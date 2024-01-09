// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Address.sol";
import "./SafeTransfer.sol";

struct CreatorConfig {
    address payable creatorWalletAddress;
    address wethAddress;
}

abstract contract Creator is SafeTransfer {
    CreatorConfig public _creatorConfig;

    mapping(uint256 => bool) private _creatorSealedTokens;

    modifier creatorConfigSet() {
        require(
            _creatorConfig.creatorWalletAddress != address(0),
            "Creator: _creatorConfig not set"
        );
        _;
    }

    modifier creatorCanUpdateToken(uint256 tokenId) {
        require(
            msg.sender != _creatorConfig.creatorWalletAddress ||
                !_creatorSealedTokens[tokenId],
            "Creator: tokenId is sealed"
        );
        _;
    }

    function payCreator(uint256 amount) internal creatorConfigSet {
        safeTransferETH(
            _creatorConfig.wethAddress,
            _creatorConfig.creatorWalletAddress,
            amount
        );
    }

    function sealTokenForCreator(uint256 tokenId) internal creatorConfigSet {
        _creatorSealedTokens[tokenId] = true;
    }
}
