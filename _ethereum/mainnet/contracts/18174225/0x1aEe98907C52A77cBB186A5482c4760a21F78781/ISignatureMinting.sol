// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISignatureMinting {

    struct SignatureMintCart {
       SignatureMintCartItem[] items;
   }

    struct SignatureClaimCart {
       SignatureMintCartItem[] items;
       address minting_wallet;
       address delegated_wallet;
       address receiving_wallet;
       bytes  signature;
       uint256  expirationTime;
   }

   struct SignatureMintCartItem{
        string  uid;
        uint256  quantity;
        uint256  price;
        uint256  allocation;
        uint256  expirationTime;
        uint256  maxSupply;
        bytes  signature;
   }

    struct MintSignature {
       address wallet_address;
       string uid;
       uint256 quantity;
       uint256 price;
       uint256 allocation;
       uint256 startTime;
       uint256 endTime;
   }

   struct Version {
       uint256 major;
       uint256 minor;
       uint256 patch;
   }
}
