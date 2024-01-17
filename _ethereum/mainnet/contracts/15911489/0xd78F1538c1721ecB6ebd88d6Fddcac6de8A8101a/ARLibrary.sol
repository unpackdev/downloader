// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ARLibrary {
  struct Claim {
    string barcodeId;
    string material;
    uint256 mass; // in grams for gold, kilograms for almost everything else
    uint256 purity; // 0-100%, base denominator 10_000
    string country;
    address creator;
    address[] beneficiaries;
    uint256[] percentages;
  }

  struct Beneficiary {
    address beneficiary;
    uint256 percent; // 0-100%, base denominator 10_000
  }
}
