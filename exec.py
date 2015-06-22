#!/usr/bin/env python
# -*- coding: utf-8 -*-

import httplib2
import pprint
import sys
import pandas as pd
import numpy as np
import pyper as pr

from apiclient.discovery import build
from apiclient.errors import HttpError
from oauth2client.client import OAuth2WebServerFlow
from oauth2client.client import AccessTokenRefreshError
from oauth2client.client import flow_from_clientsecrets
from oauth2client.file import Storage

PROJECT_NUMBER = '501314667068'

#connect to big query
FLOW = flow_from_clientsecrets('/home/dmp_user/dmp_sample/auth/client_secrets.json', 
        scope='https://www.googleapis.com/auth/bigquery')
storage = Storage('/home/dmp_user/dmp_sample/auth/bigquery_credentials.dat')

credentials = storage.get()
http = httplib2.Http()
http = credentials.authorize(http)
service = build('bigquery', 'v2')
jobs = service.jobs()

#run query
sql = "  SELECT  "
sql += "  cv1.fullVisitorId AS fullVisitorId,  "
sql += "  cv1.COUNT_fullVisitorId AS COUNT_fullVisitorId,  "
sql += "  cv1.AVG_hits_hour AS AVG_hits_hour,  "
sql += "  cv1.SUM_totals_pageviews AS SUM_totals_pageviews,  "
sql += "  cv1.SUM_totals_hits AS SUM_totals_hits,  "
sql += "  cv1.SUM_totals_timeOnSite AS SUM_totals_timeOnSite,  "
sql += "  cv1.SUM_hits_hitNumber AS SUM_hits_hitNumber,  "
sql += "  cv1.diffdays AS diffdays,  "
sql += "  cv1.OS_Windows AS OS_Windows,  "
sql += "  cv1.OS_Macintosh AS OS_Macintosh,  "
sql += "  ID_matching_list.CV_flag AS CV_flag  "
sql += "  FROM(  "
sql += "  SELECT  "
sql += "  fullVisitorId,  "
sql += "  COUNT(fullVisitorId) AS COUNT_fullVisitorId,  "
sql += "  AVG(hits.hour) AS AVG_hits_hour,  "
sql += "  IF (SUM(INTEGER(totals.pageviews)) is null, 1, SUM(INTEGER(totals.pageviews))) AS SUM_totals_pageviews,  "
sql += "  SUM(totals.hits) AS SUM_totals_hits,   "
sql += "  IF (SUM(INTEGER(totals.timeOnSite)) is null, 1, SUM(INTEGER(totals.timeOnSite))) AS SUM_totals_timeOnSite,  "
sql += "  SUM(hits.hitNumber) AS SUM_hits_hitNumber,  "
sql += "  MAX(date) AS MAX_date,  "
sql += "  DATEDIFF(TIMESTAMP('2014-09-10 00:00:00'), MAX(date)) AS diffdays,  "
sql += "  device.operatingSystem,  "
sql += "  CASE WHEN device.operatingSystem = 'Windows' THEN 1  "
sql += "      ELSE 0 END AS OS_Windows,  "
sql += "  CASE WHEN device.operatingSystem = 'Macintosh' THEN 1  "
sql += "      ELSE 0 END AS OS_Macintosh,  "
sql += "  hits.customDimensions.value  "
sql += "  FROM  "
sql += "  (TABLE_DATE_RANGE([gcp-samples:gcp_samples.ga_sessions_],  "
sql += "                    TIMESTAMP('2014-07-16'),  "
sql += "                    TIMESTAMP('2014-09-10')))   "
sql += "  WHERE  "
sql += "  hits.customDimensions.index = 6  "
sql += "  AND hits.customDimensions.value <> 'n/a'   "
sql += "  GROUP BY fullVisitorId,hits.customDimensions.value,device.operatingSystem,OS_Windows,OS_Macintosh  "
sql += "  ) AS cv1  "
sql += "  JOIN  "
sql += "  [gcp-samples:gcp_samples.ID_matching_list] AS ID_matching_list  "
sql += "  ON  "
sql += "  cv1.hits.customDimensions.value = ID_matching_list.hits_customDimensions_value  "
sql += "  ORDER BY cv1.fullVisitorId;  "

