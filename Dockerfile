FROM registry.opensuse.org/yast/sle-15/sp2/containers/yast-ruby
RUN zypper --gpg-auto-import-keys --non-interactive in --no-recommends \
    perl-XML-XPath
COPY . /usr/src/app

