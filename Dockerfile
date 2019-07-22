FROM yastdevel/ruby:sle12-sp5

RUN zypper --non-interactive in --no-recommends \
    perl-XML-XPath

COPY . /usr/src/app

