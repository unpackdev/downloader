// contracts/IDebtCity.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";


interface IProperty is IERC721 {
    function getPayForProperty(uint256 _tokenId) external view returns (uint8);
}
