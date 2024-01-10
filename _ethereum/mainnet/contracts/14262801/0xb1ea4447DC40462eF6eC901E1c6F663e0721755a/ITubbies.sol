// SPDX-License-Identifier: GPL-3.0

import "./IERC721.sol";
import "./ERC721A.sol";

pragma solidity ^0.8.0;
interface ITubbies is IERC721{
        function mintFromSale(uint tubbiesToMint) external payable;
}