query = {'query': sql}
result = jobs.query(projectId=PROJECT_NUMBER, body=query).execute(http)


#data frame stored in the data acquired
datas = np.asarray([row['f'] for row in result['rows']])
datas = np.asarray([[v_[i]['v'] for i in xrange(len(v_))] for v_ in datas])
col = ('fullVisitorId','COUNT_fullVisitorId','AVG_hits_hour','SUM_totals_pageviews','SUM_totals_hits','SUM_totals_timeOnSite','SUM_hits_hitNumber','diffdays','OS_Windows','OS_Macintosh','CV_flag')
df = pd.DataFrame(datas, columns=col)


#processing execution of R
r = pr.R(use_pandas = "True")
r.assign('df', df)
r('source("/home/dmp_user/dmp_sample/script/calc.R")')


#Regression equation R acquisition of processing results
r_result = r.get('result')

#Run Query
sql = "  SELECT  "
sql += "  hits.customDimensions.value,  "
sql += "  1 / (1+exp(- (" + str(r_result[' value '][0]) + " + (" + str(r_result[' value '][1]) + " * (COUNT_fullVisitorId)) + (" + str(r_result[' value '][2]) + " *(AVG_hits_hour)) + (" + str(r_result[' value '][3]) + "*(SUM_totals_pageviews)) + (" + str(r_result[' value '][7]) + "*(diffdays)) + (" + str(r_result[' value '][8]) + "*(OS_Windows)) + (" + str(r_result[' value '][9]) + "*(OS_Macintosh))))) AS probability  "
sql += "  FROM(  "
sql += "  SELECT  "
sql += "  fullVisitorId,  "
sql += "  COUNT(fullVisitorId) AS COUNT_fullVisitorId,  "
sql += "  AVG(hits.hour) AS AVG_hits_hour,  "
sql += "  IF (SUM(INTEGER(totals.pageviews)) is null, 1, SUM(INTEGER(totals.pageviews))) AS SUM_totals_pageviews,  "
sql += "  SUM(totals.hits) AS SUM_totals_hits,   "
#connect to big query
sql += "  IF (SUM(INTEGER(totals.timeOnSite)) is null, 1, SUM(INTEGER(totals.timeOnSite))) AS SUM_totals_timeOnSite
,  "
sql += "  SUM(hits.hitNumber) AS SUM_hits_hitNumber,  "
sql += "  MAX(date) AS MAX_date,  "
sql += "  DATEDIFF(TIMESTAMP('2014-09-10 00:00:00'), MAX(date)) AS diffdays,  "
sql += "  device.operatingSystem,  "
sql += "  CASE WHEN device.operatingSystem = 'Windows' THEN 1  "
sql += "      ELSE 0 END AS OS_Windows,  "
sql += "  CASE WHEN device.operatingSystem = 'Macintosh' THEN 1  "
sql += "      ELSE 0 END AS OS_Macintosh,  "
sql += "  hits.customDimensions.value  "
sql += "  FROM  "
sql += "  (TABLE_DATE_RANGE([gcp-samples:gcp_samples.ga_sessions_],  "
sql += "                    TIMESTAMP('2014-07-16'),  "
sql += "                    TIMESTAMP('2014-09-10')))   "
sql += "  WHERE  "
sql += "  hits.customDimensions.index = 6  "
sql += "  AND hits.customDimensions.value = 'n/a'   "
sql += "  GROUP BY fullVisitorId,hits.customDimensions.value,device.operatingSystem,OS_Windows,OS_Macintosh  "
sql += "  ) AS table1  "
sql += "  ORDER BY probability DESC;  "
query = {'query': sql}
result = jobs.query(projectId=PROJECT_NUMBER, body=query).execute(http)
datas = np.asarray([row['f'] for row in result['rows']])
datas = np.asarray([[v_[i]['v'] for i in xrange(len(v_))] for v_ in datas])
col = ('hits.customDimensions.value','probability')
df = pd.DataFrame(datas, columns=col)
scorelist = df.to_csv(index = False)
f = open('/home/dmp_user/dmp_sample/result/result.csv', 'w')
f.write(scorelist)
f.close()
