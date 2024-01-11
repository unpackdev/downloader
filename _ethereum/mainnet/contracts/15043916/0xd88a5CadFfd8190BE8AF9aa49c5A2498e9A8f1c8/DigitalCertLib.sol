// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library DigitalCertLib {
    struct DigitalCertificate {
      uint256 expire; // unix timestamp
      uint256 price;
    }

    struct DigitalCertificateRes {
      uint256 certId;
      uint256 expire;
      uint256 price;
      uint256 available;
      bool isPaused;
    }
}