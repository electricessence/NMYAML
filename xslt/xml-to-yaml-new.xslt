<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:yaml="http://yaml.org/xml/1.2">

  <xsl:output method="text" encoding="UTF-8" indent="no"/>
  <xsl:strip-space elements="*"/>

  <!-- Root template -->
  <xsl:template match="yaml:document">
    <xsl:apply-templates select="yaml:scalar | yaml:sequence | yaml:mapping"/>
  </xsl:template>

  <!-- Scalar template -->
  <xsl:template match="yaml:scalar">
    <xsl:param name="indent" select="0"/>
    <xsl:choose>
      <xsl:when test="@type = 'string' and (contains(., ' ') or contains(., ':') or contains(., '#') or contains(., '''') or contains(., '&quot;'))">
        <xsl:text>"</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="."/>
        </xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:when test="@type = 'string' and normalize-space(.) = ''">
        <xsl:text>""</xsl:text>
      </xsl:when>
      <xsl:when test="@type = 'null' or normalize-space(.) = ''">
        <xsl:text>null</xsl:text>
      </xsl:when>
      <xsl:when test="@type = 'boolean'">
        <xsl:choose>
          <xsl:when test=". = 'true' or . = 'True' or . = 'TRUE' or . = 'yes' or . = 'Yes' or . = 'YES' or . = 'on' or . = 'On' or . = 'ON'">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- Add anchor if present -->
    <xsl:if test="@anchor">
      <xsl:text> &amp;</xsl:text>
      <xsl:value-of select="@anchor"/>
    </xsl:if>
  </xsl:template>

  <!-- Sequence template -->
  <xsl:template match="yaml:sequence">
    <xsl:param name="indent" select="0"/>
    <!-- Add anchor if present -->
    <xsl:if test="@anchor">
      <xsl:text>&amp;</xsl:text>
      <xsl:value-of select="@anchor"/>
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count(yaml:item) = 0">
        <xsl:text>[]</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="yaml:item">
          <xsl:if test="position() > 1">
            <xsl:text>&#10;</xsl:text>
            <xsl:call-template name="indent">
              <xsl:with-param name="level" select="$indent"/>
            </xsl:call-template>
          </xsl:if>
          <xsl:text>- </xsl:text>
          <xsl:apply-templates select="*">
            <xsl:with-param name="indent" select="$indent + 1"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Mapping template -->
  <xsl:template match="yaml:mapping">
    <xsl:param name="indent" select="0"/>
    <!-- Add anchor if present -->
    <xsl:if test="@anchor">
      <xsl:text>&amp;</xsl:text>
      <xsl:value-of select="@anchor"/>
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count(yaml:entry) = 0">
        <xsl:text>{}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="yaml:entry">
          <xsl:if test="position() > 1">
            <xsl:text>&#10;</xsl:text>
            <xsl:call-template name="indent">
              <xsl:with-param name="level" select="$indent"/>
            </xsl:call-template>
          </xsl:if>
          <!-- Handle key -->
          <xsl:apply-templates select="yaml:key/*">
            <xsl:with-param name="indent" select="$indent"/>
          </xsl:apply-templates>
          <xsl:text>: </xsl:text>
          <!-- Handle value -->
          <xsl:choose>
            <xsl:when test="yaml:value/yaml:mapping or yaml:value/yaml:sequence">
              <xsl:text>&#10;</xsl:text>
              <xsl:call-template name="indent">
                <xsl:with-param name="level" select="$indent + 1"/>
              </xsl:call-template>
              <xsl:apply-templates select="yaml:value/*">
                <xsl:with-param name="indent" select="$indent + 1"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="yaml:value/*">
                <xsl:with-param name="indent" select="$indent"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Alias template for anchor references -->
  <xsl:template match="yaml:alias">
    <xsl:param name="indent" select="0"/>
    <xsl:text>*</xsl:text>
    <xsl:value-of select="@ref"/>
  </xsl:template>

  <!-- Template for creating indentation -->
  <xsl:template name="indent">
    <xsl:param name="level" select="0"/>
    <xsl:if test="$level > 0">
      <xsl:text>  </xsl:text>
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$level - 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Template for escaping strings -->
  <xsl:template name="escape-string">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="contains($text, '&quot;')">
        <xsl:value-of select="substring-before($text, '&quot;')"/>
        <xsl:text>\"</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="substring-after($text, '&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($text, '\')">
        <xsl:value-of select="substring-before($text, '\')"/>
        <xsl:text>\\</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="substring-after($text, '\')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($text, '&#10;')">
        <xsl:value-of select="substring-before($text, '&#10;')"/>
        <xsl:text>\n</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="substring-after($text, '&#10;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($text, '&#13;')">
        <xsl:value-of select="substring-before($text, '&#13;')"/>
        <xsl:text>\r</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="substring-after($text, '&#13;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($text, '&#9;')">
        <xsl:value-of select="substring-before($text, '&#9;')"/>
        <xsl:text>\t</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="substring-after($text, '&#9;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
