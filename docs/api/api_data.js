define({ "api": [  {    "type": "get",    "url": "/",    "title": "Request version inforrmation",    "name": "GetApi",    "group": "Api",    "success": {      "fields": {        "Success 200": [          {            "group": "Success 200",            "type": "String",            "optional": false,            "field": "version",            "description": "<p>Version of the API</p>"          },          {            "group": "Success 200",            "type": "Object[]",            "optional": false,            "field": "authentication_endpoints",            "description": "<p>Authentication endpoints.</p>"          }        ]      }    },    "version": "0.0.0",    "filename": "/Users/sergio/workspace/Exchange/manageiq-exchange/app/controllers/v1/api_controller.rb",    "groupTitle": "Api"  }] });
