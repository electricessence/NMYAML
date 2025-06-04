<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:yaml="http://yaml.org/xml/1.2">

  <xsl:output method="text" encoding="UTF-8" indent="no"/>
  <xsl:strip-space elements="*"/>

  <!-- Root template - handles both namespaced and non-namespaced -->
  <xsl:template match="document | yaml:document">
    <xsl:apply-templates select="*[local-name()='scalar' or local-name()='sequence' or local-name()='mapping']"/>
  </xsl:template>

  <!-- Scalar template - handles both namespaced and non-namespaced -->
  <xsl:template match="scalar | yaml:scalar">
    <xsl:param name="indent" select="0"/>
    
    <!-- Add anchor if present -->
    <xsl:if test="@anchor">
      <xsl:text>&amp;</xsl:text>
      <xsl:value-of select="@anchor"/>
      <xsl:text> </xsl:text>
    </xsl:if>
    
    <xsl:choose>
      <!-- Check if string needs quoting -->
      <xsl:when test="@type = 'string' and (contains(., ' ') or contains(., ':') or contains(., '#'))">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="."/>
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
          <xsl:when test=". = 'true' or . = 'True' or . = 'TRUE'">
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
  </xsl:template>
  <!-- Sequence template - handles both namespaced and non-namespaced -->
  <xsl:template match="sequence | yaml:sequence">
    <xsl:param name="indent" select="0"/>
    
    <xsl:choose>
      <xsl:when test="count(*[local-name()='item']) = 0">
        <!-- Add anchor if present for empty sequence -->
        <xsl:if test="@anchor">
          <xsl:text>&amp;</xsl:text>
          <xsl:value-of select="@anchor"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:text>[]</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <!-- Add anchor if present before the first item -->
        <xsl:if test="@anchor">
          <xsl:text>&amp;</xsl:text>
          <xsl:value-of select="@anchor"/>
          <xsl:text>&#10;</xsl:text>
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent"/>
          </xsl:call-template>
        </xsl:if>
        
        <xsl:for-each select="*[local-name()='item']">
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
  <!-- Mapping template - handles both namespaced and non-namespaced -->
  <xsl:template match="mapping | yaml:mapping">
    <xsl:param name="indent" select="0"/>
    
    <xsl:choose>
      <xsl:when test="count(*[local-name()='entry']) = 0">
        <!-- Add anchor if present for empty mapping -->
        <xsl:if test="@anchor">
          <xsl:text>&amp;</xsl:text>
          <xsl:value-of select="@anchor"/>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:text>{}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <!-- Add anchor if present before the first entry -->
        <xsl:if test="@anchor">
          <xsl:text>&amp;</xsl:text>
          <xsl:value-of select="@anchor"/>
          <xsl:text>&#10;</xsl:text>
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent"/>
          </xsl:call-template>
        </xsl:if>
        
        <xsl:for-each select="*[local-name()='entry']">
          <xsl:if test="position() > 1">
            <xsl:text>&#10;</xsl:text>
            <xsl:call-template name="indent">
              <xsl:with-param name="level" select="$indent"/>
            </xsl:call-template>
          </xsl:if>
          
          <!-- Handle simple attribute-based key (for backward compatibility) -->
          <xsl:choose>
            <xsl:when test="@key">
              <xsl:value-of select="@key"/>
              <xsl:text>: </xsl:text>
              <xsl:choose>
                <xsl:when test="*[local-name()='mapping' or local-name()='sequence']">
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
                    <xsl:with-param name="indent" select="$indent"/>
                  </xsl:apply-templates>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            
            <!-- Handle complex key-value structure -->
            <xsl:when test="*[local-name()='key']">
              <xsl:apply-templates select="*[local-name()='key']/*">
                <xsl:with-param name="indent" select="$indent"/>
              </xsl:apply-templates>
              <xsl:text>: </xsl:text>
              <xsl:choose>
                <xsl:when test="*[local-name()='value']/*[local-name()='mapping' or local-name()='sequence']">
                  <xsl:text>&#10;</xsl:text>
                  <xsl:call-template name="indent">
                    <xsl:with-param name="level" select="$indent + 1"/>
                  </xsl:call-template>
                  <xsl:apply-templates select="*[local-name()='value']/*">
                    <xsl:with-param name="indent" select="$indent + 1"/>
                  </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="*[local-name()='value']/*">
                    <xsl:with-param name="indent" select="$indent"/>
                  </xsl:apply-templates>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Alias template for anchor references -->
  <xsl:template match="alias | yaml:alias">
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

</xsl:stylesheet>
