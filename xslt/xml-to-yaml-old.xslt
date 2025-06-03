<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="UTF-8" indent="no"/>
  <xsl:strip-space elements="*"/>

  <!-- Root template -->
  <xsl:template match="document">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- Scalar template -->
  <xsl:template match="scalar">
    <xsl:param name="indent" select="0"/>
    <xsl:choose>
      <xsl:when test="@type = 'string' and (contains(., ' ') or contains(., ':') or contains(., '#'))">
        <xsl:text>'</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>'</xsl:text>
      </xsl:when>
      <xsl:when test="@type = 'null'">
        <xsl:text>null</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Sequence template -->
  <xsl:template match="sequence">
    <xsl:param name="indent" select="0"/>
    <xsl:choose>
      <xsl:when test="@style = 'flow'">
        <xsl:text>[</xsl:text>
        <xsl:for-each select="item">
          <xsl:if test="position() > 1">, </xsl:if>
          <xsl:apply-templates select="*">
            <xsl:with-param name="indent" select="$indent"/>
          </xsl:apply-templates>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="item">
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
  <xsl:template match="mapping">
    <xsl:param name="indent" select="0"/>
    <xsl:choose>
      <xsl:when test="@style = 'flow'">
        <xsl:text>{</xsl:text>
        <xsl:for-each select="entry">
          <xsl:if test="position() > 1">, </xsl:if>
          <xsl:value-of select="@key"/>
          <xsl:text>: </xsl:text>
          <xsl:apply-templates select="*">
            <xsl:with-param name="indent" select="$indent"/>
          </xsl:apply-templates>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="entry">
          <xsl:if test="position() > 1">
            <xsl:text>&#10;</xsl:text>
            <xsl:call-template name="indent">
              <xsl:with-param name="level" select="$indent"/>
            </xsl:call-template>
          </xsl:if>
          <xsl:value-of select="@key"/>
          <xsl:text>: </xsl:text>
          <xsl:choose>
            <xsl:when test="mapping or sequence">
              <xsl:text>&#10;</xsl:text>
              <xsl:call-template name="indent">
                <xsl:with-param name="level" select="$indent + 1"/>
              </xsl:call-template>
              <xsl:apply-templates select="*">
                <xsl:with-param name="indent" select="$indent + 1"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="*">
                <xsl:with-param name="indent" select="$indent + 1"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Indentation helper template -->
  <xsl:template name="indent">
    <xsl:param name="level" select="0"/>
    <xsl:if test="$level > 0">
      <xsl:text>  </xsl:text>
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$level - 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
