// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library DataLibrarry {
  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct Metadata {
    uint8 evolution;
    uint8 types;
  }

  enum MetadataEvolution {
    Evolution1,
    Evolution2,
    Evolution3,
    Evolution4,
    Evolution5,
    Evolution6,
    Evolution7
  }

  enum MetadataType {
    B,
    A
  }

  enum SalePhase {
    Phase01,
    Phase02,
    Phase03,
    Phase04,
    Phase05
  }

  enum CouponType {
    PrivateSales,
    WhiteListSales
  }

  struct CouponTypeCount {
    uint16 BasicCount;
    uint16 UltrarareCount;
    uint16 LegendaireCount;
    uint16 eggCount;
  }

  struct CouponClaim {
    address user;
    uint256 legCount;
    uint256 urEggCount;
    uint256 urCount;
    uint256 basicEggCount;
    uint256 basicCount;
    uint256 phase;
  }
}