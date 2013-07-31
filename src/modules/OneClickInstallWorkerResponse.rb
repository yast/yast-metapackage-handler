# encoding: utf-8

require "yast"

module Yast
  class OneClickInstallWorkerResponseClass < Module
    def main
      textdomain "oneclickinstall"

      Yast.import "XML"

      @DEFAULT_FAILURE_STAGE = _("unknown")
      @DEFAULT_ERROR_MESSAGE = _(
        "Root privileges are required. Either they were not supplied, or an unknown error occurred."
      )
      @DEFAULT_NOTE = ""
      @success = "false"
      @note = @DEFAULT_NOTE
      @failureStage = @DEFAULT_FAILURE_STAGE
      @errorMessage = @DEFAULT_ERROR_MESSAGE
      @failedPackages = []
      @failedPatterns = []
      @failedRepositories = []
    end

    # @return the success indicator.
    #
    def GetSuccess
      @success == "true"
    end
    # @param the success status to set.
    #
    def SetSuccess(value)
      if value
        @success = "true"
      else
        @success = "false"
      end

      nil
    end
    # @return the string representation of the failure stage of the install process.
    #
    def GetFailureStage
      @failureStage
    end
    # @param [String] value the string representation of the failure stage of the install process.
    #
    def SetFailureStage(value)
      @failureStage = value

      nil
    end
    # @return the error message.
    #
    def GetErrorMessage
      @errorMessage
    end
    # @param [String] value the error message.
    #
    def SetErrorMessage(value)
      @errorMessage = value

      nil
    end
    # @return the note.
    #
    def GetNote
      @note
    end
    # @param [String] value the note to set.
    #
    def SetNote(value)
      @note = value

      nil
    end

    def GetFailedPackages
      deep_copy(@failedPackages)
    end
    def AddFailedPackage(value)
      @failedPackages = Builtins.add(@failedPackages, value)

      nil
    end

    def GetFailedPatterns
      deep_copy(@failedPatterns)
    end
    def AddFailedPattern(value)
      @failedPatterns = Builtins.add(@failedPatterns, value)

      nil
    end

    def GetFailedRepositories
      deep_copy(@failedRepositories)
    end
    def AddFailedRepository(value)
      @failedRepositories = Builtins.add(@failedRepositories, value)

      nil
    end


    # Sets up YaST's XML serialisation for this data structure.
    #
    def SetupXML
      doc = {}
      Ops.set(
        doc,
        "listEntries",
        {
          "failedRepositories" => "repository",
          "failedPackages"     => "package",
          "failedPatterns"     => "pattern"
        }
      )
      Ops.set(doc, "cdataSections", [])
      Ops.set(doc, "rootElement", "OneClickInstallWorkerResponse")
      Ops.set(doc, "systemID", "/un/defined")
      Ops.set(doc, "nameSpace", "http://www.suse.com/1.0/yast2ns")
      Ops.set(doc, "typeNamespace", "http://www.suse.com/1.0/configns")
      XML.xmlCreateDoc(:OneClickInstallWorkerResponse, doc)

      nil
    end

    # Serialises this data structure to XML.
    # @param [String] filename the file to serialise to.
    #
    def ToXML(filename)
      SetupXML()
      toSerialise = {}
      toSerialise = Builtins.add(toSerialise, "success", @success)
      toSerialise = Builtins.add(toSerialise, "failureStage", @failureStage)
      toSerialise = Builtins.add(toSerialise, "errorMessage", @errorMessage)
      toSerialise = Builtins.add(toSerialise, "note", @note)
      toSerialise = Builtins.add(
        toSerialise,
        "failedRepositories",
        @failedRepositories
      )
      toSerialise = Builtins.add(toSerialise, "failedPackages", @failedPackages)
      toSerialise = Builtins.add(toSerialise, "failedPatterns", @failedPatterns)
      success = XML.YCPToXMLFile(
        :OneClickInstallWorkerResponse,
        toSerialise,
        filename
      )

      nil
    end

    # DeSerialises this data structure from XML.
    # @param [String] filename the file to deserialise from.
    #
    def FromXML(filename)
      SetupXML()
      deSerialised = XML.XMLToYCPFile(filename)
      @success = Ops.get_string(deSerialised, "success", "false")
      @failureStage = Ops.get_string(
        deSerialised,
        "failureStage",
        @DEFAULT_FAILURE_STAGE
      )
      @errorMessage = Ops.get_string(
        deSerialised,
        "errorMessage",
        @DEFAULT_ERROR_MESSAGE
      )
      @note = Ops.get_string(deSerialised, "note", @DEFAULT_NOTE)
      @failedRepositories = Ops.get_list(deSerialised, "failedRepositories", [])
      @failedPackages = Ops.get_list(deSerialised, "failedPackages", [])
      @failedPatterns = Ops.get_list(deSerialised, "failedPatterns", [])

      nil
    end

    publish :function => :GetSuccess, :type => "boolean ()"
    publish :function => :SetSuccess, :type => "void (boolean)"
    publish :function => :GetFailureStage, :type => "string ()"
    publish :function => :SetFailureStage, :type => "void (string)"
    publish :function => :GetErrorMessage, :type => "string ()"
    publish :function => :SetErrorMessage, :type => "void (string)"
    publish :function => :GetNote, :type => "string ()"
    publish :function => :SetNote, :type => "void (string)"
    publish :function => :GetFailedPackages, :type => "list <string> ()"
    publish :function => :AddFailedPackage, :type => "void (string)"
    publish :function => :GetFailedPatterns, :type => "list <string> ()"
    publish :function => :AddFailedPattern, :type => "void (string)"
    publish :function => :GetFailedRepositories, :type => "list <string> ()"
    publish :function => :AddFailedRepository, :type => "void (string)"
    publish :function => :ToXML, :type => "void (string)"
    publish :function => :FromXML, :type => "void (string)"
  end

  OneClickInstallWorkerResponse = OneClickInstallWorkerResponseClass.new
  OneClickInstallWorkerResponse.main
end
