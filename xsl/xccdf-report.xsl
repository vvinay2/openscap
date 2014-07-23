<?xml version="1.0" encoding="UTF-8" ?>

<!--
Copyright 2010-2014 Red Hat Inc., Durham, North Carolina.
All Rights Reserved.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

Authors:
     Martin Preisler <mpreisle@redhat.com>
     Lukas Kuklinek <lkuklinek@redhat.com>
-->

<xsl:stylesheet version="1.1"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:cdf="http://checklists.nist.gov/xccdf/1.2"
    xmlns:exsl="http://exslt.org/common"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:s="http://open-scap.org/"
    xmlns:db="http://open-scap.org/"
    exclude-result-prefixes="xsl cdf s exsl"
    xmlns:ovalres="http://oval.mitre.org/XMLSchema/oval-results-5"
    xmlns:sceres="http://open-scap.org/page/SCE_result_file">

<xsl:include href="xccdf-share.xsl" />

<xsl:output
    method="html"
    encoding="utf-8"
    indent="no"
    omit-xml-declaration="yes"/>

<!-- parameters -->
<xsl:param name="result-id"/>
<xsl:param name="with-target-facts"/>
<xsl:param name="show"/>

<!-- OVAL and SCE result parameters -->
<xsl:param name='pwd'/>
<xsl:param name='oval-template'/>
<xsl:param name='sce-template'/>

<xsl:variable name='oval-tmpl'>
  <xsl:choose>
    <xsl:when test='not($oval-template)' />
    <xsl:when test='substring($oval-template, 1, 1) = "/"'><xsl:value-of select='$oval-template'/></xsl:when>
    <xsl:otherwise><xsl:value-of select='concat($pwd, "/", $oval-template)'/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name='sce-tmpl'>
  <xsl:choose>
    <xsl:when test='not($sce-template)' />
    <xsl:when test='substring($sce-template, 1, 1) = "/"'><xsl:value-of select='$sce-template'/></xsl:when>
    <xsl:otherwise><xsl:value-of select='concat($pwd, "/", $sce-template)'/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name='toshow'>
  <xsl:choose>
    <xsl:when test='substring($show, 1, 1) = "="'>,<xsl:value-of select='substring($show, 2)'/>,</xsl:when>
    <xsl:otherwise>,pass,fixed,notchecked,informational,unknown,error,fail,<xsl:value-of select='$show'/>,</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- keys -->
<xsl:key name="items" match="cdf:Group|cdf:Rule|cdf:Value" use="@id"/>
<xsl:key name="profiles" match="cdf:Profile" use="@id"/>

