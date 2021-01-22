# encoding: utf-8

require "yast"
require "rexml/document"

module Yast
  class OneClickInstallClass < Module
    include Yast::Logger

    def main
      # Module to provide simple API for working with the One Click Install metapackages.
      # Enables removal of non-UI logic from UI module.
      #
      textdomain "oneclickinstall"

      Yast.import "XML"
      Yast.import "Product"
      Yast.import "Language"

      # 	repositories =
      #		$[ url =>
      #			$[
      #				name,
      #				summary,
      #				description,
      #				recommended
      #			]
      #
      #		]
      #
      @repositories = {}

      #	software =
      #		$[ name =>
      #			$[
      #				summary,
      #				description,
      #				recommended
      #			]
      #		]
      #
      @software = {}

      #Whether the user should remain subscribed to these repositories post installation.
      @remainSubscribed = true

      #The name of this software bundle.
      @name = ""

      #The summary of this software bundle.
      @summary = ""

      #The description of this software bundle.
      @description = ""
    end

    # Load the Metapackage data from the YML file supplied for further processing.
    #
    # Convert data into two hashes, one for repositories, one for software.
    # Use the Product.rb to obtain the correct version for our product.
    # Use the Language.rb to obtain correct strings for our language.
    #
    # Pick the strings, mirror, and product at evaluation time.
    #
    # Note: This must be called before any of the rest of the methods.
    #
    # @param [String] file XML file with meta data.
    #
    def Load(file)
      distversion = Product.name
      lang = Language.language

      xml = xml_from_file(file)

      log.info "distversion = #{distversion}, lang = #{lang}"

      group = xpath_element(xml, "/metapackage/group", distversion: distversion)

      return if !group

      log.info "distversion in YMP = #{group.attributes['distversion']}"

      # pick name, summary, description from group element, if any, else from first package
      @name = xpath_text(group, "name") ||
              xpath_text(group, "software/item/name") || ""

      @summary = xpath_text(group, "summary", lang: lang) ||
                 xpath_text(group, "software/item/summary", lang: lang) || ""

      @description = xpath_text(group, "description", lang: lang) ||
                     xpath_text(group, "software/item/description", lang: lang) || ""

      @remainSubscribed = xpath_text(group, "remainsubscribed") != "false"

      log.info "name = #{@name}, remainSubscribed = #{@remainSubscribed}"
      log.info "summary = #{@summary}"
      log.info "description = #{@description}"

      repos = xpath_match(group, "repositories/repository")

      repos.each do |repo|
        recommended = repo.attributes["recommended"] != "false"
        url = xpath_text(repo, "url") || ""
        name = xpath_text(repo, "name") || ""
        summary = xpath_text(repo, "summary", lang: lang) || ""
        description = xpath_text(repo, "description", lang: lang) || ""

        @repositories[url] = {
          "name" => name, "summary" => summary, "description" => description,
          "recommended" => recommended.to_s
        }
      end

      log.info "repositories = #{@repositories}"

      items = xpath_match(group, "software/item")

      items.each do |item|
        name = xpath_text(item, "name") || ""
        summary = xpath_text(item, "summary", lang: lang) || ""
        description = xpath_text(item, "description", lang: lang) || ""
        recommended = item.attributes["recommended"] != "false"
        action = item.attributes["action"] != "remove" ? "install" : "remove"
        type = item.attributes["type"] != "pattern" ? "package" : "pattern"

        @software[name] = {
          "summary" => summary, "description" => description, "recommended" => recommended.to_s,
          "action" => action, "type" => type
        }
      end

      log.info "software = #{@software}"

      nil
    end

    # Parse XML file.
    #
    # @param [String] file
    #
    # @return [REXML::Document] XML data
    #
    def xml_from_file(file)
      return REXML::Document.new(File.read(file))
    rescue
      return REXML::Document.new("")
    end

    # XPath match.
    #
    # @param [REXML::Document,REXML::Element] node
    # @param [String] path
    #
    # @return [Array<REXML::Element>] matching elements
    #
    def xpath_match(node, path)
      REXML::XPath.match(node, path)
    end

    # First matching element.
    #
    # This finds the first matching element. If an attribute is specified as
    # last argument, it tries to find a match that also matches this
    # attribute.
    #
    # If that finds no match, an element without that attribute is looked
    # for.
    #
    # @example Find summary and prefer German translation
    #    xpath_element(node, "summary", lang: de_DE)
    #
    # @param [REXML::Document,REXML::Element] node
    # @param [String] path
    # @param [Array<Hash>] attr
    #
    # @return [REXML::Element,nil] matching element or nil
    #
    def xpath_element(node, path, *attr)
      return xpath_match(node, path).first if attr.empty?

      key = attr.first.keys.first
      val = attr.first[key]

      xpath_match(node, "#{path}[@#{key}='#{val}']").first ||
      xpath_match(node, "#{path}[not(@#{key})]").first
    end

    # Text field of first matching element.
    #
    # @see #xpath_element for a detailed description.
    #
    # @param [REXML::Document,REXML::Element] node
    # @param [String] path
    # @param [Array<Hash>] attr
    #
    # @return [String,nil] text of first matching element or nil
    #
    def xpath_text(node, path, *attr)
      xpath_element(node, path, *attr)&.text
    end

    # <region name="Repositories"> *

    # @return a list of the URLs of the repositories currently selected for addition.
    #
    def GetRequiredRepositories
      repoURLs = []
      Builtins.foreach(@repositories) do |repoURL, repoDetails|
        if Ops.get(repoDetails, "recommended", "false") == "true"
          repoURLs = Builtins.add(repoURLs, repoURL)
        end
      end
      deep_copy(repoURLs)
    end

    # Ensures that the repository with the specified URL is selected for addition.
    # @param [String] url the url of the repository to ensure is selected for addition.
    #
    def SetRequiredRepository(url)
      repoDetails = Ops.get(@repositories, url)
      return if repoDetails == nil
      repoDetails = Builtins.add(repoDetails, "recommended", "true")
      @repositories = Builtins.add(@repositories, url, repoDetails)

      nil
    end

    #  @return a list of the URLs of the repositories currently NOT selected for addition.
    #
    def GetNonRequiredRepositories
      repoURLs = []
      Builtins.foreach(@repositories) do |repoURL, repoDetails|
        if Ops.get(repoDetails, "recommended", "false") == "false"
          repoURLs = Builtins.add(repoURLs, repoURL)
        end
      end
      deep_copy(repoURLs)
    end

    # Ensures that the repository with the specified URL is NOT selected for addition.
    # @param [String] url the url to ensure is not selected for addition
    #
    def SetNonRequiredRepository(url)
      repoDetails = Ops.get(@repositories, url)
      return if repoDetails == nil
      repoDetails = Builtins.add(repoDetails, "recommended", "false")
      @repositories = Builtins.add(@repositories, url, repoDetails)

      nil
    end


    # Ensures that the repositories with specified URLs are selected for addition, and all others are not.
    # @param [Array<String>] urls the urls to ensure are selected.
    #
    def SetRequiredRepositories(urls)
      urls = deep_copy(urls)
      Builtins.foreach(@repositories) do |url, repoDetails|
        if Builtins.contains(urls, url)
          SetRequiredRepository(url)
        else
          SetNonRequiredRepository(url)
        end
      end

      nil
    end


    # @return the name of the repository with the specified name.
    #
    def GetRepositoryName(url)
      repoDetails = Ops.get(@repositories, url)
      return "" if repoDetails == nil
      Ops.get(repoDetails, "name", "")
    end

    # @return the summary of the repository with the specified name.
    # This will be in the user's current language if there was a localised summary available.
    #
    def GetRepositorySummary(url)
      repoDetails = Ops.get(@repositories, url)
      return "" if repoDetails == nil
      Ops.get(repoDetails, "summary", "")
    end

    # @return the description of the repository with the specified name.
    # This will be in the user's current language if there was a localised description available.
    #
    def GetRepositoryDescription(url)
      repoDetails = Ops.get(@repositories, url)
      return "" if repoDetails == nil
      Ops.get(repoDetails, "description", "")
    end

    # </region> *

    # <region name="Software"> *

    # @return a list of the names of the software currently selected for installation.
    #
    def GetRequiredSoftware
      names = []
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "true" &&
            Ops.get(softwareDetails, "action", "install") == "install"
          names = Builtins.add(names, name)
        end
      end
      deep_copy(names)
    end

    def GetRequiredPackages
      names = []
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "true" &&
            Ops.get(softwareDetails, "action", "install") == "install" &&
            Ops.get(softwareDetails, "type", "package") == "package"
          names = Builtins.add(names, name)
        end
      end
      deep_copy(names)
    end

    def GetRequiredPatterns
      names = []
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "true" &&
            Ops.get(softwareDetails, "action", "install") == "install" &&
            Ops.get(softwareDetails, "type", "package") == "pattern"
          names = Builtins.add(names, name)
        end
      end
      deep_copy(names)
    end

    # @return a list of the names of the software currently selected for removal.
    #
    def GetRequiredRemoveSoftware
      names = []
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "true" &&
            Ops.get(softwareDetails, "action", "install") == "remove"
          names = Builtins.add(names, name)
        end
      end
      deep_copy(names)
    end

    # Ensures the software with the specified name is selected for installation or removal.
    # @param name [String] the name of the software to ensure is selected for installation.
    #
    def SetRequiredSoftware(name)
      softwareDetails = Ops.get(@software, name)
      return if softwareDetails == nil
      softwareDetails = Builtins.add(softwareDetails, "recommended", "true")
      @software = Builtins.add(@software, name, softwareDetails)

      nil
    end

    # @return a list of the names of the software currently NOT selected for installation.
    #
    def GetNonRequiredSoftware
      names = []
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "false" &&
            Ops.get(softwareDetails, "action", "install") == "install"
          names = Builtins.add(names, name)
        end
      end
      deep_copy(names)
    end

    # @return a list of the names of the software currently selected for removal.
    #
    def GetNonRequiredRemoveSoftware
      names = []
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "false" &&
            Ops.get(softwareDetails, "action", "install") == "remove"
          names = Builtins.add(names, name)
        end
      end
      deep_copy(names)
    end

    # Ensures the software with the specified name is NOT selected for installation or removal.
    # @param name [String] the name of the software to ensure is NOT selected for installation.
    #
    def SetNonRequiredSoftware(name)
      softwareDetails = Ops.get(@software, name)
      return if softwareDetails == nil
      softwareDetails = Builtins.add(softwareDetails, "recommended", "false")
      @software = Builtins.add(@software, name, softwareDetails)

      nil
    end

    # Ensures that the repositories with specified URLs are selected for addition, and all others are not.
    # Invalid pluralisation due to lack of proper overloading :(
    # @param names [Array<String>] the names of the software to ensure is selected for installation.
    #
    def SetRequiredSoftwares(names)
      names = deep_copy(names)
      Builtins.foreach(@software) do |name, softwareDetails|
        if Builtins.contains(names, name)
          SetRequiredSoftware(name)
        else
          SetNonRequiredSoftware(name)
        end
      end

      nil
    end

    # @return the summary for the software with specified name.
    # This will be in the user's current language if there was a localised summary available.
    #
    def GetSoftwareSummary(name)
      softwareDetails = Ops.get(@software, name)
      return "" if softwareDetails == nil
      Ops.get(softwareDetails, "summary", "")
    end

    # @return the description for the software with specified name.
    # This will be in the user's current language if there was a localised description available.
    #
    def GetSoftwareDescription(name)
      softwareDetails = Ops.get(@software, name)
      return "" if softwareDetails == nil
      Ops.get(softwareDetails, "description", "")
    end

    # </region> *

    # <region name="Processing"> *

    # Specify whether the user should remain subscribed to the repositories after installation of this software is complete.
    # @param value [Boolean] indicating whether the user should remain subscribed.
    #
    def SetRemainSubscribed(value)
      @remainSubscribed = value

      nil
    end

    # @return the current setting of whether the user should remain subscribed to repositories after installation.
    #
    def GetRemainSubscribed
      @remainSubscribed
    end

    # @return the name for this software bundle.
    #
    def GetName
      @name
    end

    # @return the summary for this software bundle.
    # This will be in the user's current language if there was a localised summary available.
    #
    def GetSummary
      @summary
    end

    # @return the description for this software bundle.
    # This will be in the user's current language if there was a localised description available.
    #
    def GetDescription
      @description
    end

    # @return Find out whether we have any repositories that need to be added for this installation.
    # Useful to find out whether to display this wizard step.
    #
    def HaveRepositories
      Ops.greater_than(Builtins.size(@repositories), 0)
    end

    # @return Find out whether we have any software that needs to be installed for this installation.
    # Useful to find out whether to display this wizard step.
    #
    def HaveSoftware
      haveSoftware = false
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "action", "install") == "install"
          haveSoftware = true
          next haveSoftware
        end
      end
      haveSoftware
    end

    def HavePackagesToInstall
      have = false
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "true" &&
            Ops.get(softwareDetails, "action", "install") == "install" &&
            Ops.get(softwareDetails, "type", "package") == "package"
          have = true
          next have
        end
      end
      have
    end

    def HavePatternsToInstall
      have = false
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "recommended", "false") == "true" &&
            Ops.get(softwareDetails, "action", "install") == "install" &&
            Ops.get(softwareDetails, "type", "package") == "pattern"
          have = true
          next have
        end
      end
      have
    end

    def HaveRepositoriesToInstall
      have = false
      Builtins.foreach(@repositories) do |url, repoDetails|
        if Ops.get(repoDetails, "recommended", "false") == "true"
          have = true
          next have
        end
      end
      have
    end

    def HaveRemovalsToInstall
      have = false
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "action", "install") == "remove" &&
            Ops.get(softwareDetails, "recommended", "false") == "true"
          have = true
          next have
        end
      end
      have
    end

    # @return Find out whether we have any software that needs to be removed for this installation.
    # Useful to find out whether to display this wizard step.
    #
    def HaveRemovals
      haveSoftware = false
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "action", "install") == "remove"
          haveSoftware = true
          next haveSoftware
        end
      end
      haveSoftware
    end

    # @return Whether we have anything to do
    # Determine whether we have a proper metapackage, useful as we can't throw exceptions.
    #
    def HaveAnythingToDo
      Ops.greater_than(Builtins.size(@repositories), 0) &&
        Ops.greater_than(Builtins.size(@software), 0)
    end

    # @return Whether we have a bundle description for the whole bundle
    # Build service isn't currently generating one for YMPs for individual packages.
    #
    def HaveBundleDescription
      @description != "" && @summary != "" && @name != ""
    end

    # @return Whether we have any recommended repositories or packages
    # If not we will have to show advanced view.
    #
    def HaveAnyRecommended
      rec = false
      Builtins.foreach(@software) do |name, softwareDetails|
        if Ops.get(softwareDetails, "action", "install") == "install" &&
            Ops.get(softwareDetails, "recommended", "false") == "true"
          rec = true
        end
        true
      end
      Builtins.foreach(@repositories) do |url, repoDetails|
        if Ops.get(repoDetails, "recommended", "false") == "true"
          rec = true
          next true
        end
      end
      rec
    end


    # Converts our map -> map structure to a list of maps with a "key" element.
    # This is friendly for yast's XML serialisation support.
    #
    def makeXMLFriendly(toFlatten)
      toFlatten = deep_copy(toFlatten)
      flattened = []
      Builtins.foreach(toFlatten) do |key, value|
        flattened = Builtins.add(flattened, Builtins.add(value, "key", key))
      end
      deep_copy(flattened)
    end

    # Converts back from the above to our original structure
    #
    def fromXMLFriendly(toUnFlatten)
      toUnFlatten = deep_copy(toUnFlatten)
      unflattened = {}
      Builtins.foreach(toUnFlatten) do |item|
        key = Ops.get(item, "key", "nokey")
        unflattened = Builtins.add(
          unflattened,
          key,
          Builtins.remove(item, "key")
        )
      end
      deep_copy(unflattened)
    end

    # Sets up a doctype for YaST's XML serialisation.
    #
    def SetupXML
      doc = {}
      Ops.set(doc, "listEntries", { "repositories" => "repository" })
      Ops.set(doc, "cdataSections", [])
      Ops.set(doc, "rootElement", "OneClickInstall")
      Ops.set(doc, "systemID", "/un/defined")
      Ops.set(doc, "nameSpace", "http://www.suse.com/1.0/yast2ns")
      Ops.set(doc, "typeNamespace", "http://www.suse.com/1.0/configns")
      XML.xmlCreateDoc(:OneClickInstall, doc)

      nil
    end

    # Serialises this data structure to XML.
    # @param [String] filename the file to write the XML to.
    #
    def ToXML(filename)
      SetupXML()
      toSerialise = {}
      toSerialise = Builtins.add(
        toSerialise,
        "software",
        makeXMLFriendly(@software)
      )
      toSerialise = Builtins.add(
        toSerialise,
        "repositories",
        makeXMLFriendly(@repositories)
      )
      toSerialise = Builtins.add(
        toSerialise,
        "remainSubscribed",
        @remainSubscribed
      )
      toSerialise = Builtins.add(toSerialise, "name", @name)
      toSerialise = Builtins.add(toSerialise, "summary", @summary)
      toSerialise = Builtins.add(toSerialise, "description", @description)

      success = XML.YCPToXMLFile(:OneClickInstall, toSerialise, filename)

      nil
    end

    # DeSerialises this data structure from XML.
    # @param [String] filename the file to read the XML from.
    #
    def FromXML(filename)
      SetupXML()
      deSerialised = XML.XMLToYCPFile(filename)
      @software = fromXMLFriendly(Ops.get_list(deSerialised, "software", []))
      @repositories = fromXMLFriendly(
        Ops.get_list(deSerialised, "repositories", [])
      )
      @remainSubscribed = Ops.get_boolean(
        deSerialised,
        "remainSubscribed",
        false
      )
      @summary = Ops.get_string(deSerialised, "summary", "")
      @description = Ops.get_string(deSerialised, "description", "")
      @name = Ops.get_string(deSerialised, "name", "")

      nil
    end

    publish :function => :Load, :type => "void (string)"
    publish :function => :GetRequiredRepositories, :type => "list <string> ()"
    publish :function => :SetRequiredRepository, :type => "void (string)"
    publish :function => :GetNonRequiredRepositories, :type => "list <string> ()"
    publish :function => :SetNonRequiredRepository, :type => "void (string)"
    publish :function => :SetRequiredRepositories, :type => "void (list <string>)"
    publish :function => :GetRepositoryName, :type => "string (string)"
    publish :function => :GetRepositorySummary, :type => "string (string)"
    publish :function => :GetRepositoryDescription, :type => "string (string)"
    publish :function => :GetRequiredSoftware, :type => "list <string> ()"
    publish :function => :GetRequiredPackages, :type => "list <string> ()"
    publish :function => :GetRequiredPatterns, :type => "list <string> ()"
    publish :function => :GetRequiredRemoveSoftware, :type => "list <string> ()"
    publish :function => :SetRequiredSoftware, :type => "void (string)"
    publish :function => :GetNonRequiredSoftware, :type => "list <string> ()"
    publish :function => :GetNonRequiredRemoveSoftware, :type => "list <string> ()"
    publish :function => :SetNonRequiredSoftware, :type => "void (string)"
    publish :function => :SetRequiredSoftwares, :type => "void (list <string>)"
    publish :function => :GetSoftwareSummary, :type => "string (string)"
    publish :function => :GetSoftwareDescription, :type => "string (string)"
    publish :function => :SetRemainSubscribed, :type => "void (boolean)"
    publish :function => :GetRemainSubscribed, :type => "boolean ()"
    publish :function => :GetName, :type => "string ()"
    publish :function => :GetSummary, :type => "string ()"
    publish :function => :GetDescription, :type => "string ()"
    publish :function => :HaveRepositories, :type => "boolean ()"
    publish :function => :HaveSoftware, :type => "boolean ()"
    publish :function => :HavePackagesToInstall, :type => "boolean ()"
    publish :function => :HavePatternsToInstall, :type => "boolean ()"
    publish :function => :HaveRepositoriesToInstall, :type => "boolean ()"
    publish :function => :HaveRemovalsToInstall, :type => "boolean ()"
    publish :function => :HaveRemovals, :type => "boolean ()"
    publish :function => :HaveAnythingToDo, :type => "boolean ()"
    publish :function => :HaveBundleDescription, :type => "boolean ()"
    publish :function => :HaveAnyRecommended, :type => "boolean ()"
    publish :function => :ToXML, :type => "void (string)"
    publish :function => :FromXML, :type => "void (string)"
  end

  OneClickInstall = OneClickInstallClass.new
  OneClickInstall.main
end
