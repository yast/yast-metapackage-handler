FROM yastdevel/ruby:sle15-sp1
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
    perl-XML-XPath
COPY . /usr/src/app

