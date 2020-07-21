# encoding: utf-8

require "yast"

module Yast
  class UserSettingsClass < Module
    include Yast::Logger

    def main

      Yast.import "XML"
      Yast.import "String"

      @FILENAME = ".y2usersettings"

      @settings = {}
      UserSettings()
    end

    def UserSettings
      homedir = Convert.convert(
        SCR.Execute(path(".target.bash_output"), "echo $HOME"),
        :from => "any",
        :to   => "map <string, any>"
      )
      @FILENAME = Ops.add(
        Ops.add(
          String.FirstChunk(
            Ops.get_string(
              homedir,
              "stdout",
              Convert.to_string(SCR.Read(path(".target.tmpdir")))
            ),
            "\n"
          ),
          "/"
        ),
        @FILENAME
      )
      Builtins.y2debug("Reading UserSettings from %1", @FILENAME)
      @settings = read_xml_file(@FILENAME)

      nil
    end

    # Retrieves the specified value.
    # @param [String] section    The section to find KVP in, could be the module/client name.
    # @param [String] key        The key used for retreiving value.
    # @return           The value of this key.
    def GetValue(section, key)
      Ops.get(Ops.get(@settings, section, {}), key)
    end

    # Retrieves the specified value and casts to a String.
    def GetStringValue(section, key)
      Convert.to_string(GetValue(section, key))
    end

    # Retrieves the specified value and casts to an integer.
    def GetIntegerValue(section, key)
      Convert.to_integer(GetValue(section, key))
    end

    # Retrieves the specified value and casts to a boolean.
    def GetBooleanValue(section, key)
      Convert.to_boolean(GetValue(section, key))
    end

    # Sets up a doctype for YaST's XML serialisation.
    #
    def SetupXML
      doc = {}
      Ops.set(doc, "cdataSections", [])
      Ops.set(doc, "rootElement", "UserSettings")
      Ops.set(doc, "systemID", "/un/defined")
      Ops.set(doc, "nameSpace", "http://www.suse.com/1.0/yast2ns")
      Ops.set(doc, "typeNamespace", "http://www.suse.com/1.0/configns")
      XML.xmlCreateDoc(:UserSettings, doc)

      nil
    end


    # Writes a key value pair for specified section.
    # @param [String] section    The section to write KVP in, could be the module/client name.
    # @param [String] key        The key used for retreiving value later.
    # @param [Object] value      The value to store.
    # @return           True if the settings were written to disk successfully. False on failure.
    def SetValue(section, key, value)
      value = deep_copy(value)
      kvps = Ops.get(@settings, section, {})
      kvps = Builtins.add(kvps, key, value)
      @settings = Builtins.add(@settings, section, kvps)
      SetupXML()
      Builtins.y2debug("Writing %1:%2 UserSetting to %3", key, value, @FILENAME)
      XML.YCPToXMLFile(:UserSettings, @settings, @FILENAME)
    end

    publish :function => :UserSettings, :type => "void ()"
    publish :function => :GetValue, :type => "any (string, string)"
    publish :function => :GetStringValue, :type => "string (string, string)"
    publish :function => :GetIntegerValue, :type => "integer (string, string)"
    publish :function => :GetBooleanValue, :type => "boolean (string, string)"
    publish :function => :SetValue, :type => "boolean (string, string, any)"

  private

    # Turns the content of the specified XML file into a hash
    #
    # @param path [String] name of the XML file
    # @return [Hash] empty hash if the file does not exists or cannot be processed
    def read_xml_file(path)
      XML.XMLToYCPFile(path)
    rescue RuntimeError => e
      log.debug "Using empty hash for #{path}: #{e.inspect}"
      {}
    end
  end

  UserSettings = UserSettingsClass.new
  UserSettings.main
end
