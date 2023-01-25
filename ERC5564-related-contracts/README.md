# ERC5564

## 目次

### 1. [はじめに](#1-はじめに)

### 2. [ ERC5564.sol にインポートされることになるであろうファイル]()

1. 

### 3. [`ERC5564.sol`](#3-ERC5564sol)


### 4. [TIPs](#4-tips)

## 1. はじめに

ここでは，今後，標準化されるであろう `ERC5564.sol` とその中でインポートされる可能性の高い 8 つを含めた 9 つの sol ファイルについて，順番にコードベースでよみとくことによって ERC5564 を理解することを目指します．

ERC5564 はまだ EIP の段階であり，正式には ERC でないことにご留意ください．


## 2. ERC5564.sol にインポートされているファイル

以下では，`ERC5564.sol` でインポートされる可能性のあるそれぞれのファイルについて，おおまかな内容と `ERC5564.sol` 内での用途を説明していきます．
レポジトリ内の同名ファイルには，原本に適宜コメントを追加したファイルを同梱してあります．ご活用ください．


## 3. ERC5564

EIP 段階の IERC5564 をベースに，筆者が実装したものになります．

## 4. TIPs

## 5. Refference

1. [https://coinpost.jp/?p=427794](https://coinpost.jp/?p=427794)
2. [https://vitalik.eth.limo/general/2023/01/20/stealth.html](https://vitalik.eth.limo/general/2023/01/20/stealth.html)
3. [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5564.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5564.md)

## 6. 参考になるドキュメント

### 6.1 ヴィタリックのブログ(日本誤訳)

# ステルスアドレスの不完全なガイド

イーサリアムのエコシステムに残る最大の課題の1つは、プライバシーです。デフォルトでは、パブリックブロックチェーンに載るものはすべて公開されます。これは、お金や金融取引だけでなく、ENS名、POAPs、NFTs、soulboundトークンなど、ますます多くのことを意味するようになりました。実際には、イーサリアムのアプリケーション群をすべて使用することは、人生のかなりの部分を誰もが見たり分析したりできるように公開することを意味します。

この状態を改善することは重要な問題であり、このことは広く認識されています。しかし、これまでのところ、プライバシーの改善に関する議論は、主に1つの特定のユースケースに集中しています。ETHや主流のERC20トークンのプライバシー保護された転送（通常は自己転送）です。この記事では、他の多くの文脈でEthereum上のプライバシーの状態を改善することができる別のカテゴリーのツール、ステルスアドレスの仕組みと使用例について説明します。

## ステルスアドレスの仕組み

アリスがボブに資産を送ることを望んでいるとする。これはある量の暗号通貨（例えば1ETH、500RAI）かもしれませんし、NFTかもしれません。ボブは資産を受け取るとき、それを受け取ったのが自分であることを全世界に知られたくありません。特にチェーン上に1つしかないNFTの場合、転送があったことを隠すことは不可能ですが、誰が受取人であるかを隠すことはより現実的かもしれません。アリスとボブは怠け者です。彼らは支払いのワークフローが現在と全く同じであるシステムを望んでいます。ボブはアリスに（あるいはENSに登録して）誰かが彼に支払う方法をコード化したある種の「アドレス」を送り、その情報だけで、アリス（あるいは他の誰でも）は彼に資産を送るのに十分である。

これは、例えばトルネードキャッシュが提供するものとは異なる種類のプライバシーであることに注意してください。Tornado Cashは、ETHや主要なERC20のような主流の可換資産の送金を隠すことができますが（ただし、自分自身に内密に送るには最も簡単に役立ちます）、無名のERC20の送金には非常に弱く、NFT送金には全くプライバシーを加えることができません。

ステルスアドレスはそのような方式を提供する。ステルスアドレスとは、アリスとボブのどちらかが生成でき、ボブだけが制御できるアドレスのことである。ボブは消費鍵を生成して秘密にし、この鍵を用いてステルスメタアドレスを生成する。このメタアドレスをアリスに渡す（またはENSに登録する）。アリスはこのメタアドレスに対して計算を行い、ボブに属するステルスアドレスを生成することができる。そして、彼女はこのアドレスに送りたい資産を送ることができ、ボブはその資産を完全にコントロールすることができる。転送と同時に、彼女はBobがこのアドレスが自分のものであることを発見するのに役立ついくつかの特別な暗号データ（ephemeral pubkey）をチェーン上で公開する。

別の見方をすれば、ステルスアドレスは、ボブが取引のたびに新しいアドレスを生成するのと同じプライバシー特性を与えるが、ボブからのインタラクションを必要としない。

ステルスアドレス方式の完全なワークフローは、以下のように見ることができる。

1. Bobは自分のルート消費鍵(m)とステルスメタアドレス(M)を生成する。
2. ボブはENSレコードを追加して、Mをbob.ethのステルスメタアドレスとして登録する。
3. アリスはボブがbob.ethであることを知っていると仮定する。アリスはENSで自分のステルスメタアドレスMを調べる。
4. アリスは自分だけが知っていて、一度だけ使う(この特定のステルスアドレスを生成するため)エフェメラルキーを生成する。
5. アリスは自分のエフェメラルキーとボブのメタアドレスを組み合わせたアルゴリズムを使って、ステルスアドレスを生成する。彼女はこのアドレスにアセットを送ることができる。
6. アリスはまた彼女のエフェメラル公開鍵を生成し、それをエフェメラル公開鍵レジストリに公開する(これはこのステルスアドレスにアセットを送る最初のトランザクションと同じトランザクションで行うことができる)。
7. Bobが自分に属するステルスアドレスを発見するためには、Bobは、前回スキャンを行ってから、何らかの理由で誰かが公開したエフェメラル公開鍵の全リストについて、エフェメラル公開鍵レジストリをスキャンする必要がある。
8. それぞれの一時的公開鍵について、Bobはそれを自分のルート支出鍵と組み合わせてステルスアドレスを生成しようとし、そのアドレスに資産があるかどうかを確認する。もしあれば、ボブはそのアドレスの支出鍵を計算し、それを記憶しておく。

これはすべて、2つの暗号のトリックに依存している。一つはアリスの秘密鍵(ephemeral key)とボブの公開鍵(meta-address)を使うアルゴリズム、もう一つはボブの秘密鍵(root spending key)とアリスの公開鍵(ephemeral public key)を使うアルゴリズムです。これは多くの方法で可能です。ディフィー-ヘルマン鍵交換は現代の暗号の分野を確立した結果の一つで、まさにこれを実現しています。

しかし、共有秘密だけでは十分ではありません。もし共有秘密から秘密鍵を生成するだけなら、アリスとボブは両方ともこのアドレスから使うことができるのです。そのままにしておいて、ボブが新しいアドレスに資金を移動するのに任せることもできますが、これでは効率が悪く、セキュリティも不必要に低下してしまいます。そこで私たちは、鍵の目くらまし機構も追加します。 ボブが共有秘密と彼のルート支出鍵を組み合わせ、 アリスが共有秘密とボブのメタアドレスを組み合わせて、 ステルスアドレスを生成し、ボブがそのステルスアドレス用の支出鍵を生成できるような 一対のアルゴリズムを、すべてステルスアドレスとボブのメタアドレス間 (またはあるステルスアドレスと別のアドレス間) に公開リンクを作成せずに、作成できるようにします。

## 楕円曲線暗号を用いたステルスアドレス

楕円曲線暗号を用いたステルスアドレスは、もともと2014年にPeter ToddがBitcoinの文脈で紹介したものです。この手法は以下のように動作します（楕円曲線暗号の基本的な予備知識があることが前提です。いくつかのチュートリアルはこちら、こちら、こちらをご覧ください）。

ボブは鍵mを生成し、M = G * mを計算する。ここで、Gは楕円曲線の一般的に合意された生成点である。ステルスメタアドレスはMの符号化である。
アリスは、一時的な鍵rを生成し、一時的な公開鍵R = G * rを公開する。
アリスは共有秘密S = M * rを計算することができ、ボブは同じ共有秘密S = m * Rを計算することができる。
一般に、ビットコインとイーサリアム（正しく設計されたERC-4337アカウントを含む）の両方において、アドレスはそのアドレスからの取引を検証するために使用される公開鍵を含むハッシュである。つまり、公開鍵を計算すれば、アドレスを計算することができるのです。公開鍵を計算するために、アリスまたはボブはP = M + G * hash(S)を計算することができます。
そのアドレスの秘密鍵を計算するために、ボブ (とボブだけ) は p = m + hash(S) を計算することができます。
これは上記の要件をすべて満たしており、驚くほど簡単です!

現在、イーサリアムのステルスアドレス標準を定義しようとしているEIPもあります。それは、このアプローチをサポートし、ユーザーが他のアプローチ（例えば、ボブが個別の支出キーと閲覧キーを持つことをサポートしたり、量子抵抗性のセキュリティのために別の暗号を使用したり）を開発するためのスペースを提供するものです。ステルスアドレスはそれほど難しくないし、理論もすでにしっかりしているので、それを採用するのは実装の詳細だけでいい、と思われるかもしれません。しかし、問題は、本当に効果的な実装を行うには、かなり大きな実装の詳細が必要であるということです。

## ステルスアドレスと取引手数料の支払い

誰かがあなたにNFTを送ったとします。プライバシーに配慮して、その人はあなたが管理しているステルスアドレスに送ります。チェーン上のephem pubkeyをスキャンすると、ウォレットは自動的にこのアドレスを検出します。これで、NFTの所有権を自由に証明したり、他の人に譲渡したりすることができます。しかし、問題があります! そのアカウントには0ETHがあるので、取引手数料を支払う方法がないのです。ERC-4337トークンのペイマスターも機能しません。なぜなら、これらはカビの生えないERC20トークンに対してのみ機能するからです。また、メインのウォレットからそのアカウントにETHを送ることはできません。

この問題を解決する「簡単な」方法は一つ、ZK-SNARKsを使って手数料を支払うために資金を移動させればいいのだ！しかし、これにはガソリン代がかかる。一回の送金で数十万円のガソリン代が余分にかかる。

もうひとつの巧妙な方法は、専門の取引アグリゲーター（MEV用語で「サーチャー」）を信頼することだ。これらのアグリゲーターは、ユーザーが一度支払うと、オンチェーンでの取引の支払いに使用できる一連の「チケット」を購入することができるようになる。ユーザーはNFTを何も含まないステルスアドレスで使う必要があるとき、Chaumian Blindingスキームを使用してエンコードされたチケットの1つをアグリゲーターに提供する。これは、1980年代から1990年代にかけて提案された集中型プライバシー保護電子マネー方式で使用されたオリジナルのプロトコルである。探索者はチケットを受け取り、ブロック内で取引の受理が成功するまで、その取引を無料で繰り返し自分のバンドルに含める。関与する資金の量は少なく、取引手数料の支払いにしか使用できないため、この種の中央集権的なプライバシー保護e-cashの「完全な」実装に比べて、信頼と規制の問題はずっと低くなります。

## ステルスアドレスと支出キーと閲覧キーの分離

Bobが、すべてを行える単一のマスター「root spending key」ではなく、 root spending keyとviewing keyを別々に持ちたいと考えたとする。閲覧鍵はBobの全てのステルスアドレスを見ることができるが、そこから支出することはできない。

楕円曲線の世界では、これは非常に簡単な暗号のトリックで解決できる。

BobのメタアドレスMは、G * kとG * vを符号化した(K, V)形式となり、ここでkは支出鍵、vは閲覧鍵である。
共有秘密は、S = V * r = v * Rとなり、rは依然としてアリスの一時的な鍵、Rは依然としてアリスが公開する一時的な公開鍵である。
ステルスアドレスの公開鍵はP = K + G * hash(S)で、秘密鍵はp = k + hash(S)である。
最初の巧妙な暗号化ステップ(共有秘密の生成)は閲覧キーを使い、 2番目の巧妙な暗号化ステップ(ステルスアドレスとその秘密鍵を生成する アリスとボブの並列アルゴリズム)はルート支出キーを使っていることに 注意してください。

これには多くのユースケースがある。例えば、ボブがPOAPを受け取りたい場合、ボブは自分のPOAPウォレット（またはあまり安全でないウェブインターフェース）に、チェーンをスキャンして自分のPOAPをすべて見るための閲覧キーを与えることができますが、このインターフェースにこれらのPOAPを使う力を与えることはできません。

## ステルスアドレスと簡単なスキャン

一時的な公開鍵の総セットのスキャンを容易にするために、1つの手法として、 各一般的な公開鍵にビュータグを追加することがある。上記の仕組みでこれを行う方法の1つは、ビュータグを共有秘密の1バイトにすることである(例えば、Sの256モジュロのx座標、またはhash(S)の最初のバイト)。

この方法では、Bobは共有秘密を計算するために、各エフェメラル公開鍵に対して楕円曲線乗算を1回行うだけでよく、完全なアドレスを生成して確認するために、より複雑な計算を行う必要があるのは1/256回だけである。

## ステルスアドレスと耐量子セキュリティ

上記の方式は楕円曲線に依存しており、これは素晴らしいものですが、残念ながら量子コンピュータに弱いという欠点があります。もし、量子コンピュータが問題になれば、量子に強いアルゴリズムに切り替える必要があります。その候補として、楕円曲線異性体と格子の2つが自然な形で存在する。

楕円曲線等値性は、楕円曲線に基づく数学的構成で、線形性を持っているため、上記と同様の暗号トリックを行うことができるが、量子コンピュータによる離散対数攻撃に弱い環状群を構成しないように巧妙に工夫されている。

等質性暗号の最大の弱点は、その数学が非常に複雑であること、そしてその複雑さの下に可能な攻撃が隠されている危険性があることです。昨年、いくつかのアイソジェニー・ベースのプロトコルが破られたが、他のプロトコルは依然として安全である。等質性の主な強みは、鍵のサイズが比較的小さく、多くの種類の楕円曲線ベースのアプローチを直接移植することができることです。

ラティスは楕円曲線異性体よりもはるかに単純な数学に依存する、非常に異なる暗号構造であり、いくつかの非常に強力なもの（例えば、完全同型暗号化）を可能にするものである。ステルスアドレス方式は格子の上に構築することができますが、最適なものを設計することは未解決の問題です。しかし、格子に基づく構成は鍵のサイズが大きくなる傾向があります。

第三のアプローチは、一般的なブラックボックスプリミティブからステルスアドレススキームを構築することである。このスキームの共有秘密生成部分は、公開鍵暗号化システムにおいて重要な要素である鍵交換に直接マッピングされます。より難しいのは、アリスにステルスアドレスだけを生成させ（支出鍵は生成させない）、ボブには支出鍵を生成させるという並列アルゴリズムです。

残念ながら、公開鍵暗号化システムを構築するのに必要なものよりも単純な材料から、ステルスアドレスを構築することはできないのです。これには簡単な証明があります。ステルスアドレス方式から公開鍵暗号化システムを構築することができるのです。もしアリスがボブへのメッセージを暗号化したいならば、彼女はN個のトランザクションを送ることができる。それぞれのトランザクションはボブに属するステルスアドレスか彼女に属するステルスアドレスに行き、ボブはメッセージを読むために彼がどのトランザクションを受け取ったかを見ることができる。これは重要なことで、ハッシュだけでは公開鍵暗号化はできないが、ハッシュだけならゼロ知識証明ができるという数学的証明があるため、ハッシュだけではステルスアドレスはできない。

ここでは、ハッシュから作れるゼロ知識証明と、（鍵を隠蔽する）公開鍵暗号という、比較的単純な材料を使ったアプローチを紹介します。ボブのメタアドレスは公開暗号鍵とハッシュh = hash(x)であり、彼の消費鍵は対応する復号鍵とxです。ステルスアドレスを作るために、アリスは値cを生成し、ボブが読めるcの暗号化を彼女のエフェメラル公開鍵として公開します。アドレス自体はERC-4337のアカウントで、そのコードは、k = hash(hash(x), c)(ここでkはアカウントのコードの一部)となる値xとcの所有を証明するゼロ知識証明を伴うことを要求することによって取引を検証している。xとcを知ることで、ボブは自分自身でアドレスとそのコードを再構築することができる。

ウォレットコード自体にはkが含まれているだけであり、cがプライベートであるということは、kからhに辿り着くことはできないということである。

しかし、これにはSTARKが必要で、STARKは大きいです。最終的には、ポスト量子イーサリアムの世界では、多くのアプリケーションが多くのstarkを使用する可能性が高いと思いますので、ここで説明したような集約プロトコルを提唱して、これらのstarkをすべて単一の再帰的starkにまとめ、スペースを節約することを目指したいと思います。

## ステルスアドレスとソーシャルリカバリー、マルチL2ウォレット


私は長い間、ソーシャルリカバリーウォレットのファンでした。ウォレットは、機関、他のデバイス、友人の組み合わせで共有される鍵によるマルチシグ機構を備えており、主鍵を失った場合、それらの鍵の超多数がアカウントへのアクセスを回復することができるものです。

しかし、ソーシャルリカバリーウォレットはステルスアドレスとうまく混ざり合いません。もしあなたが自分のアカウントを回復しなければならない（つまり、どの秘密鍵がそれをコントロールするかを変える）場合、N個のステルスウォレットのアカウント検証ロジックを変更するステップも実行しなければならず、これにはN個の取引が必要で、手数料、便利さ、プライバシーに高いコストがかかることになります。

Optimism、Arbitrum、Starknet、Scroll、Polygonにアカウントを持っていて、スケーリング上の理由でこれらのロールアップが何十もの並列インスタンスを持ち、それぞれにアカウントを持っているとしたら、鍵を変えるのは本当に複雑な操作になるかもしれないのです。

一つの方法は、復旧はまれであり、コストと痛みを伴うことを受け入れることである。おそらく、自動化されたソフトウェアが、2週間という時間軸でランダムに新しいステルスアドレスに資産を転送し、時間ベースのリンクの効果を低減させるかもしれない。しかし、これは完璧にはほど遠い。もう一つのアプローチは、スマートコントラクトリカバリーを使用する代わりに、保護者間でルートキーを秘密裏に共有することです。しかし、これでは、自分のアカウントの回復を助けるための保護者の力を停止させることができないため、長期的なリスクがある。

より洗練されたアプローチとして、ゼロ知識証明というものがあります。上記のZKPベースのスキームを考えるが、ロジックを以下のように変更する。アカウントはk = hash(hash(x), c)を直接保持する代わりに、チェーン上のkの位置に対する（隠蔽）コミットメントを保持することになる。そのアカウントから支出するには、(i)そのコミットメントに一致するチェーン上の場所を知っていて、(ii)その場所にあるオブジェクトに何らかの値k（これは明らかにしない）が含まれており、k = hash(x), cを満たすいくつかの値xとcを持っていることをゼロ知識で証明することが必要である。

これにより、多くのアカウントは、多くのレイヤー2プロトコルにまたがっても、どこか（ベースチェーン上またはいくつかのレイヤー2上の）単一のk値によって制御され、その一つの値を変更するだけで、すべてのアカウントの所有権を変更することができます。

## 結論

基本的なステルスアドレスは今日かなり迅速に実装することができ、イーサリアムの実用的なユーザープライバシーを大幅に向上させることができる。しかし、それをサポートするためにウォレット側でいくつかの作業が必要です。とはいえ、他のプライバシー関連の理由からも、ウォレットはよりネイティブなマルチアドレスモデル（例えば、やり取りするアプリケーションごとに新しいアドレスを作成するのも一つの選択肢かもしれません）に向けて動き始めるべきだというのが私の考えです。

しかし、ステルスアドレスは、ソーシャルリカバリーの難しさなど、長期的なユーザビリティの懸念をもたらす。例えば、ソーシャルリカバリーは、プライバシーの損失、または様々な資産にリカバリートランザクションをゆっくりと解放するための2週間の遅延を伴うことを受け入れることによって、今のところこれらの懸念を単に受け入れることはおそらく大丈夫です（これはサードパーティサービスによって処理される可能性があります）。長期的には、これらの問題を解決することができますが、長期的なステルスアドレスのエコシステムは、ゼロ知識証明に大きく依存することになりそうです。

### 6.2 EIP-5564の規格書の日本語訳

## 概要

本仕様は、ステルスアドレスを作成するための標準的な方法を定義する。このEIPは，取引／転送の送信者が，受信者のために，受信者だけが解除できるプライベートステルスアドレスを非介入で生成することを可能にする。

## 動機(モチベーション)

非インタラクティブなステルスアドレス生成の標準化は、資産を受け取る際に送金の受取人が匿名性を保てるようにすることで、イーサリアムのプライバシー機能を大幅に強化する可能性を持っています。これは、送信者と受信者の間で共有された秘密を使用して、送信者がステルスアドレスを生成することによって達成されます。ステルスアドレスにある資金のロックを解除できるのは受取人のみで、この目的のために必要な秘密鍵にアクセスできるのは彼らだけだからです。その結果、監視者は受取人のステルスアドレスと自分の身元を関連付けることができず、受取人のプライバシーが守られ、この情報は送信者のみに残されます。

## 特徴

本文書におけるキーワード「MUST」「MUST NOT」「REQUIRED」「SHALL」「SHALL NOT」「SHOULD」「SHOULD NOT」「RECOMMENDED」「MAY」「OPTIONAL」はRFC2119に記載されている通りに解釈されます。  

以下の契約は、この仕様の一部である。  

`IERC5564Registry `は、ユーザーのためのステルス公開鍵を格納する。これは、チェーンごとに1つのインスタンスを持つ、シングルトン契約でなければならない(MUST)。  

`IERC5565Generator` コントラクトは、与えられた曲線に基づいて、ユーザーのステルスアドレスを計算するために使用される。チェーンごとにこれらの多くが存在することができ、与えられたカーブに対してチェーンごとに1つの実装があるべきである(SHOULD)。ステルスアドレスを生成するために HTTPS 経由でメソッドを呼び出すと、ノードの実行者によってはユーザーのプライバシーを侵害する可能性があるため、ジェネレータコントラクトは主にオフチェーンライブラリの参照実装として機能するよう意図されています。  

`IERC5564Messenger` は、ステルスアドレスに何かが送信されると、それを知らせるためにイベントを発行します。これは、チェーンごとに1つのインスタンスを持つ、シングルトンコントラクトでなければなりません(MUST)。

それぞれのインターフェイスは以下のように規定されています。

- `IERC5564Registry`

```solidity
/// @notice Registry to map an address to its stealth key information.
interface IERC5564Registry {
  /// @notice Returns the stealth public keys for the given `registrant` to compute a stealth
  /// address accessible only to that `registrant` using the provided `generator` contract.
  /// @dev MUST return zero if a registrant has not registered keys for the given generator.
  function stealthKeys(address registrant, address generator)
    external
    view
    returns (bytes memory spendingPubKey, bytes memory viewingPubKey);

  /// @notice Sets the caller's stealth public keys for the `generator` contract.
  function registerKeys(address generator, bytes memory spendingPubKey, bytes memory viewingPubKey)
    external;

  /// @notice Sets the `registrant`s stealth public keys for the `generator` contract using their
  /// `signature`.
  /// @dev MUST support both EOA signatures and EIP-1271 signatures.
  function registerKeysOnBehalf(
    address registrant,
    address generator,
    bytes memory signature,
    bytes memory spendingPubKey,
    bytes memory viewingPubKey
  ) external;

  /// @dev Emitted when a registrant updates their registered stealth keys.
  event StealthKeyChanged(
    address indexed registrant, address indexed generator, bytes spendingPubKey, bytes viewingPubKey
  );
}
```

- `IERC5564Generator`

```solidity
/// @notice Interface for generating stealth addresses for keys from a given stealth address scheme.
/// @dev The Generator contract MUST have a method called `stealthKeys` that returns the recipient's
/// public keys as the correct types. The return types will vary for each generator, so a sample
/// is shown below.
interface IERC5564Generator {
  /// @notice Given a `registrant`, returns all relevant data to compute a stealth address.
  /// @dev MUST return all zeroes if the registrant has not registered keys for this generator.
  /// @dev The returned `viewTag` MUST be the hash of the `sharedSecret`. THe hashing function used
  /// is specified by the generator.
  /// @dev `ephemeralPubKey` represents the ephemeral public key used by the sender.
  /// @dev Intended to be used off-chain only to prevent exposing secrets on-chain.
  /// @dev Consider running this against a local node, or using an off-chain library with the same
  /// logic, instead of via an `eth_call` to a public RPC provider to avoid leaking secrets.
  function generateStealthAddress(address registrant)
    external
    view
    returns (
      address stealthAddress,
      bytes memory ephemeralPubKey,
      bytes memory sharedSecret,
      bytes32 viewTag
    );

  /// @notice Returns the stealth public keys for the given `registrant`, in the types that best
  /// represent the curve.
  /// @dev The below is an example for the secp256k1 curve.
  function stealthKeys(address registrant)
    external
    view
    returns (
      uint256 spendingPubKeyX,
      uint256 spendingPubKeyY,
      uint256 viewingPubKeyX,
      uint256 viewingPubKeyY
    );
}
```

- `IERC5564Messenger`

```solidity
/// @notice Interface for announcing that something was sent to a stealth address.
interface IERC5564Messenger {
  /// @dev Emitted when sending something to a stealth address.
  /// @dev See `announce` for documentation on the parameters.
  event Announcement(
    bytes ephemeralPubKey, bytes32 indexed stealthRecipientAndViewTag, bytes32 metadata
  );

  /// @dev Called by integrators to emit an `Announcement` event.
  /// @dev `ephemeralPubKey` represents the ephemeral public key used by the sender.
  /// @dev `stealthRecipientAndViewTag` contains the stealth address (20 bytes) and the view tag (12
  /// bytes).
  /// @dev `metadata` is an arbitrary field that the sender can use however they like, but the below
  /// guidelines are recommended:
  ///   - When sending ERC-20 tokens, the metadata SHOULD include the token address as the first 20
  ///     bytes, and the amount being sent as the following 32 bytes.
  ///   - When sending ERC-721 tokens, the metadata SHOULD include the token address as the first 20
  ///     bytes, and the token ID being sent as the following 32 bytes.
  function announce(
    bytes memory ephemeralPubKey,
    bytes32 stealthRecipientAndViewTag,
    bytes32 metadata
  ) external;
}
```

#### サンプルジェネレーターコントラクトの実装例

```solidity
/// @notice Sample IERC5564Generator implementation for the secp256k1 curve.
contract Secp256k1Generator is IERC5564Generator {
  /// @notice Address of this chain's registry contract.
  IERC5564Registry public constant REGISTRY = IERC5564Registry(address(0));

  /// @notice Sample implementation for parsing stealth keys on the secp256k1 curve.
  function stealthKeys(address registrant)
    external
    view
    returns (
      uint256 spendingPubKeyX,
      uint256 spendingPubKeyY,
      uint256 viewingPubKeyX,
      uint256 viewingPubKeyY
    )
  {
    // Fetch the raw spending and viewing keys from the registry.
    (bytes memory spendingPubKey, bytes memory viewingPubKey) =
      REGISTRY.stealthKeys(registrant, address(this));

    // Parse the keys.
    assembly {
      spendingPubKeyX := mload(add(spendingPubKey, 0x20))
      spendingPubKeyY := mload(add(spendingPubKey, 0x40))
      viewingPubKeyX := mload(add(viewingPubKey, 0x20))
      viewingPubKeyY := mload(add(viewingPubKey, 0x40))
    }
  }

  /// @notice Sample implementation for generating stealth addresses for the secp256k1 curve.
  function generateStealthAddress(address registrant, bytes memory ephemeralPrivKey)
    external
    view
    returns (
      address stealthAddress,
      bytes memory ephemeralPubKey,
      bytes memory sharedSecret,
      bytes32 viewTag
    )
  {
    // Get the ephemeral public key from the private key.
    ephemeralPubKey = ecMul(ephemeralPrivKey, G);

    // Get user's parsed public keys.
    (
      uint256 spendingPubKeyX,
      uint256 spendingPubKeyY,
      uint256 viewingPubKeyX,
      uint256 viewingPubKeyY
    ) = stealthKeys(registrant, address(this));

    // Generate shared secret from sender's private key and recipient's viewing key.
    sharedSecret = ecMul(ephemeralPrivKey, viewingPubKeyX, viewingPubKeyY);
    bytes32 sharedSecretHash = keccak256(sharedSecret);

    // Generate view tag for enabling faster parsing for the recipient
    viewTag = sharedSecretHash[0:12];

    // Generate a point from the hash of the shared secret
    bytes memory sharedSecretPoint = ecMul(sharedSecret, G);

    // Generate sender's public key from their ephemeral private key.
    bytes memory stealthPubKey = ecAdd(spendingPubKeyX, spendingPubKeyY, sharedSecretPoint);

    // Compute stealth address from the stealth public key.
    stealthAddress = pubkeyToAddress(stealthPubKey);
}
```

ステルスアドレスは、楕円曲線を想定した以下のアルゴリズムで計算されます。Kyberによるポスト量子暗号化など、他の暗号化方式ではこの方法を修正する必要があるかもしれません。

- Gは曲線の生成点である。

- 受信者は秘密鍵と公開鍵を生成する。
- 受信者は対応する公開鍵をIERC5564Registry で公開する。
- 送信者は、ランダムな32バイトのエントロピーを持つエフェメラルな(一時的な)秘密鍵を生成する。
- 送信者は、受信者のアドレスとPパーソナルをIERC5564GeneratorコントラクトのgenerateStealthAddress関数に渡す。

- この関数は、以下の計算を行う。

- 共有秘密鍵 は次のように計算される。

- 秘密はハッシュ化される。

- ビュータグ は，最上位の 12 バイトを取り出すことで，抽出される．

- 共有された秘密にジェネレータポイントを乗算する。

- 受信者のステルス公開鍵は、次のように計算されます。

- 受信者のステルスアドレスは次のように計算される。

- 資金を送るには、次のようにします。

- 送信者は、自分の選択したコントラクトを使って、何かを送るために、自分の選んだコントラクトを使い、そしてその他のメタデータを send メソッドに提供します。

- コントラクトは、IERC5564Messenger.announceを呼び出します。

- 資金をスキャンするために、受信者はIERC5564Messengerコントラクトからすべてのログを取得する必要があります。次に、彼らは、ステルスアドレスとして発せられたステルスアドレスを計算できるかどうかをチェックする。

- ステルスアドレスとして発信された を計算できるかどうかを確認する。成功すれば、受信者は資産にアクセスできる秘密鍵を取得できる。

## パースに関する考慮点

通常、ステルスアドレス取引の受信者は、ある取引の受信者であったかどうかを確認するために、以下の操作を行う必要がある。

- 2x ecMUL
- 2x HASH
- 1x ecADD

ビュータグ方式を導入することで、解析時間を約6分の1に短縮することができます。ユーザーは解析されたアナウンスメントごとに1x ecMULと1x HASHを実行するだけです（1x ecMUL、1x ecADD、1x HASHはスキップされます）。12バイトの長さは、アナウンスメントイベントの最初のログで自由に利用できるスペースに基づいています。12バイトをviewTagとして使用すると、ユーザが共有秘密のハッシュ化後に残りの計算をスキップする確率は以下のように決定されます。  
 
つまり、ユーザは、自分に関係ないアナウンスメントについては、上記の3つの処理をほぼ確実にスキップすることができる。

## この規格が生まれた理由

このEIPは、受取人の身元を明らかにすることなく所有権を移転する、プライバシーを保護する方法を持つ必要性から生まれたものです。トークンは、所有者の個人的な機密情報を明らかにすることができます。ユーザーは特定の組織や国にお金を寄付したいかもしれませんが、同時に個人的なアカウント関連情報を明らかにしたくないかもしれません。プライバシーを保護するソリューションは、採用されるために標準化を必要とし、したがって、関連するソリューションを実装するための一般化可能な方法に焦点を当てることが重要である。  

ステルスアドレス拡張は、ステルスアドレスの生成と位置決定のためのプロトコルを標準化し、受取人との事前の相互作用を必要としない資産の転送を可能にし、受取人がブロックチェーンと相互作用せずに転送の受領を確認することを可能にするものである。重要なのは、ステルスアドレスによって、トークン送金の受取人は、自分が送金の受取人であることを受取人だけが確認できるため、プライバシーを維持しながら受取を確認することができるという点です。  

著者らは、オンチェーンとオフチェーンの効率性の間のトレードオフを明らかにしています。Moneroのようなビュータグメカニズムを含むことは、受信者がより迅速にアナウンスを解析するのに役立ちますが、アナウンスイベントに複雑さが加わります。  

受信者のアドレスとビュータグはアナウンスメントイベントに含まれなければならず、これによりユーザは正のアカウント残高をチェーンに問い合わせることなく所有権を迅速に確認することができます。

## 下位互換性

このEIPは完全な後方互換性を持っています。

## 参考実装

この規格の実装はTBDで見ることができます。

## セキュリティへの配慮

ステルスアドレスウォレットへの資金提供は、プライバシーを侵害する可能性のある既知の問題を表しています。ステルスアドレスに資金を供給するウォレットは、プライバシーの改善を完全に活用するために、ステルスアドレスの所有者といかなる物理的な接続も持ってはいけません(MUST NOT)。

### 寄稿をお待ちしております！！

ご覧いただいてきたように， EIP の段階の IERC5564 をもとに，筆者が可能な限り実装してみたものになります．
もし間違いに気が付いた場合には，イシューやプルリクエストにて，お知らせいただけたら幸いです．
