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
hits.customDimensions.value,
(1 / (1+exp(-(-2.3298773233 +
0.0578391477*(COUNT) +
(-0.0004420572)*SUM_totals_timeOnSite) +
0.0389364789*(SUM_hits_hitNumber) +
(-0.1301964399)*(diffdays_latest) +
0.9450177277*(desktop_flag) +
2.9104792404*(tablet_flag) +
1.0340938208*(OS_Windows_flag) +
0.8657633791*(OS_Macintosh_flag) +
0.3425240801*(SUM_morning_visit) +
0.2992608455*(SUM_daytime_visit) +
0.2578073685*(SUM_evening_visit) +
0.3279692978*(page201404) +
1.0019169671*(page201405) +
(-1.3596393104)*(page201406) ))) * 100
AS CV_probability

FROM
(
  SELECT
  hits.customDimensions.value, hits.customDimensions.index,
  COUNT(hits.customDimensions.value) AS COUNT,

  IF (SUM(INTEGER(totals.timeOnSite)) is null, 1, SUM(INTEGER(totals.timeOnSite))) AS SUM_totals_timeOnSite,
  SUM(hits.hitNumber) AS SUM_hits_hitNumber,
  DATEDIFF(TIMESTAMP('2014-09-10 00:00:00'), MAX(date)) AS diffdays_latest,

  CASE WHEN device.deviceCategory = 'desktop' THEN 1
  ELSE 0 END AS desktop_flag,
  CASE WHEN device.deviceCategory = 'tablet' THEN 1
  ELSE 0 END AS tablet_flag,
  CASE WHEN device.operatingSystem = 'Windows' THEN 1
  ELSE 0 END AS OS_Windows_flag,
  CASE WHEN device.operatingSystem = 'Macintosh' THEN 1
  ELSE 0 END AS OS_Macintosh_flag,

  SUM(CASE WHEN hits.hour IN (5,6,7,8,9,10) THEN 1 ELSE 0 END) AS SUM_morning_visit,
  SUM(CASE WHEN hits.hour IN (11,12,13,14,15,16) THEN 1 ELSE 0 END) AS SUM_daytime_visit,
  SUM(CASE WHEN hits.hour IN (17,18,19,20,21,22) THEN 1 ELSE 0 END) AS SUM_evening_visit,

  IF (SUM(hits.eventInfo.eventLabel='/2014/04/apr-campaign.html') is null, 1, SUM(hits.eventInfo.eventLabel='/2014/04/apr-campaign.html')) AS page201404,
  IF (SUM(hits.eventInfo.eventLabel='/2014/05/may-campaign.html') is null, 1, SUM(hits.eventInfo.eventLabel='/2014/05/may-campaign.html')) AS page201405,
  IF (SUM(hits.eventInfo.eventLabel='/2014/06/jun-campaign.html') is null, 1, SUM(hits.eventInfo.eventLabel='/2014/06/jun-campaign.html')) AS page201406

  FROM (TABLE_DATE_RANGE([<INSERT PROJECT>:<INSERT DATASET>.ga_sessions_],
                   TIMESTAMP('2014-07-16'),
                   TIMESTAMP('2014-09-10')))

  OMIT RECORD IF EVERY (hits.customDimensions.index != 6)
  GROUP BY hits.customDimensions.index, hits.customDimensions.value, desktop_flag, tablet_flag, OS_Windows_flag, OS_Macintosh_flag
)
WHERE (
  hits.customDimensions.index = 6 
  AND
  hits.customDimensions.value <> 'n/a')
ORDER BY CV_probability DESC
