# Send network data to stdout which may be used to build an openapi spec file

Inspired by the following repo.
https://github.com/joolfe/postman-to-openapi/tree/master

# Here's the steps to generate a spec file
Send traffic and log the output.

Incorporate the boilerplate like below into your logged requests

```
    "info": {
        "_postman_id": "abc",
        "name": "My Collection name",
        "description": "my first description",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
        "_exporter_id": "123"
    },
    "item": []
```

You will need to insert each logline into the `items` field in the above boilerplate.

# Examples
## Example logged requests with boilerplate
```
{
    "info": {
        "_postman_id": "abc",
        "name": "My Collection name",
        "description": "my first description",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
        "_exporter_id": "123"
    },
    "item": [
        {
            "info": {
                "_exporter_id": "123",
                "_postman_id": "abc",
                "description": "my first description",
                "name": "New Collection name",
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            },
            "item": [
                {
                    "name": "00000000000000000000000000000004",
                    "request": {
                        "body": {
                            "mode": "raw",
                            "raw": ""
                        },
                        "headers": [],
                        "method": "GET",
                        "url": {
                            "host": [
                                "127",
                                "0",
                                "0",
                                "1"
                            ],
                            "path": [
                                "anything",
                                "1",
                                "get"
                            ],
                            "protocol": "https",
                            "raw": "http://127.0.0.1:7676/anything/1/get"
                        }
                    },
                    "response": []
                }
            ]
        },
        {
            "info": {
                "_exporter_id": "123",
                "_postman_id": "abc",
                "description": "my first description",
                "name": "New Collection name",
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            },
            "item": [
                {
                    "name": "00000000000000000000000000000005",
                    "request": {
                        "body": {
                            "mode": "raw",
                            "raw": ""
                        },
                        "headers": [],
                        "method": "GET",
                        "url": {
                            "host": [
                                "127",
                                "0",
                                "0",
                                "1"
                            ],
                            "path": [
                                "anything",
                                "2",
                                "get"
                            ],
                            "protocol": "https",
                            "raw": "http://127.0.0.1:7676/anything/2/get"
                        }
                    },
                    "response": []
                }
            ]
        },
        {
            "info": {
                "_exporter_id": "123",
                "_postman_id": "abc",
                "description": "my first description",
                "name": "New Collection name",
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            },
            "item": [
                {
                    "name": "00000000000000000000000000000003",
                    "request": {
                        "body": {
                            "mode": "raw",
                            "raw": "{\"foo\": \"bar\"}"
                        },
                        "headers": [],
                        "method": "POST",
                        "url": {
                            "host": [
                                "127",
                                "0",
                                "0",
                                "1"
                            ],
                            "path": [
                                "anything",
                                "3",
                                "post"
                            ],
                            "protocol": "https",
                            "raw": "http://127.0.0.1:7676/anything/3/post"
                        }
                    },
                    "response": []
                }
            ]
        }
    ]
}
```
## Example OpenAPI spec
Below is the OpenAPI spec that is generated from https://kevinswiber.github.io/postman2openapi/

```
openapi: 3.0.3
info:
  title: My Collection name
  description: my first description
  version: 1.0.0
  contact: {}
servers:
  - url: https://127.0.0.1
paths:
  /anything/1/get:
    get:
      tags:
        - <folder>
      summary: '00000000000000000000000000000004'
      description: '00000000000000000000000000000004'
      operationId: '00000000000000000000000000000004'
      requestBody:
        content:
          text/plain:
            examples:
              '00000000000000000000000000000004':
                value: ''
      responses:
        '200':
          description: ''
  /anything/2/get:
    get:
      tags:
        - <folder>1
      summary: '00000000000000000000000000000005'
      description: '00000000000000000000000000000005'
      operationId: '00000000000000000000000000000005'
      requestBody:
        content:
          text/plain:
            examples:
              '00000000000000000000000000000005':
                value: ''
      responses:
        '200':
          description: ''
  /anything/3/post:
    post:
      tags:
        - <folder>12
      summary: '00000000000000000000000000000003'
      description: '00000000000000000000000000000003'
      operationId: '00000000000000000000000000000003'
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                foo:
                  type: string
                  example: bar
            examples:
              '00000000000000000000000000000003':
                value:
                  foo: bar
      responses:
        '200':
          description: ''
tags:
  - name: <folder>
  - name: <folder>1
  - name: <folder>12

```