//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IEdition is IERC721 {
    function tokenToEdition(uint256) external view returns(uint256);
}