<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:df="http://dita2indesign.org/dita/functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="df ditaarch" version="2.0">
<!-- This transform takes DITA content and wraps mixed content with the <p>
     element for all elements identified by the ts:isWrapMixed() boolean
     function. The ts:isWrapMixed() function definition is in file
     ts_dita_tidy_util.xsl. Edit the function definition to add or remove
     elements identified for wrapping.
     
     Parameters:
     
       preservePIs: Preserve processing instructions. The default value 'yes'.
     
       preserveComments: Preserve comments. The default value is 'yes'.
     
       outputfile: Output file name. The default value is 'out.xml'.
     
     
     Output: This transform sends its output to the file specified in the
     outfile parameter.
     
     Dependencies: This module depends upon ts_dita_tidy_util
     
     Use cases:
     1. Simplify output stylesheet logic by reducing the number of mixed-content
     contexts that a stylesheet has to consider. This can be especially helpful
     when writing logic to render lists and tables.
     2. Convert out-of-the-box DITA to constrained versions of DITA that do not
     allow mixed content in certain places.
     
     Author: Bob Thomas, bob.thomas@tagsmiths.com
-->

   <!--  Depends on these modules:  -->
   <xsl:import href="dita-support-lib.xsl"/>
   <xsl:import href="relpath_util.xsl"/>
   <!-- outputfile can be used in conjunction with the ant 'xslt' task's
      filenameparameter attribute when you wish to process several topics. -->
   <xsl:param name="outputfile">/home/rnt/Testing/DitaTidy/out.xml</xsl:param>
   <xsl:param name="preservePIs">yes</xsl:param>
   <xsl:param name="preserveComments">yes</xsl:param>

   <xsl:preserve-space elements="pre lines codeblock"/>

   <xsl:output method="xml" indent="no"/>

   <xsl:template name="dita-tidy" match="/">
      <xsl:variable name="rootElement">
         <xsl:value-of select="name(/*[1])"/>
      </xsl:variable>
      <xsl:variable name="publicDoctype">
         <xsl:choose>
            <xsl:when test="$rootElement = 'concept'">
               <xsl:text>-//OASIS//DTD DITA Concept//EN</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'reference'">
               <xsl:text>-//OASIS//DTD DITA Reference//EN</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'task'">
               <xsl:text>-//OASIS//DTD DITA Task//EN</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'topic'">
               <xsl:text>-//OASIS//DTD DITA Topic//EN</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'troubleshooting'">
          <xsl:text>-//OASIS//DTD DITA Troubleshooting//EN</xsl:text>
        </xsl:when>
        <xsl:when test="$rootElement = 'dita'">
               <xsl:text>-//OASIS//DTD DITA Composite//EN</xsl:text>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="systemId">
         <xsl:choose>
            <xsl:when test="$rootElement = 'concept'">
               <xsl:text>urn:concept.dtd</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'reference'">
               <xsl:text>urn:reference.dtd</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'task'">
               <xsl:text>urn:task.dtd</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'topic'">
               <xsl:text>urn:topic.dtd</xsl:text>
            </xsl:when>
            <xsl:when test="$rootElement = 'troubleshooting'">
          <xsl:text>urn:troubleshooting.dtd</xsl:text>
        </xsl:when>
        <xsl:when test="$rootElement = 'dita'">
               <xsl:text>urn:ditabase.dtd</xsl:text>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:result-document method="xml" indent="no" doctype-public="{$publicDoctype}"
         doctype-system="{$systemId}" href="{$outputfile}">
         <xsl:apply-templates/>
      </xsl:result-document>
   </xsl:template>

   <xsl:template match="*">
      <!--<xsl:comment>START <xsl:value-of select="name()"/></xsl:comment>-->
    <xsl:element name="{name(.)}">
         <xsl:call-template name="output-attrs"/>
         <xsl:apply-templates/>
      </xsl:element>
   <!--<xsl:comment>END <xsl:value-of select="name()"/></xsl:comment>-->
  </xsl:template>

   <xsl:template match="*[df:isWrapMixed(.)]">
      <xsl:call-template name="wrap-mixed-content"/>
   </xsl:template>

   <xsl:template name="wrap-mixed-content">
      <!-- buffer intermediate output where all text() is wrapped in
            <rawtext wrapWithP="yes"> and all inline elements have 
            @wrapWithP="yes". Later, this buffer will be processed
            by "xsl:for-each-group, group-adjacent" to wrap contiguous
            text() and inline elements with <p> elements.
        -->
      <xsl:variable name="wrapped-text-buffer">
         <xsl:apply-templates mode="populate-wrapped-text-buffer"/>
      </xsl:variable>
      <!--<xsl:result-document method="xml" indent="no" href="/home/rnt/Testing/DitaTidy/wtb.xml">
      <foo>
        <xsl:apply-templates mode="populate-wrapped-text-buffer"/>
      </foo>
    </xsl:result-document>-->
    <xsl:element name="{name(.)}">
         <xsl:call-template name="output-attrs"/>
         <!-- Iterate over the top-level nodes in wrapped-text-buffer, wrapping
              all contiguous *[@wrapWithP='yes'] in a single <p> element. The
              template rule that matches the temporary <rawtext> element
              unwraps the <rawtext> tags surronding the text.
            -->
         <xsl:for-each-group select="$wrapped-text-buffer/*"
            group-adjacent="boolean(self::*[@wrapWithP = 'yes'])">
            <xsl:choose>
               <xsl:when test="current-grouping-key()">
                  <xsl:element name="p">
                     <xsl:apply-templates select="current-group()" mode="wrap"/>
                  </xsl:element>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="current-group()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:element>
   </xsl:template>

   <xsl:template match="rawprocessing-instruction">
      <xsl:choose>
         <xsl:when test="$preservePIs = 'yes'">
            <xsl:processing-instruction name="{@name}"><xsl:value-of select="."/></xsl:processing-instruction>
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <xsl:template name="output-attrs">
      <xsl:for-each select="@*">
         <xsl:choose>
            <xsl:when test="name(.) = 'class'"/>
            <xsl:when test="starts-with(name(.), 'ish')"/>
            <xsl:when test="name(.) = 'wrapWithP'"/>
            <xsl:when test="matches(name(.), 'ditaarch')"/>
            <xsl:when test="name(.) = 'domains'"/>
            <xsl:otherwise>
               <xsl:attribute name="{name(.)}">
                  <xsl:value-of select="."/>
               </xsl:attribute>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>

   <xsl:template match="comment()">
      <xsl:if test="$preserveComments = 'yes'">
         <xsl:comment><xsl:value-of select="."/></xsl:comment>
      </xsl:if>
   </xsl:template>

   <xsl:template match="processing-instruction()">
      <xsl:choose>
         <xsl:when test="$preservePIs = 'yes'">
            <xsl:processing-instruction name="{name(.)}"><xsl:value-of select="."/></xsl:processing-instruction>
         </xsl:when>
      </xsl:choose>
   </xsl:template>


   <!-- BEGIN templates for mode populate-wrapped-text-buffer -->
    <xsl:template match="text()" mode="populate-wrapped-text-buffer">
        <!-- If the text() contains significant white-space or something
             other than white-space, then wrap it with temporary element
             <rawtext wrapWithText="yes">
        -->
        <xsl:choose>
            <!-- Ignore white-space only text() when it is the first node. -->
            <xsl:when test="normalize-space(.) = '' and position() = 1">
                <!-- Ignore this node -->
            </xsl:when>
            <!-- Ignore white-space only text() when it is the last node. -->
            <xsl:when test="normalize-space(.) = '' and position() = last()">
                <!-- Ignore this node -->
            </xsl:when>
            <!-- Ignore white-space only text() when it is the only node between
                 between two block elements. -->
            <xsl:when
                test="
                    normalize-space(.) = '' and
                    preceding-sibling::*[1] and df:isBlock(preceding-sibling::*[1]) and
                    following-sibling::*[1] and df:isBlock(following-sibling::*[1])">
                <!-- Ignore this node -->
            </xsl:when>
            <!-- Strip leading and trailing spaces when text() is the only node between
                 between two block elements, then wrap the text() -->
            <xsl:when
                test="
                    preceding-sibling::*[1] and df:isBlock(preceding-sibling::*[1]) and
                    following-sibling::*[1] and df:isBlock(following-sibling::*[1])">
                <xsl:element name="rawtext">
                    <xsl:attribute name="wrapWithP">yes</xsl:attribute>
                    <xsl:value-of select="replace(., '^\s+(.*)\s+$', '$1')"/>
                </xsl:element>
            </xsl:when>
            <!-- Strip leading spaces when text() is the first node or when text()
                 is preceded by a block element, then wrap the text(). -->
            <xsl:when
                test="
                    (position() = 1 and matches(., '^\s+')) or
                    (preceding-sibling::*[1] and df:isBlock(preceding-sibling::*[1]) and matches(., '^\s+'))">
                <xsl:element name="rawtext">
                    <xsl:attribute name="wrapWithP">yes</xsl:attribute>
                    <xsl:value-of select="replace(., '^\s+', '')"/>
                </xsl:element>
            </xsl:when>
            <!-- Strip trailing spaces when text() is the last node or when text()
                 is followed by a block element, then wrap the text(). -->
            <xsl:when
                test="
                    (position() = last() and matches(., '\s+$')) or
                    (following-sibling::*[1] and df:isBlock(following-sibling::*[1]) and matches(., '\s+$'))">
                <xsl:element name="rawtext">
                    <xsl:attribute name="wrapWithP">yes</xsl:attribute>
                    <xsl:value-of select="replace(., '\s+$', '')"/>
                </xsl:element>
            </xsl:when>
            <!-- No whiteshpace handling, just wrap the text(). -->
            <xsl:otherwise>
                <xsl:element name="rawtext">
                    <xsl:attribute name="wrapWithP">yes</xsl:attribute>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

   <xsl:template match="comment()" mode="populate-wrapped-text-buffer">
      <!-- Preserve XML comments -->
      <xsl:if test="$preserveComments = 'yes'">
         <xsl:element name="rawcomment">
            <xsl:attribute name="wrapWithP">yes</xsl:attribute>
            <xsl:value-of select="normalize-space(.)"/>
         </xsl:element>
      </xsl:if>
   </xsl:template>

   <xsl:template match="processing-instruction()" mode="populate-wrapped-text-buffer">
      <!-- Preserve processing instructions -->
      <xsl:if test="$preservePIs = 'yes'">
         <xsl:element name="rawprocessing-instruction">
            <xsl:attribute name="name">
               <xsl:value-of select="name(.)"/>
            </xsl:attribute>
            <xsl:attribute name="wrapWithP">yes</xsl:attribute>
            <xsl:value-of select="normalize-space(.)"/>
         </xsl:element>
      </xsl:if>
   </xsl:template>

   <xsl:template match="*[df:isInline(.)]" mode="populate-wrapped-text-buffer">
      <!-- When the element is an inline, add temporary attribute wrapWithP. -->
      <xsl:element name="{name(.)}">
         <xsl:call-template name="output-attrs"/>
         <xsl:attribute name="wrapWithP">yes</xsl:attribute>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="*" mode="populate-wrapped-text-buffer">
      <xsl:apply-templates select="."/>
   </xsl:template>
   <!-- END templates for mode populate-wrapped-text-buffer -->


   <!-- BEGIN templates for mode wrap -->
   <!-- Only elements previously identified as inlines are submitted with mode "wrap".-->
   <xsl:template match="*" mode="wrap">
      <xsl:apply-templates select="."/>
   </xsl:template>

   <xsl:template match="rawtext" mode="wrap">
      <xsl:apply-templates/>
   </xsl:template>

   <xsl:template match="rawcomment" mode="wrap">
      <xsl:if test="$preserveComments = 'yes'">
         <xsl:comment><xsl:value-of select="."/></xsl:comment>
      </xsl:if>
   </xsl:template>
   <!-- END templates for mode wrap -->

</xsl:stylesheet>