<!-- top-level template -->
<xsl:template match='cdf:Benchmark'>
  <xsl:variable name='end-times'>
    <s:times>
    <xsl:for-each select='cdf:TestResult/@end-time'>
      <xsl:sort order='descending'/>
      <s:t t='{.}'/>
    </xsl:for-each>
    </s:times>
  </xsl:variable>

  <xsl:variable name='last-test-time' select='exsl:node-set($end-times)/s:times/s:t[1]/@t'/>

  <xsl:variable name='final-result-id'>
    <xsl:choose>
      <xsl:when test="$result-id">
        <xsl:value-of select='$result-id'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='cdf:TestResult[@end-time=$last-test-time][last()]/@id'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name='result' select='cdf:TestResult[@id=$final-result-id]'/>

  <xsl:variable name='profile' select='cdf:TestResult[@id=$result-id][1]/cdf:profile/@idref'/>

  <xsl:choose>
    <xsl:when test='count(cdf:TestResult) = 0'>
      <xsl:message terminate='yes'>This benchmark does not contain any test results.</xsl:message>
    </xsl:when>
    <xsl:when test='$result'>
      <xsl:message>TestResult ID: <xsl:value-of select='$final-result-id'/></xsl:message>
      <xsl:message>Profile: <xsl:choose><xsl:when test='$profile'><xsl:value-of select="$profile"/></xsl:when><xsl:otherwise>(Default)</xsl:otherwise></xsl:choose></xsl:message>
      <xsl:apply-templates select='$result'/>
    </xsl:when>
    <xsl:when test='$result-id'>
      <xsl:message terminate='yes'>No such result exists.</xsl:message>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message terminate='yes'>No result ID specified.</xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="characteristics">
    <!-- we can later easily turn this into a param -->
    <xsl:variable name="testresult" select="."/>

    <div id="characteristics"><a name="characteristics"></a>
        <h2>Characteristics</h2>
        <div class="row">
            <div class="col-md-5 well well-lg">
                <p>
                    <xsl:choose>
                        <!-- cdf:identity is optional and will appear at most once -->
                        <xsl:when test="$testresult/cdf:identity">
                            User <strong><xsl:value-of select="$testresult/cdf:identity/text()"/></strong>
                        </xsl:when>
                        <xsl:otherwise>
                            Unknown user
                        </xsl:otherwise>
                    </xsl:choose>
                    started the evaluation
                    <xsl:choose>
                        <xsl:when test="$testresult/@start-time">
                            at <strong><xsl:value-of select="$testresult/@start-time"/></strong>.
                        </xsl:when>
                        <xsl:otherwise>
                            .
                        </xsl:otherwise>
                    </xsl:choose>
                    Evaluation finished at <strong><xsl:value-of select="$testresult/@end-time"/></strong>.
                    The target machine was called <strong><xsl:value-of select="$testresult/cdf:target/text()"/></strong>.
                </p>
                <xsl:if test="$testresult/cdf:benchmark">
                    <p>
                        Benchmark from <strong><xsl:value-of select="$testresult/cdf:benchmark/@href"/></strong>
                        <xsl:if test="$testresult/cdf:benchmark/@id">
                            with ID <strong><xsl:value-of select="$testresult/cdf:benchmark/@id"/></strong>
                        </xsl:if>
                        was used.
                        <xsl:if test="$testresult/cdf:profile">
                            Profile <strong><xsl:value-of select="/cdf:Benchmark/cdf:Profile[@id = $testresult/cdf:profile/@idref]/cdf:title/text()"/></strong> was selected.
                        </xsl:if>
                    </p>
                </xsl:if>
            </div>
            <div class="col-md-3">
                <h4>CPE Platforms</h4>
                <ul class="list-group">
                    <!-- all the applicable platforms first -->
                    <xsl:for-each select="/cdf:Benchmark/cdf:platform">
                        <xsl:variable name="idref" select="@idref"/>
                        <xsl:if test="$testresult/cdf:platform[@idref=$idref]">
                            <li class="list-group-item">
                                <span class="label label-success" title="CPE platform {@idref} was found applicable on the evaluated machine"><xsl:value-of select="@idref"/></span>
                            </li>
                        </xsl:if>
                    </xsl:for-each>
                    <!-- then the rest -->
                    <xsl:for-each select="/cdf:Benchmark/cdf:platform">
                        <xsl:variable name="idref" select="@idref"/>
                        <xsl:if test="not($testresult/cdf:platform[@idref=$idref])">
                            <li class="list-group-item">
                                <span class="label label-default" title="This CPE platform was not applicable on the evaluated machine"><xsl:value-of select="@idref"/></span>
                            </li>
                        </xsl:if>
                    </xsl:for-each>
                </ul>
            </div>
            <div class="col-md-4">
                <h4>Addresses</h4>
                <ul class="list-group">
                    <!-- the second predicate ensures that we don't print duplicates -->
                    <xsl:for-each select="$testresult/cdf:target-address[not(. = preceding::cdf:target-address)]">
                        <li class="list-group-item">
                            <xsl:choose>
                                <xsl:when test="contains(text(), ':')">
                                    <span class="label label-info">IPv6</span>
                                </xsl:when>
                                <xsl:when test="contains(text(), '.')">
                                    <span class="label label-primary">IPv4</span>
                                </xsl:when>
                                <xsl:otherwise>
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- #160 is nbsp -->
                            &#160;<xsl:value-of select="text()"/>
                        </li>
                    </xsl:for-each>
                    <!-- the second predicate ensures that we don't print duplicates -->
                    <xsl:for-each select="$testresult/cdf:target-facts/cdf:fact[@name = 'urn:xccdf:fact:ethernet:MAC'][not(. = preceding::cdf:fact)]">
                        <li class="list-group-item">
                            <span class="label label-default">MAC</span>
                            <!-- #160 is nbsp -->
                            &#160;<xsl:value-of select="text()"/>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </div>
    </div>
