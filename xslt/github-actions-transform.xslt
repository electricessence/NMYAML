<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:gh="http://github.com/actions/1.0">

  <xsl:output method="text" encoding="UTF-8" indent="no" />
  <xsl:strip-space elements="*" />

  <!-- Root workflow template -->
  <xsl:template match="gh:workflow">    <!-- Workflow name -->
    <xsl:if test="gh:name">
      <xsl:text>name: </xsl:text>
      <xsl:call-template name="quote-if-needed">
        <xsl:with-param name="text" select="gh:name" />
      </xsl:call-template>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>

    <!-- Run name -->
    <xsl:if test="gh:run-name">
      <xsl:text>run-name: </xsl:text>
      <xsl:call-template name="quote-if-needed">
        <xsl:with-param name="text" select="gh:run-name" />
      </xsl:call-template>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>

    <!-- Triggers -->
    <xsl:if test="gh:on and gh:on/*">
      <xsl:text>on:&#10;</xsl:text>
      <xsl:apply-templates select="gh:on">
        <xsl:with-param name="indent" select="1" />
      </xsl:apply-templates>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Global environment variables -->
    <xsl:if test="gh:env and gh:env/*">
      <xsl:text>env:&#10;</xsl:text>
      <xsl:apply-templates select="gh:env">
        <xsl:with-param name="indent" select="1" />
      </xsl:apply-templates>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>    <!-- Global defaults -->
    <xsl:if test="gh:defaults and gh:defaults/*">
      <xsl:text>defaults:&#10;</xsl:text>
      <xsl:apply-templates select="gh:defaults">
        <xsl:with-param name="indent" select="1" />
      </xsl:apply-templates>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Concurrency -->
    <xsl:if test="gh:concurrency and gh:concurrency/*">
      <xsl:text>concurrency:&#10;</xsl:text>
      <xsl:apply-templates select="gh:concurrency">
        <xsl:with-param name="indent" select="1" />
      </xsl:apply-templates>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Permissions -->
    <xsl:if test="gh:permissions and gh:permissions/*">
      <xsl:text>permissions:&#10;</xsl:text>
      <xsl:apply-templates select="gh:permissions">
        <xsl:with-param name="indent" select="1" />
      </xsl:apply-templates>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Jobs -->
    <xsl:text>jobs:&#10;</xsl:text>
    <xsl:apply-templates select="gh:jobs">
      <xsl:with-param name="indent" select="1" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- Triggers template -->
  <xsl:template match="gh:on">
    <xsl:param name="indent" select="0" />

    <!-- Push trigger -->
    <xsl:if test="gh:push">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>push:</xsl:text>
      <xsl:choose>
        <xsl:when test="gh:push/*">
          <xsl:text>&#10;</xsl:text>
          <xsl:apply-templates select="gh:push">
            <xsl:with-param name="indent" select="$indent + 1" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> true&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- Pull request trigger -->
    <xsl:if test="gh:pull_request">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>pull_request:</xsl:text>
      <xsl:choose>
        <xsl:when test="gh:pull_request/*">
          <xsl:text>&#10;</xsl:text>
          <xsl:apply-templates select="gh:pull_request">
            <xsl:with-param name="indent" select="$indent + 1" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> true&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- Schedule trigger -->
    <xsl:if test="gh:schedule">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>schedule:&#10;</xsl:text>
      <xsl:apply-templates select="gh:schedule">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>

    <!-- Workflow dispatch -->
    <xsl:if test="gh:workflow_dispatch">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>workflow_dispatch:</xsl:text>
      <xsl:choose>
        <xsl:when test="gh:workflow_dispatch/*">
          <xsl:text>&#10;</xsl:text>
          <xsl:apply-templates select="gh:workflow_dispatch">
            <xsl:with-param name="indent" select="$indent + 1" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> true&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- Other simple triggers -->
    <xsl:if test="gh:issues">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>issues: true&#10;</xsl:text>
    </xsl:if>

    <xsl:if test="gh:release">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>release: true&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Push/Pull Request trigger details -->
  <xsl:template match="gh:push | gh:pull_request | gh:pull_request_target">
    <xsl:param name="indent" select="0" />

    <xsl:if test="gh:branches">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>branches:&#10;</xsl:text>
      <xsl:apply-templates select="gh:branches">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="gh:paths">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>paths:&#10;</xsl:text>
      <xsl:apply-templates select="gh:paths">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="gh:types">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>types:&#10;</xsl:text>
      <xsl:apply-templates select="gh:types">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <!-- Schedule template -->
  <xsl:template match="gh:schedule">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="gh:cron">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>- cron: '</xsl:text>
      <xsl:value-of select="@schedule" disable-output-escaping="yes" />
      <xsl:text>'&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Workflow dispatch inputs -->
  <xsl:template match="gh:workflow_dispatch">
    <xsl:param name="indent" select="0" />
    <xsl:if test="gh:inputs">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>inputs:&#10;</xsl:text>
      <xsl:for-each select="gh:inputs/gh:input">
        <xsl:call-template name="indent">
          <xsl:with-param name="level" select="$indent + 1" />
        </xsl:call-template>
        <xsl:value-of select="@name" />
        <xsl:text>:&#10;</xsl:text>

        <xsl:if test="gh:description">
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent + 2" />
          </xsl:call-template>
          <xsl:text>description: '</xsl:text>
          <xsl:value-of select="gh:description" />
          <xsl:text>'&#10;</xsl:text>
        </xsl:if>

        <xsl:if test="gh:required">
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent + 2" />
          </xsl:call-template>
          <xsl:text>required: </xsl:text>
          <xsl:value-of select="gh:required" />
          <xsl:text>&#10;</xsl:text>
        </xsl:if>

        <xsl:if test="gh:type">
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent + 2" />
          </xsl:call-template>
          <xsl:text>type: </xsl:text>
          <xsl:value-of select="gh:type" />
          <xsl:text>&#10;</xsl:text>
        </xsl:if>

        <xsl:if test="gh:default">
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent + 2" />
          </xsl:call-template>
          <xsl:text>default: </xsl:text>
          <xsl:value-of select="gh:default" />
          <xsl:text>&#10;</xsl:text>
        </xsl:if>

        <xsl:if test="gh:options">
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent + 2" />
          </xsl:call-template>
          <xsl:text>options:&#10;</xsl:text>
          <xsl:for-each select="gh:options/gh:item">
            <xsl:call-template name="indent">
              <xsl:with-param name="level" select="$indent + 3" />
            </xsl:call-template>
            <xsl:text>- </xsl:text>
            <xsl:value-of select="." />
            <xsl:text>&#10;</xsl:text>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <!-- Environment variables -->
  <xsl:template match="gh:env">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="gh:var">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:value-of select="@name" />
      <xsl:text>: </xsl:text>
      <xsl:call-template name="quote-if-needed">
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Defaults -->
  <xsl:template match="gh:defaults">
    <xsl:param name="indent" select="0" />
    <xsl:if test="gh:run">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>run:&#10;</xsl:text>
      <xsl:if test="gh:run/gh:shell">
        <xsl:call-template name="indent">
          <xsl:with-param name="level" select="$indent + 1" />
        </xsl:call-template>
        <xsl:text>shell: </xsl:text>
        <xsl:value-of select="gh:run/gh:shell" />
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
      <xsl:if test="gh:run/gh:working-directory">
        <xsl:call-template name="indent">
          <xsl:with-param name="level" select="$indent + 1" />
        </xsl:call-template>
        <xsl:text>working-directory: </xsl:text>
        <xsl:value-of select="gh:run/gh:working-directory" />
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Concurrency -->
  <xsl:template match="gh:concurrency">
    <xsl:param name="indent" select="0" />
    <xsl:call-template name="indent">
      <xsl:with-param name="level" select="$indent" />
    </xsl:call-template>
    <xsl:text>group: </xsl:text>
    <xsl:call-template name="quote-if-needed">
      <xsl:with-param name="text" select="gh:group" />
    </xsl:call-template>
    <xsl:text>&#10;</xsl:text>
    <xsl:if test="gh:cancel-in-progress">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>cancel-in-progress: </xsl:text>
      <xsl:value-of select="gh:cancel-in-progress" />
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Permissions -->
  <xsl:template match="gh:permissions">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="*">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:value-of select="local-name()" />
      <xsl:text>: </xsl:text>
      <xsl:value-of select="." />
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Jobs collection -->
  <xsl:template match="gh:jobs">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="gh:job">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:value-of select="@id" />
      <xsl:text>:&#10;</xsl:text>
      <xsl:apply-templates select=".">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
      <xsl:if test="position() != last()">
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Individual job -->
  <xsl:template match="gh:job">
    <xsl:param name="indent" select="0" />

    <!-- Job name -->
    <xsl:if test="gh:name">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>name: </xsl:text>
      <xsl:call-template name="quote-if-needed">
        <xsl:with-param name="text" select="gh:name" />
      </xsl:call-template>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Runs-on -->
    <xsl:call-template name="indent">
      <xsl:with-param name="level" select="$indent" />
    </xsl:call-template>
    <xsl:text>runs-on: </xsl:text>
    <xsl:choose>
      <xsl:when test="gh:runs-on/gh:runner">
        <xsl:value-of select="gh:runs-on/gh:runner" />
      </xsl:when>
      <xsl:when test="gh:runs-on/gh:matrix">
        <xsl:text>&#10;</xsl:text>
        <xsl:apply-templates select="gh:runs-on/gh:matrix">
          <xsl:with-param name="indent" select="$indent + 1" />
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>

    <!-- Needs -->
    <xsl:if test="gh:needs">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>needs:</xsl:text>
      <xsl:choose>
        <xsl:when test="count(gh:needs/gh:item) = 1">
          <xsl:text> </xsl:text>
          <xsl:value-of select="gh:needs/gh:item" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&#10;</xsl:text>
          <xsl:apply-templates select="gh:needs">
            <xsl:with-param name="indent" select="$indent + 1" />
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- If condition -->
    <xsl:if test="gh:if">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>if: </xsl:text>
      <xsl:choose>
        <xsl:when test="contains(gh:if, '&#10;') or contains(gh:if, '|')">
          <xsl:text>|&#10;</xsl:text>
          <xsl:call-template name="multiline-text">
            <xsl:with-param name="text" select="gh:if" />
            <xsl:with-param name="indent" select="$indent + 1" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="quote-if-needed">
            <xsl:with-param name="text" select="gh:if" />
          </xsl:call-template>
          <xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- Strategy -->
    <xsl:if test="gh:strategy">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>strategy:&#10;</xsl:text>
      <xsl:apply-templates select="gh:strategy">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>

    <!-- Environment -->
    <xsl:if test="gh:env">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>env:&#10;</xsl:text>
      <xsl:apply-templates select="gh:env">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>

    <!-- Steps -->
    <xsl:if test="gh:steps">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>steps:&#10;</xsl:text>
      <xsl:apply-templates select="gh:steps">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <!-- Strategy -->
  <xsl:template match="gh:strategy">
    <xsl:param name="indent" select="0" />
    <xsl:if test="gh:matrix">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>matrix:&#10;</xsl:text>
      <xsl:apply-templates select="gh:matrix">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="gh:fail-fast">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>fail-fast: </xsl:text>
      <xsl:value-of select="gh:fail-fast" />
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Matrix -->
  <xsl:template match="gh:matrix">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="*[not(local-name()='include' or local-name()='exclude')]">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:value-of select="local-name()" />
      <xsl:text>:</xsl:text>
      <xsl:choose>
        <xsl:when test="gh:item">
          <xsl:text>&#10;</xsl:text>
          <xsl:for-each select="gh:item">
            <xsl:call-template name="indent">
              <xsl:with-param name="level" select="$indent + 1" />
            </xsl:call-template>
            <xsl:text>- </xsl:text>
            <xsl:call-template name="quote-if-needed">
              <xsl:with-param name="text" select="." />
            </xsl:call-template>
            <xsl:text>&#10;</xsl:text>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> </xsl:text>
          <xsl:call-template name="quote-if-needed">
            <xsl:with-param name="text" select="." />
          </xsl:call-template>
          <xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- Steps collection -->
  <xsl:template match="gh:steps">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="gh:step">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>- </xsl:text>
      <xsl:apply-templates select=".">
        <xsl:with-param name="indent" select="$indent + 1" />
        <xsl:with-param name="is-list-item" select="true()" />
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>

  <!-- Individual step -->
  <xsl:template match="gh:step">
    <xsl:param name="indent" select="0" />
    <xsl:param name="is-list-item" select="false()" />

    <xsl:variable name="first-item" select="true()" />

    <!-- Step name -->
    <xsl:if test="gh:name">
      <xsl:if test="not($is-list-item) or not($first-item)">
        <xsl:call-template name="indent">
          <xsl:with-param name="level" select="$indent" />
        </xsl:call-template>
      </xsl:if>
      <xsl:text>name: </xsl:text>
      <xsl:call-template name="quote-if-needed">
        <xsl:with-param name="text" select="gh:name" />
      </xsl:call-template>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Uses -->
    <xsl:if test="gh:uses">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>uses: </xsl:text>
      <xsl:value-of select="gh:uses" disable-output-escaping="yes" />
      <xsl:text>&#10;</xsl:text>
    </xsl:if>

    <!-- Run -->
    <xsl:if test="gh:run">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>run: </xsl:text>
      <xsl:choose>
        <xsl:when test="contains(gh:run, '&#10;') or contains(gh:run, '|')">
          <xsl:text>|&#10;</xsl:text>
          <xsl:call-template name="multiline-text">
            <xsl:with-param name="text" select="gh:run" />
            <xsl:with-param name="indent" select="$indent + 1" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="quote-if-needed">
            <xsl:with-param name="text" select="gh:run" />
          </xsl:call-template>
          <xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- With parameters -->
    <xsl:if test="gh:with">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>with:&#10;</xsl:text>
      <xsl:apply-templates select="gh:with">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>

    <!-- Environment -->
    <xsl:if test="gh:env">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>env:&#10;</xsl:text>
      <xsl:apply-templates select="gh:env">
        <xsl:with-param name="indent" select="$indent + 1" />
      </xsl:apply-templates>
    </xsl:if>    <!-- If condition -->
    <xsl:if test="gh:if">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>if: </xsl:text>
      <xsl:choose>
        <xsl:when test="contains(gh:if, '&#10;') or contains(gh:if, '|')">
          <xsl:text>|&#10;</xsl:text>
          <xsl:call-template name="multiline-text">
            <xsl:with-param name="text" select="gh:if" />
            <xsl:with-param name="indent" select="$indent + 1" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="quote-if-needed">
            <xsl:with-param name="text" select="gh:if" />
          </xsl:call-template>
          <xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- With parameters -->
  <xsl:template match="gh:with">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="gh:param">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:value-of select="@name" />
      <xsl:text>: </xsl:text>
      <xsl:call-template name="quote-if-needed">
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- String lists (branches, paths, etc.) -->
  <xsl:template match="gh:branches | gh:paths | gh:types | gh:needs">
    <xsl:param name="indent" select="0" />
    <xsl:for-each select="gh:item">
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$indent" />
      </xsl:call-template>
      <xsl:text>- </xsl:text>
      <xsl:call-template name="quote-if-needed">
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Utility templates -->
  <xsl:template name="indent">
    <xsl:param name="level" select="0" />
    <xsl:if test="$level > 0">
      <xsl:text>  </xsl:text>
      <xsl:call-template name="indent">
        <xsl:with-param name="level" select="$level - 1" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="quote-if-needed">
    <xsl:param name="text" />
    <xsl:choose>
      <xsl:when
        test="contains($text, ' ') or contains($text, ':') or contains($text, '#') or contains($text, &quot;'&quot;) or contains($text, '&quot;') or starts-with($text, '-') or starts-with($text, '[') or starts-with($text, '{') or starts-with($text, '$') or starts-with($text, '*')">
        <xsl:text>"</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="$text" />
        </xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" disable-output-escaping="yes" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="escape-string">
    <xsl:param name="text" />
    <xsl:choose>
      <xsl:when test="contains($text, '&quot;')">
        <xsl:value-of select="substring-before($text, '&quot;')" disable-output-escaping="yes" />
        <xsl:text>\"</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="substring-after($text, '&quot;')" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($text, '\')">
        <xsl:value-of select="substring-before($text, '\')" disable-output-escaping="yes" />
        <xsl:text>\\</xsl:text>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="text" select="substring-after($text, '\')" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" disable-output-escaping="yes" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="multiline-text">
    <xsl:param name="text" />
    <xsl:param name="indent" select="0" />

    <!-- Remove leading | and whitespace if present -->
    <xsl:variable name="cleanText">
      <xsl:choose>
        <xsl:when test="starts-with(normalize-space($text), '|')">
          <xsl:value-of select="substring-after($text, '|')" disable-output-escaping="yes" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text" disable-output-escaping="yes" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Process each line -->
    <xsl:choose>
      <xsl:when test="contains($cleanText, '&#10;')">
        <xsl:variable name="firstLine"
          select="normalize-space(substring-before($cleanText, '&#10;'))" />
        <xsl:if test="$firstLine != ''">
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent" />
          </xsl:call-template>
          <xsl:value-of select="$firstLine" disable-output-escaping="yes" />
          <xsl:text>&#10;</xsl:text>
        </xsl:if>
        <xsl:call-template name="multiline-text">
          <xsl:with-param name="text" select="substring-after($cleanText, '&#10;')" />
          <xsl:with-param name="indent" select="$indent" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="lastLine" select="normalize-space($cleanText)" />
        <xsl:if test="$lastLine != ''">
          <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$indent" />
          </xsl:call-template>
          <xsl:value-of select="$lastLine" disable-output-escaping="yes" />
          <xsl:text>&#10;</xsl:text>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>