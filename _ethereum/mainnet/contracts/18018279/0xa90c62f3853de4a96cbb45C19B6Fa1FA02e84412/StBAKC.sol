// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./INftVault.sol";

import "./StNft.sol";

contract StBAKC is StNft {
    function initialize(IERC721MetadataUpgradeable bakc_, INftVault nftVault_) public initializer {
        __StNft_init(bakc_, nftVault_, "Staked BAKC", "stBAKC");
    }
}