</xsl:template>

<xsl:template name="compliance-and-scoring">
    <!-- we can later easily turn this into a param -->
    <xsl:variable name="testresult" select="."/>

    <div id="compliance-and-scoring"><a name="compliance-and-scoring"></a>
        <h2>Compliance and Scoring</h2>
        <xsl:choose>
            <xsl:when test="$testresult/cdf:rule-result/cdf:result[text() = 'fail' or text() = 'error' or text() = 'unknown']">
                <div class="alert alert-warning">
                    <span class="pficon-layered">
                        <span class="pficon pficon-warning-triangle"></span>
                        <span class="pficon pficon-warning-exclamation"></span>
                    </span>
                    <strong>The system is not compliant!</strong> Please review rule results and consider applying remediation.
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="alert alert-success">
                    <span class="pficon pficon-ok"></span>
                    <strong>The system is fully compliant!</strong> No action is necessary.
                </div>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:variable name="total_rules_count" select="count($testresult/cdf:rule-result[cdf:result])"/>
        <xsl:variable name="ignored_rules_count" select="count($testresult/cdf:rule-result[cdf:result/text() = 'notselected' or cdf:result/text() = 'notapplicable'])"/>
        <xsl:variable name="passed_rules_count" select="count($testresult/cdf:rule-result[cdf:result/text() = 'pass' or cdf:result/text() = 'fixed'])"/>
        <xsl:variable name="failed_rules_count" select="count($testresult/cdf:rule-result[cdf:result/text() = 'fail'])"/>

        <div class="progress">
            <div class="progress-bar progress-bar-success" style="width: {$passed_rules_count div ($total_rules_count - $ignored_rules_count) * 100}%">
                <xsl:value-of select="$passed_rules_count"/> passed
            </div>
            <div class="progress-bar progress-bar-danger" style="width: {$failed_rules_count div ($total_rules_count - $ignored_rules_count) * 100}%">
                <xsl:value-of select="$failed_rules_count"/> failed
            </div>
            <div class="progress-bar progress-bar-warning" style="width: {(1 - ($passed_rules_count + $failed_rules_count) div ($total_rules_count - $ignored_rules_count)) * 100}%">
                <xsl:value-of select="$total_rules_count - $ignored_rules_count - $passed_rules_count - $failed_rules_count"/> other
            </div>
        </div>

        <table class="table table-striped table-bordered">
            <thead>
                <tr>
                    <th>Scoring system</th>
                    <th class="text-center">Score</th>
                    <th class="text-center">Maximum</th>
                    <th class="text-center" style="width: 40%">%</th>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="$testresult/cdf:score">
                    <xsl:variable name="percent" select="(text() div @maximum) * 100"/>
                    <tr>
                        <td><xsl:value-of select="@system"/></td>
                        <td class="text-center"><xsl:value-of select="text()"/></td>
                        <td class="text-center"><xsl:value-of select="@maximum"/></td>
                        <td>
                            <div class="progress">
                                <div class="progress-bar progress-bar-success" style="width: {$percent}%"><xsl:value-of select="round($percent * 100) div 100"/>%</div>
                                <div class="progress-bar progress-bar-danger" style="width: {100 - $percent}%"></div>
                            </div>
                        </td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </div>
</xsl:template>

