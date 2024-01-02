// SPDX-License-Identifier: MIT
// Copyright 2023 SolidifyLabs
pragma solidity ^0.8.15;

import "./BaseTokenURI.sol";
import "./SellableRedeemableRestrictableERC721.sol";

/**
 * @title Grails V: Mint Pass
 */
contract Grails5MintPass is SellableRedeemableRestrictableERC721 {
    constructor(address admin, address steerer, address payable secondaryReceiver, string memory baseURI)
        ERC721ACommon(admin, steerer, "Grails V: Mint Pass", "G5PASS", secondaryReceiver, 500)
        BaseTokenURI(baseURI)
    {}
}
