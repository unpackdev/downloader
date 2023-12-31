// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BitMapsUpgradeable.sol";
import "./IERC6551Registry.sol";

contract SapienzStorageV2 {
    string BASE_URI;

    IERC6551Registry erc6551Registry;
    address erc6551AccountImplementation;

    bool public claimEnabled;
    bool public mintEnabled;

    mapping(address => BitMapsUpgradeable.BitMap) _erc721Minted;
}
