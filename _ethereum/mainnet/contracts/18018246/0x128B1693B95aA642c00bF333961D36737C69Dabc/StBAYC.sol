// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./INftVault.sol";

import "./StNft.sol";

contract StBAYC is StNft {
    function initialize(IERC721MetadataUpgradeable bayc_, INftVault nftVault_) public initializer {
        __StNft_init(bayc_, nftVault_, "Staked BAYC", "stBAYC");
    }
}
