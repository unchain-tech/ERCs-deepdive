// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC5192} from "./IERC5192.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// ERC5192はEIPの段階であることにご留意ください．

contract ERC5192 is Context, ERC165, IERC721, IERC721Metadata, IERC5192 {
    // ライブラリの使用を宣言
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // トークンID→所有者アドレス のマッピング
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // 所有者アドレス→保有枚数 のマッピング
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // トークンID→移転許可所有アドレス のマッピング
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // 所有者アドレスから移転許可所有アドレス，そして許可の有無へのダブルマッピング
    // 移転許可所有アドレスを登録する時にマッピングしておいて，
    // 許可移転する時に許可の有無を確認する時に使う
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // EIP5192をもとに独自に実装しました．
    // 指定されたtokenIDのtransferのロックをフラグとして制御します．
    // Mapping from tokenID to acount lock;
    mapping(uint256 => bool) private _accountLock;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        // トークン名，トークンシンボルを初期化
        _name = name_;
        _symbol = symbol_;
    }

    // ERC165の本体．
    // 引数に取ったinterfaceId(interface の識別子)が，ERC165が実装されたコントラクトまたは
    // 実装したコントラクトに継承したコントラクト内に実装されているか調べることができる．
    // 具体的には，まず，ERC165を実装したコントラクト内でERC165内で定義されたsupportsInterface(bytes4 interfaceId)関数をオーバーライドして，
    // 実装したコントラクトに継承するインターフェイスのIDと引数との等価演算全種を行い，
    // 継承されているコントラクトの中にERC165が実装されていた場合，そのコントラクトでも同様な等価演算全種を行う．
    // 最後に行われた全ての等価演算の結果の論理和をとって，返り値として返している．
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            // EIP5192で指定されたinterfaceId
            interfaceId == 0xb45a3c0e ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // EIP5192をもとに独自に実装しました．
    // 上で定義した_accountLockマッピングのbool値を参照する関数．
    // 指定されたtokenIDのtransferがロックされているか否かを返す．
    function locked(uint256 tokenId) external view override returns (bool) {
        require(_exists(tokenId), "invalid token ID");
        return _accountLock[tokenId];
    }

    // 上で定義した_balancesマッピングの中身を参照する関数．
    // アドレスがもつ(このコントラクトで規定された)SBTの総数を返す．
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC5192: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    // 上で定義した_ownersマッピングの中身を参照する関数．
    // 引数にとったトークンIDのSBT(もちろんこれもこのコントラクトで規定されたもののIdのこと)の所有者となっているアドレスを返す．
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC5192: invalid token ID");
        return owner;
    }

    // 上で定義したトークン名を参照する関数．
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // 同じくうえで定義したトークンシンボルを参照する関数
    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // 下で定義する_baseURI()関数の返り値を参照する関数．
    // この返り値，すなはち_baseURI()関数の中身が俗にいうメタデータである．
    // 実際にはそれだけではなく，_requireMinted関数でミントされているか確認されたり，
    // return時にメタデータが空でないか確認されたりしている．
    // それを満たさなかった場合，revertされることになる．
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    // 上で言及したメタデータの中身．
    // 初期値では空になっている(空stringを返す)．
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    // EIP5192をもとに独自に変更しました．
    // _accountLockがfalseでtransferが可能な場合，tokenの現ownerがtoアドレスに対してtokenの移送許可を与える関数
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // tokenIdのownerをマッピングから参照
        address owner = ERC5192.ownerOf(tokenId);
        // toアドレスがownerアドレスと同一でないか確認．
        // 同一ならrevert．
        require(to != owner, "ERC5192: approval to current owner");

        // トランザクション送信者が当該tokenのownerまたは移送許可を受けた者であるか確認
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC5192: approve caller is not token owner or approved for all"
        );

        // 移送許可情報が記録されているマッピングを更新
        _approve(to, tokenId);
    }

    // EIP5192をもとに独自に変更しました．
    // _accountLockがfalseでtransferが可能な場合，token移送許可情報を参照する関数．
    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    // token移送許可を与える関数．
    // approveより上位の許可として定義されている模様
    // デフォルトでは使い道がないが，追加実装で活きてくる可能性がある．
    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        // 挙動を司る子関数を呼び出している
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // operatorとして渡されたアドレスが上位許可``_operatorApprovals`` を有しているか確認する関数．
    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // 移送許可情報が記録されているマッピングを参照
        return _operatorApprovals[owner][operator];
    }

    // EIP5192をもとに独自に変更しました．
    // _accountLockがfalseでtransferが可能な場合，移送許可に準じたtoken移送を行う関数
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // 移送許可があるかどうかを確認
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC5192: caller is not token owner or approved"
        );

        // 挙動を司る子関数を呼び出している
        _transfer(from, to, tokenId);
    }

    // EIP5192をもとに独自に変更しました．
    // transferFrom関数にERC721Receiverを適用した関数．
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // 直下の関数を呼び出している
        safeTransferFrom(from, to, tokenId, "");
    }

    // EIP5192をもとに独自に変更しました．
    // caldataを引数として渡すために直上のsafeTransferFromが分割されたもの．
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // 移送許可があるかどうかを確認
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC5192: caller is not token owner or approved"
        );
        // 挙動を司る関数を呼び出している
        _safeTransfer(from, to, tokenId, data);
    }

    // EIP5192をもとに独自に変更しました．
    // transfer関数にERC721Rceiverを適用した関数．
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC5192 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // 挙動を司る子関数を呼び出している
        _transfer(from, to, tokenId);
        // 送信先がコントラクトでかつERC721Receiverを採用していない場合revertする
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC5192: transfer to non ERC721Receiver implementer"
        );
    }

    // _requireMinted()関数の子関数．
    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        // tokenIdのownerが存在するか確認している
        // Solidityでは大抵のパラメータの初期値は0になっているため，
        // 0アドレスと該当Idで参照した_owners[]マッピングの返り値(_owners[tokenId])を照合する
        return _owners[tokenId] != address(0);
    }

    // EIP5192をもとに独自に変更しました．
    // _accountLockがfalseでtransferが可能な場合，文字通り，引数アドレスが引数Idのトークンのオーナーもしくは移送許可保持者であればtrueを返す関数．
    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // マッピングを用いてIdからオーナーアドレスを参照しローカル変数に定義
        address owner = ERC5192.ownerOf(tokenId);
        // 引数のアドレスとオーナー，上位移送許可の有無，そして通常移送許可の有無についての真偽演算を論理和にかける
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    // _mint関数にERC721Rceiverを適用した関数．
    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bool lock // transferをlockするかどうか
    ) internal virtual {
        // 直下の子関数を呼び出している
        _safeMint(to, tokenId, lock, "");
    }

    // 直上から呼び出される子関数．
    // ERC721Rceiverを適用している．
    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bool lock, // transferをlockするかどうか
        bytes memory data
    ) internal virtual {
        // 挙動を司る子関数を呼び出している
        _mint(to, tokenId, lock);
        // ERC721Receiverのメソッドを呼び出している
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC5192: transfer to non ERC721Receiver implementer"
        );
    }

    // トークンミントを行う時に実行されるメソッド．
    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 tokenId,
        bool lock // transferをlockするかどうか
    ) internal virtual {
        // ミント先が0アドレスでないことを確認
        require(to != address(0), "ERC5192: mint to the zero address");
        // 既にミントされていないか確認する子関数を呼び出している
        require(!_exists(tokenId), "ERC5192: token already minted");

        // トークンの移動前に実行されるメソッドを呼び出す
        _beforeTokenTransfer(address(0), to, tokenId);

        // 関係するマッピングの値を適切に変更している
        _balances[to] += 1;
        _owners[tokenId] = to;
        _accountLock[tokenId] = lock;

        // フロントエンド等に向けたeventをemitしている
        emit Transfer(address(0), to, tokenId);

        // フロントエンド等に向けたeventをemitしている
        if (lock) {
            // lockされている場合にLockedイベントをemit
            emit Locked(tokenId);
        } else {
            // lockされていない場合にUnlockedイベントをemit
            emit Unlocked(tokenId);
        }

        // トークンの移動後に実行されるメソッドを呼び出す
        _afterTokenTransfer(address(0), to, tokenId);
    }

    // トークンをburnする関数
    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        // 引数をローカル変数に格納
        address owner = ERC5192.ownerOf(tokenId);

        // トークンの移動前に実行されるメソッドを呼び出す
        _beforeTokenTransfer(owner, address(0), tokenId);

        // 移送許可のマッピングの中身を削除(値を初期値の0に)している
        // Clear approvals
        delete _tokenApprovals[tokenId];

        // 関係するマッピングを適切に変更している
        _balances[owner] -= 1;
        delete _owners[tokenId];

        // フロントエンド等に向けたeventをemitしている
        emit Transfer(owner, address(0), tokenId);

        // トークンの移動後に実行されるメソッドを呼び出す
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    // EIP5192をもとに独自に変更しました．
    // トークン移送の挙動を司る関数
    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // 引数tokenIdのトークンownerが引数のfromと一致しているか確認する
        require(
            ERC5192.ownerOf(tokenId) == from,
            "ERC5192: transfer from incorrect owner"
        );
        // 移送先が0アドレスでないことを確認
        require(to != address(0), "ERC5192: transfer to the zero address");

        // トークンの移動前に実行されるメソッドを呼び出す
        _beforeTokenTransfer(from, to, tokenId);

        // 移送許可のマッピングの中身を削除(値を初期値の0に)している
        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        // 関係するマッピングを適切に変更している
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // フロントエンド等に向けたeventをemitしている
        emit Transfer(from, to, tokenId);

        // トークンの移動後に実行されるメソッドを呼び出す
        _afterTokenTransfer(from, to, tokenId);
    }

    // EIP5192をもとに独自に変更しました．
    // トークン移送許可付与の挙動を司る関数．
    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        // 指定されたtokenIDがtransfer可能かを確認．
        // transfer不可ならrevert．
        require(!_accountLock[tokenId], "SBT transfers are locked.");
        // 関係するマッピングを適切に変更している
        _tokenApprovals[tokenId] = to;
        // フロントエンド等に向けたeventをemitしている
        emit Approval(ERC5192.ownerOf(tokenId), to, tokenId);
    }

    // 上位のトークン移送許可の付与の挙動を司る関数．
    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        // 移送許可の付与先がトークン保有者出ないことを確認
        require(owner != operator, "ERC5192: approve to caller");
        // 関係するマッピングを適切に変更している
        _operatorApprovals[owner][operator] = approved;
        // フロントエンド等に向けたeventをemitしている
        emit ApprovalForAll(owner, operator, approved);
    }

    // 引数のtokenIdを持つトークンがミントされているかどうかを確認する関数
    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        // 挙動を司る子関数を呼び出している
        require(_exists(tokenId), "ERC5192: invalid token ID");
    }

    // ERC721Rceiverが適用された関数上で適切な操作を施すための関数
    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        // if文の条件節でAddressライブラリから引用した関数の真偽演算を行い，
        // 引数のtoアドレスがコントラクトかどうか確認
        // コントラクトでないならelse文でtrueを返す
        if (to.isContract()) {
            // 当該コントラクトERC721Rceiverを実装しているか確かめる
            // 実装されていれば関数のセレクター(関数識別子)が返ってくるので，真偽演算で判定する
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                // onERC721Receiverの正しい関数識別子を呼び出し，to上での当該関数識別子呼び出しと比較
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                // reasonのlengthプロパティを参照
                // 空ならばカスタムエラーは存在しない
                if (reason.length == 0) {
                    revert(
                        "ERC5192: transfer to non ERC721Receiver implementer"
                    );
                    // 空でない場合，カスタムエラーが存在するので，
                    // エラー内容をアセンブリrevertでキャッチする
                    // https://ethereum.stackexchange.com/questions/133748/trying-to-understand-solidity-assemblys-revert-function
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // トークンの移動前に実行されるメソッドを呼び出す．
    // デフォルトでは空．
    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    // トークンの移動後に実行されるメソッドを呼び出す．
    // デフォルトでは空．
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
