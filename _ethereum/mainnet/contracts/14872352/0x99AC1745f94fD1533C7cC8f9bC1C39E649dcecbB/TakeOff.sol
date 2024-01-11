// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ReentrancyGuard.sol";
import "ECDSA.sol";
import "SafeERC20.sol";

import "BCANFT1155Base.sol";
import "TakeOffBase.sol";

contract TakeOff is TakeOffBase {

    constructor(string memory name, string memory symbol, uint256 maxSupply, string memory uri,
        RoyaltyInfo memory royaltyInfo,
        address validator_,
        address[] memory tos,
        uint256[] memory amounts
    )

    TakeOffBase(name, symbol, maxSupply, uri, royaltyInfo, validator_) {
        airdropMintTo(tos, amounts);
    }
}