<xsl:template name="rule-overview-leaf">
    <xsl:param name="testresult"/>
    <xsl:param name="item"/>
    <xsl:param name="indent"/>

    <xsl:variable name="ruleresult" select="$testresult/cdf:rule-result[@idref = $item/@id]"/>
    <xsl:variable name="result" select="$ruleresult/cdf:result/text()"/>

    <tr data-tt-id="{$item/@id}" class="rule-overview-leaf rule-overview-leaf-{$result}" id="rule-overview-leaf-{generate-id($ruleresult)}">
        <xsl:attribute name="data-tt-parent-id">
            <xsl:value-of select="$item/parent::cdf:*/@id"/>
        </xsl:attribute>
        <xsl:if test="$result = 'fail' or $result = 'error' or $result = 'unknown'">
            <xsl:attribute name="class">rule-overview-leaf rule-overview-leaf-<xsl:value-of select="$result"/> rule-overview-needs-attention</xsl:attribute>
        </xsl:if>

        <td style="padding-left: {$indent * 19}px"><a href="#result-detail-{generate-id($ruleresult)}" onclick="return openRuleDetailsDialog('{generate-id($ruleresult)}')">
            <xsl:value-of select="$item/cdf:title/text()"/>
        </a></td>
        <td>
            <xsl:if test="$ruleresult/cdf:ident">
                <ul>
                <xsl:for-each select="$ruleresult/cdf:ident">
                    <li><xsl:value-of select="text()"/></li>
                </xsl:for-each>
                </ul>
            </xsl:if>
        </td>
        <td style="text-align: center"><xsl:value-of select="$ruleresult/@severity"/></td>
        <td class="rule-result rule-result-{$result}">
            <div>
                <xsl:value-of select="$result"/>
            </div>
            <!-- TODO: provide tooltips and better differentiation -->
        </td>
    </tr>
</xsl:template>

<xsl:template name="rule-overview-count-results">
    <xsl:param name="testresult"/>
    <xsl:param name="item"/>
    <xsl:param name="result"/>

    <xsl:variable name="count" select="0"/>

    <xsl:for-each select="$item/cdf:Group">
        <xsl:variable name="inner_count">
            <xsl:call-template name="rule-overview-count-results">
                <xsl:with-param name="testresult" select="$testresult"/>
                <xsl:with-param name="item" select="."/>
                <xsl:with-param name="result" select="$result"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="count" select="$count + $inner_count"/>
    </xsl:for-each>

    <xsl:value-of select="$count"/>
</xsl:template>

<xsl:template name="rule-overview-inner-node">
    <xsl:param name="testresult"/>
    <xsl:param name="item"/>
    <xsl:param name="indent"/>

    <xsl:variable name="contained_rules_fail" select="count($item/descendant::cdf:Rule[@id = $testresult/cdf:rule-result[cdf:result/text() = 'fail']/@idref])"/>
    <xsl:variable name="contained_rules_error" select="count($item/descendant::cdf:Rule[@id = $testresult/cdf:rule-result[cdf:result/text() = 'error']/@idref])"/>
    <xsl:variable name="contained_rules_unknown" select="count($item/descendant::cdf:Rule[@id = $testresult/cdf:rule-result[cdf:result/text() = 'unknown']/@idref])"/>
    <xsl:variable name="contained_rules_need_attention" select="$contained_rules_fail + $contained_rules_error + $contained_rules_unknown"/>

    <tr data-tt-id="{$item/@id}">
        <xsl:if test="$item/parent::cdf:Group or $item/parent::cdf:Benchmark">
            <xsl:attribute name="data-tt-parent-id">
                <xsl:value-of select="$item/parent::cdf:*/@id"/>
            </xsl:attribute>
        </xsl:if>

        <td colspan="4" style="padding-left: {$indent * 19}px">
            <xsl:choose>
                <xsl:when test="$contained_rules_need_attention > 0">
                    <strong><xsl:value-of select="$item/cdf:title/text()"/></strong>

                    <xsl:if test="$contained_rules_fail > 0">
                        &#160;<span class="badge"><xsl:value-of select="$contained_rules_fail"/>x fail</span>
                    </xsl:if>
                    <xsl:if test="$contained_rules_error > 0">
                        &#160;<span class="badge"><xsl:value-of select="$contained_rules_error"/>x error</span>
                    </xsl:if>
                    <xsl:if test="$contained_rules_unknown > 0">
                        &#160;<span class="badge"><xsl:value-of select="$contained_rules_unknown"/>x unknown</span>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$item/cdf:title/text()"/>
                    <script>
                        <xsl:comment>
                         // group doesn't contain any rules that need attention, collapse it
                         $(document).ready( function() {
                             $('.treetable').treetable("collapseNode", "<xsl:value-of select="$item/@id"/>");
                         });
                        </xsl:comment>
                    </script>
                </xsl:otherwise>
            </xsl:choose>
        </td>
    </tr>

    <xsl:for-each select="$item/cdf:Group">
        <xsl:call-template name="rule-overview-inner-node">
            <xsl:with-param name="testresult" select="$testresult"/>
            <xsl:with-param name="item" select="."/>
            <xsl:with-param name="indent" select="$indent + 1"/>
        </xsl:call-template>
    </xsl:for-each>

    <xsl:for-each select="$item/cdf:Rule">
        <xsl:call-template name="rule-overview-leaf">
            <xsl:with-param name="testresult" select="$testresult"/>
            <xsl:with-param name="item" select="."/>
            <xsl:with-param name="indent" select="$indent + 1"/>
        </xsl:call-template>
    </xsl:for-each>
