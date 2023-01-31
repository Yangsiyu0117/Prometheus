# -*- conding:utf-8 -*-
import time
import hmac
import hashlib
import base64
import urllib.parse
import requests
import json
import sys

#获取时间戳，签名值
def getSignTimestamp(signature):
    timestamp = str(round(time.time() * 1000))
    secret = signature
    secret_enc = secret.encode('utf-8')
    string_to_sign = '{}\n{}'.format(timestamp, secret)
    string_to_sign_enc = string_to_sign.encode('utf-8')
    hmac_code = hmac.new(secret_enc, string_to_sign_enc, digestmod=hashlib.sha256).digest()
    sign = urllib.parse.quote_plus(base64.b64encode(hmac_code))
    return (timestamp,sign)

#发送text信息到钉钉
def sendDing(url,text):
    headers = {
        'Content-Type': 'application/json',
    }
    data = {
        'msgtype':'text',
        'text':{
            'content': text,
        }
    }
    r = requests.post(url,headers=headers,data=json.dumps(data)).text
    json_r = json.loads(r)

    if json_r['errcode'] == 0:
        print("发送成功")
    else:
        print("发送失败")

def run(text):
    signature = 'SECdfaaa917475bc01443d237fb2299c917c2bdfdfc96dbd9596f1c853ca4ff8196'
    (times,signs) = getSignTimestamp(signature)
    webhook = 'https://oapi.dingtalk.com/robot/send?access_token=2e7a57d2731720053f60143741a1b806b3d4bc89ab142dfedd06947f8c572893'
    urls = webhook + '&timestamp=' + times + '&sign=' + signs
    sendDing(urls,text)


run('test')