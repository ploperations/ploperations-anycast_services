# anycast_services

# replace anycast_services in each badge
![](https://img.shields.io/puppetforge/pdk-version/ploperations/anycast_services.svg?style=popout)
![](https://img.shields.io/puppetforge/v/ploperations/anycast_services.svg?style=popout)
![](https://img.shields.io/puppetforge/dt/ploperations/anycast_services.svg?style=popout)
[![Build Status](https://github.com/ploperations/ploperations-anycast_services/actions/workflows/pr_test.yml/badge.svg?branch=main)](https://github.com/ploperations/ploperations-anycast_services/actions/workflows/pr_test.yml)

Manage Quagga and associated OSPF setup for anycast services such as DNS and RADIUS.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Description](#description)
- [Setup](#setup)
  - [Setup Requirements](#setup-requirements)
  - [Beginning with anycast\_services](#beginning-with-anycast_services)
- [Usage](#usage)
- [Reference](#reference)
- [Changelog](#changelog)
- [Limitations](#limitations)
- [Development](#development)

## Description

This module will install and manage Quagga and its associated services: ospfd & zebra. The design of this module is focused on advertising an [anycast](https://www.cloudflare.com/learning/cdn/glossary/anycast-network/) addresses via OSPF.

## Setup

### Setup Requirements

This module assumes the network your host(s) reside on utilize OSPF.

### Beginning with anycast_services

The very basic steps needed for a user to get the module up and running. This
can include setup steps, if necessary, or it can be an example of the most basic
use of the module.

## Usage

Include usage examples for common use cases in the **Usage** section. Show your
users how to use your module to solve problems, and be sure to include code
examples. Include three to five examples of the most important or common tasks a
user can accomplish with your module. Show users how to accomplish more complex
tasks that involve different types, classes, and functions working in tandem.

## Reference

This module is documented via `pdk bundle exec puppet strings generate --format markdown`. Please see [REFERENCE.md](REFERENCE.md) for more info.

## Changelog

[CHANGELOG.md](CHANGELOG.md) is generated prior to each release via `pdk bundle exec rake changelog`. This proecss relies on labels that are applied to each pull request.

## Limitations

Please take note of the operating systems in `metadata.json` as these are the only ones tested right now. Initial development of the module started wtih Debian 10 which no longer utilizes a service named quagga.

## Development

PR's are welcome!