</xsl:template>

<xsl:template name="rule-overview">
    <!-- we can later easily turn this into a param -->
    <xsl:variable name="testresult" select="."/>
    <!-- we can later easily turn this into a param -->
    <xsl:variable name="benchmark" select="/cdf:Benchmark"/>

    <div id="rule-overview"><a name="rule-overview"></a>
        <h2>Rule Overview</h2>

        <div class="form-group js-only">
            <div class="row">
                <div title="Filter rules by their XCCDF result">
                    <div class="col-sm-2 toggle-rule-display-success">
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="pass"/>pass</label>
                        </div>
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="fixed"/>fixed</label>
                        </div>
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="informational"/>informational</label>
                        </div>
                    </div>

                    <div class="col-sm-2 toggle-rule-display-danger">
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="fail"/>fail</label>
                        </div>
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="error"/>error</label>
                        </div>
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="unknown"/>unknown</label>
                        </div>
                    </div>

                    <div class="col-sm-2 toggle-rule-display-other">
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="notchecked"/>notchecked</label>
                        </div>
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" value="notselected"/>notselected</label>
                        </div>
                        <div class="checkbox">
                            <label><input class="toggle-rule-display" type="checkbox" onclick="toggleRuleDisplay(this)" checked="checked" value="notapplicable"/>notapplicable</label>
                        </div>
                    </div>
                </div>
                <div class="col-sm-6">
                    <div class="input-group">
                        <input type="text" class="form-control" placeholder="Search through XCCDF rules" id="search-input" oninput="ruleSearch()"/>

                        <div class="input-group-btn">
                            <button class="btn btn-default" onclick="ruleSearch()"><i class="glyphicon glyphicon-search"></i></button>
                        </div>
                    </div>
                    <p id="search-matches"></p>
                </div>
            </div>
        </div>

        <table class="treetable table table-striped table-bordered">
            <thead>
                <tr>
                    <th>Title</th>
                    <th style="width: 120px; text-align: center">Identifiers</th>
                    <th style="width: 120px; text-align: center">Severity</th>
                    <th style="width: 120px; text-align: center">Result</th>
                </tr>
            </thead>
            <tbody>
                <xsl:call-template name="rule-overview-inner-node">
                    <xsl:with-param name="testresult" select="$testresult"/>
                    <xsl:with-param name="item" select="$benchmark"/>
                    <xsl:with-param name="indent" select="0"/>
                </xsl:call-template>
            </tbody>
        </table>
    </div>
</xsl:template>

<xsl:template name="result-details-leaf">
    <xsl:param name="testresult"/>
    <xsl:param name="item"/>

    <xsl:variable name="ruleresult" select="$testresult/cdf:rule-result[@idref = $item/@id]"/>
    <xsl:variable name="result" select="$ruleresult/cdf:result/text()"/>

    <div class="panel panel-default result-detail result-detail-{$result}" id="result-detail-{generate-id($ruleresult)}" title="{$item/cdf:title/text()}">
        <div class="keywords sr-only">
            <xsl:value-of select="$item/cdf:title/text()"/> <xsl:value-of select="$item/@id"/>
            <!-- TODO: identifiers -->
        </div>
        <div class="panel-heading">
            <a name="result-detail-{generate-id($ruleresult)}"></a>
            <h3 class="panel-title"><xsl:value-of select="$item/cdf:title/text()"/></h3>
        </div>
        <div class="panel-body">
            <table class="table table-striped table-bordered">
                <tbody>
                    <tr><td>Result</td><td><xsl:value-of select="$result"/></td></tr>
                    <tr><td>Rule ID</td><td><xsl:value-of select="$item/@id"/></td></tr>
                    <tr><td>Time</td><td><xsl:value-of select="$ruleresult/@time"/></td></tr>
                    <tr><td>Severity</td><td><xsl:value-of select="$ruleresult/@severity"/></td></tr>
                    <tr><td colspan="2" class="description">
                        <p>
                            <xsl:copy-of select="$item/cdf:description/node()"/>
                        </p>
                    </td></tr>
                    <xsl:if test="$item/cdf:fix">
                        <tr><td colspan="2" class="remediation">
                            Remediation script:
                            <pre>
                                <xsl:copy-of select="$item/cdf:fix/node()"/>
                            </pre>
                        </td></tr>
                    </xsl:if>
                </tbody>
            </table>
        </div>
    </div>
