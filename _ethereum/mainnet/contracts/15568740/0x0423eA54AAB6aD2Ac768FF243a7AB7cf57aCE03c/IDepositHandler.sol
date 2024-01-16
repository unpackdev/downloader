// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./IERC721.sol";

interface IDepositHandler {
    struct FungibleTokenDeposit {
        address tokenAddress;
        uint256 amount;
        bool isLP;
    }

    struct NonFungibleTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
    }

    struct MultiTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }
}
