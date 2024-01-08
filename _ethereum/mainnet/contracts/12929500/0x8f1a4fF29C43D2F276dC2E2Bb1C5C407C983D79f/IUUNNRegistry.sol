// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721EnumerableUpgradeable.sol";

interface IUUNNRegistry is IERC721EnumerableUpgradeable{
    function mint(uint256 tokenId, address protectionContract, address to) external;
    function burn(uint256 tokenId) external;
    function protectionContract(uint256 tokenId) external view returns (address);
}