</xsl:template>

<xsl:template name="result-details-inner-node">
    <xsl:param name="testresult"/>
    <xsl:param name="item"/>

    <xsl:for-each select="$item/cdf:Group">
        <xsl:call-template name="result-details-inner-node">
            <xsl:with-param name="testresult" select="$testresult"/>
            <xsl:with-param name="item" select="."/>
        </xsl:call-template>
    </xsl:for-each>

    <xsl:for-each select="$item/cdf:Rule">
        <xsl:call-template name="result-details-leaf">
            <xsl:with-param name="testresult" select="$testresult"/>
            <xsl:with-param name="item" select="."/>
        </xsl:call-template>
    </xsl:for-each>
</xsl:template>

<xsl:template name="result-details">
    <!-- we can later easily turn this into a param -->
    <xsl:variable name="testresult" select="."/>
    <!-- we can later easily turn this into a param -->
    <xsl:variable name="benchmark" select="/cdf:Benchmark"/>

    <div class="js-only">
        <button type="button" class="btn btn-info" onclick="return toggleResultDetails(this)">Show all result details</button>
    </div>
    <div id="result-details"><a name="result-details"></a>
        <h2>Result Details</h2>

        <xsl:call-template name="result-details-inner-node">
            <xsl:with-param name="testresult" select="$testresult"/>
            <xsl:with-param name="item" select="$benchmark"/>
        </xsl:call-template>
    </div>
</xsl:template>

