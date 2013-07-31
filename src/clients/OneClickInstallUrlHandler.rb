# encoding: utf-8

module Yast
  class OneClickInstallUrlHandlerClient < Client
    def main
      #Allows embedding just the URL to the metapackage in the web page, instead of the entire package.
      textdomain "oneclickinstall"

      @args = Convert.convert(WFM.Args, :from => "list", :to => "list <string>")
      @urlurl = Ops.get(@args, 0, "")
      @INVALID_CHARS = "\n"
      @url = Convert.to_string(SCR.Read(path(".target.string"), @urlurl))
      WFM.call(
        "OneClickInstallUI",
        [Builtins.deletechars(@url, @INVALID_CHARS)]
      )

      nil
    end
  end
end

Yast::OneClickInstallUrlHandlerClient.new.main
