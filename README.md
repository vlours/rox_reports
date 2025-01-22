# rox_reports

## Description

This bash script provide an easy way to generate & download ROX reports

## Usage

### Basic Usage

Simply run the script with the desired option(s)

```bash
rox_reports.sh [-s <ROX_ENDPOINT_URL>] [-t <ROX_API_TOKEN>] [-h]
```

#### Script Options

```text
usage: rox_reports.sh [-s <ROX_ENDPOINT_URL>] [-t <ROX_API_TOKEN>] [-h]

|---------------------------------------------------------------------------------------------------------------------|
| Options | Description                                                     | Alternate way, setting variables        |
|---------|-----------------------------------------------------------------|-----------------------------------------|
|      -s | Set ROX Endpoint URL                                            | export ROX_ENDPOINT=<ROX_ENDPOINT_URL>  |
|      -t | ROX Token                                                       | export ROX_API_TOKEN=<ROX_API_TOKEN>    |
|---------|-----------------------------------------------------------------|-----------------------------------------|
|         | Additional Options:                                             |                                         |
|---------|-----------------------------------------------------------------|-----------------------------------------|
|      -h | display this help and check for updated version                 |                                         |
|---------------------------------------------------------------------------------------------------------------------|

Current Version: X.Y.Z
```