<xsl:template match='cdf:TestResult'>
<xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
<html lang="en">
<head>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <title><xsl:value-of select="@id"/> | OpenSCAP Evaluation Report</title>

    <link href="css/jquery.treetable.css" rel="stylesheet"/>
    <link href="css/jquery.treetable.theme.patternfly.css" rel="stylesheet"/>
    <!-- Bootstrap -->
    <link href="css/bootstrap.min.css" rel="stylesheet"/>

    <style>
        tr.rule-overview-needs-attention td a { color: #c90813 }

        td.rule-result div { text-align: center; font-weight: bold; color: #fff; background: #808080 }
        td.rule-result-fail div { background: #c90813 }
        td.rule-result-error div { background: #c90813 }
        td.rule-result-unknown div { background: #eb7720 }
        td.rule-result-pass div { background: #5cb75c }
        td.rule-result-fixed div { background: #5cb75c }

        .js-only { display: none }

        .rule-result-filtered, .rule-result-filtered > * { display: none !important }
        .search-no-match, .search-no-match > * { display: none !important }

        #footer { text-align: center; margin-top: 50px }
    </style>

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
          <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
          <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="js/jquery.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/jquery.treetable.js"></script>
    <script src="js/bootstrap.js"></script>
    <script>
        <xsl:comment>
            function openRuleDetailsDialog(rule_result_id)
            {
                $("#result-detail-modal").remove();

                //<![CDATA[
                var closebutton = $('<button type="button" class="close" data-dismiss="modal" aria-hidden="true" title="Close">×</button>');
                var modal = $('<div id="result-detail-modal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true"><div id="result-detail-modal-body" class="modal-body"></div></div>');//]]>

                $("body").prepend(modal);

                var resultclone = $("#result-detail-" + rule_result_id).clone();
                resultclone.attr("id", "");
                resultclone.children(".panel-heading").append(closebutton);
                closebutton.css( { marginTop: '-=17px' } );
                $("#result-detail-modal-body").append(resultclone);

                $("#result-detail-modal").modal();

                return false;
            }

            function toggleRuleDisplay(checkbox)
            {
                var result = checkbox.value;

                if (checkbox.checked)
                {
                    $(".rule-overview-leaf-" + result).removeClass("rule-result-filtered");
                    $(".result-detail-" + result).removeClass("rule-result-filtered");
                }
                else
                {
                    $(".rule-overview-leaf-" + result).addClass("rule-result-filtered");
                    $(".result-detail-" + result).addClass("rule-result-filtered");
                }
            }

            function toggleResultDetails(button)
            {
                var result_details = $("#result-details");

                if (result_details.is(":visible"))
                {
                    result_details.hide();
                    $(button).html("Show all result details");
                }
                else
                {
                    result_details.show();
                    $(button).html("Hide all result details");
                }

                return false;
            }

            function ruleSearchMatches(detail_leaf, keywords)
            {
                //<![CDATA[
                if (keywords.length == 0)
                    return true;

                var match = true;
                var checked_keywords = detail_leaf.children(".keywords").text().toLowerCase();

                var index;
                for (index = 0; index < keywords.length; ++index)
                {
                    if (checked_keywords.indexOf(keywords[index].toLowerCase()) < 0)
                    {
                        match = false;
                        break;
                    }
                }

                return match;
                //]]>
            }

            function ruleSearch()
            {
                var search_input = $("#search-input").val();
                var keywords = search_input.split(/[\s,\.;]+/);
                var matches = 0;

                $(".result-detail").each(function(){
                    // result-result-rrid, that's offset 14
                    var rrid = $(this).attr("id").substring(14);

                    var overview_leaf = $("#rule-overview-leaf-" + rrid);
                    var detail_leaf = $(this);

                    if (ruleSearchMatches(detail_leaf, keywords))
                    {
                        overview_leaf.removeClass("search-no-match");
                        detail_leaf.removeClass("search-no-match");
                        ++matches;
                    }
                    else
                    {
                        overview_leaf.addClass("search-no-match");
                        detail_leaf.addClass("search-no-match");
                    }
                });

                if (!search_input)
                    $("#search-matches").html("");
                else if (matches > 0)
                    $("#search-matches").html(matches.toString() + " rules match.");
                else
                    $("#search-matches").html("No rules match your search criteria!");
            }

            $(document).ready( function() {
                $("#result-details").hide();
                $(".js-only").show();
                $(".toggle-rule-display").each(function(){
                    toggleRuleDisplay(this);
                });

                $(".treetable").treetable({ column: 0, expandable: true, initialState : "expanded",  clickableNodeNames : true, indent : 0 });
            });
        </xsl:comment>
    </script>
</head>

<body>
<nav class="navbar navbar-default" role="navigation">
    <div class="navbar-header">
        <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse-3">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
        </button>
        <a class="navbar-brand" href="#"><img src="img/brand.svg" alt="OpenSCAP" /></a>
        <div style="padding-left: 270px !important"><h1>Evaluation Report</h1></div>
    </div>
    <div class="collapse navbar-collapse navbar-collapse-3">
        <ul class="nav navbar-nav">
            <li>
                <a href="#characteristics">Characteristics</a>
            </li>
            <li>
                <a href="#compliance-and-scoring">Compliance and Scoring</a>
            </li>
            <li>
                <a href="#rule-overview">Rule Overview</a>
            </li>
            <li>
                <a href="#result-details">Result Details</a>
            </li>
        </ul>
    </div>
</nav>

<div class="container"><div id="content">
    <xsl:call-template name="characteristics"/>
    <xsl:call-template name="compliance-and-scoring"/>
    <xsl:call-template name="rule-overview"/>
    <xsl:call-template name="result-details"/>

</div></div>

<footer id="footer">
    <div class="container">
        <p class="muted credit">
            <p>Generated using <a href="http://open-scap.org">OpenSCAP 1.1.0</a></p>
        </p>
    </div>
</footer>

</body>
</html>

</xsl:template>

</xsl:stylesheet>
