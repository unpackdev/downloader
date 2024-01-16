// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IDiamondCut.sol";
import "./LivelyDiamond.sol";

/// @custom:security-contact support@golive.ly
contract Arise is LivelyDiamond {
    constructor(
        IDiamondCut.FacetCut[] memory _diamondCut,
        LivelyDiamond.DiamondArgs memory _args
    ) payable LivelyDiamond(_diamondCut, _args) {}
}
