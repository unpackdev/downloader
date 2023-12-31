// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";

interface IConstrainedNFT is IERC721 {
    function setMarketplaceAddress(address _marketplaceAddress) external;
}