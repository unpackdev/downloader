//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IBountyBoard {
    struct ERC721Grouping {
        IERC721 erc721;
        uint256[] ids;
    }
}
