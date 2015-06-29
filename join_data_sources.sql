/*
# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
*/

SELECT
  a.fullVisitorId,
  a.hits.customDimensions.value,
  a.COUNT,
  a.SUM_totals_pageviews,
  a.SUM_totals_hits,
  a.SUM_totals_timeOnSite,
  a.SUM_hits_hitNumber,
  a.diffdays_latest,
  a.diffdays_oldest,
  a.desktop_flag,
  a.tablet_flag,
  a.mobile_flag,
  a.OS_Windows_flag,
  a.OS_Macintosh_flag,
  a.SUM_morning_visit,
  a.SUM_daytime_visit,
  a.SUM_evening_visit,
  a.SUM_midnight_visit,
  a.page201404,
  a.page201405,
  a.page201406,
  b.hits_customDimensions_value,
  b.CV_flag
FROM
  (
  SELECT
    fullVisitorId,
    hits.customDimensions.index,
    hits.customDimensions.value,
    COUNT(hits.customDimensions.value) AS COUNT,

    IF (SUM(INTEGER(totals.pageviews)) is null, 1, SUM(INTEGER(totals.pageviews))) AS SUM_totals_pageviews,

    SUM(totals.hits) AS SUM_totals_hits,
    IF (SUM(INTEGER(totals.timeOnSite)) is null, 1, SUM(INTEGER(totals.timeOnSite))) AS SUM_totals_timeOnSite,
    SUM(hits.hitNumber) AS SUM_hits_hitNumber,
    DATEDIFF(TIMESTAMP('2014-09-10 00:00:00'), MAX(date)) AS diffdays_latest,
    DATEDIFF(TIMESTAMP('2014-09-10 00:00:00'), MIN(date)) AS diffdays_oldest,

    CASE WHEN device.deviceCategory = 'desktop' THEN 1
    ELSE 0 END AS desktop_flag,
    CASE WHEN device.deviceCategory = 'tablet' THEN 1
    ELSE 0 END AS tablet_flag,
    CASE WHEN device.deviceCategory = 'mobile' THEN 1
    ELSE 0 END AS mobile_flag,
    CASE WHEN device.operatingSystem = 'Windows' THEN 1
    ELSE 0 END AS OS_Windows_flag,
    CASE WHEN device.operatingSystem = 'Macintosh' THEN 1
    ELSE 0 END AS OS_Macintosh_flag,

    SUM(CASE WHEN hits.hour IN (5,6,7,8,9,10) THEN 1 ELSE 0 END) AS SUM_morning_visit,
    SUM(CASE WHEN hits.hour IN (11,12,13,14,15,16) THEN 1 ELSE 0 END) AS SUM_daytime_visit,
    SUM(CASE WHEN hits.hour IN (17,18,19,20,21,22) THEN 1 ELSE 0 END) AS SUM_evening_visit,
    SUM(CASE WHEN hits.hour IN (23,24,0,1,2,3,4) THEN 1 ELSE 0 END) AS SUM_midnight_visit,

    SUM(hits.eventInfo.eventLabel='/2014/04/apr-campaign.html') AS page201404,
    SUM(hits.eventInfo.eventLabel='/2014/05/may-campaign.html') AS page201405,
    SUM(hits.eventInfo.eventLabel='/2014/06/jun-campaign.html') AS page201406

  FROM
    TABLE_DATE_RANGE([<PROJECT-NAME>:<DATASET>.ga_sessions_],
    TIMESTAMP(‘<YYYY-MM-DD>'),
    TIMESTAMP('<YYYY-MM-DD>'))

  OMIT RECORD IF EVERY (hits.customDimensions.index != 6)
  GROUP BY
    fullVisitorId,
    hits.customDimensions.value,
    hits.customDimensions.index,
    device.deviceCategory,
    desktop_flag,
    tablet_flag,
    mobile_flag,
    device.operatingSystem,
    OS_Windows_flag,
    OS_Macintosh_flag
  ) a
JOIN
  [<PROJECT-NAME>:<DATASET>.<TABLE>] b
ON
  a.hits.customDimensions.value = b.hits_customDimensions_value
WHERE (
    a.hits.customDimensions.index = 6
AND
    a.hits.customDimensions.value <> 'n/a')

