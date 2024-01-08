// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ILuchaNames {
    function getName(address luchaAddress, uint256 _tokenId) external view returns (string memory);
}
