# dropnico

ニコニコ動画、 Youtube から動画をダウンロードして、あなたの Dropbox アカウントに転送します。

**使用は自己責任で行ってください。このアプリケーションの利用の結果生じた損害・問題について、作成者は一切責任を負いません。**

# 使用手順

## 1. bundle install

    $ bundle install

## 2. Dropbox App を作成する

適当な名前で dropbox アプリケーションを作成してください。ダウンロードしたファイルは /Apps/アプリケーション名 に置かれます。
このとき consumer key と consumer secret が割り当てられます。

## 3. 作成した Dropbox App が自分の Dropbox にアクセスできるようにする

    $ bundle exec rake dropbox:authorize

を実行し、先程の consumer key, secret を入力します。ブラウザで OAuth 承認画面に飛ぶので、自分が作成したアプリによるアクセスを許可してください。

この後、 terminal にもどって Enter を押すと自分の client token, secret が取得されます。

## 4. 環境変数を設定する

次のようなかんじで、このサービスが利用する環境変数を設定してください。

    export NICO_MAIL=your_mail
    export NICO_PASS=your_niconico_login_pass
    export DROPBOX_APP_KEY=consumer_key(#2)
    export DROPBOX_APP_SECRET=consumer_secret(#2)
    export DROPBOX_CLIENT_TOKEN=client_token(#3)
    export DROPBOX_CLIENT_SECRET=client_secret(#3)

## 5. 起動

    $ bundle exec rackup

で起動します。

## 6. アクセス & ダウンロード

http://localhost:9292 にアクセスし、フォームがいくつか表示されることを確認します。

現状、次の項目に対応しています。

- niconico の video id (sm... で始まるやつ)
- niconico の mylist id (数字)
- youtube の video id (10文字前後のランダム)
- youtube の埋め込みビデオを含んだページの URL (ブログなど、http で始まる URL)

短いビデオをためしにロードしてみて、 Dropbox のファイル更新通知までが動作することを確認しましょう。

# License

Copyright (c) 2013 tomykaira

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

http://opensource.org/licenses/MIT

一部のソースコードは [joker1007/pasokara_player3](https://github.com/joker1007/pasokara_player3) より拝借しています。
