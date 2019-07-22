FROM yastdevel/ruby:sle12-sp5

RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
    perl-XML-XPath

COPY . /usr/src/app

