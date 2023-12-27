// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

enum CNCSaleType {
  CLAIM,
  EXCHANGE
}

struct CNCSale {
    uint8 id;
    uint248 mintCost;
    uint248 maxSupply;
    CNCSaleType saleType;
}
