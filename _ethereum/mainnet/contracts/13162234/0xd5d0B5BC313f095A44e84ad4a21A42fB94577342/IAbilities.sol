// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IERC721.sol";

interface IAbilities is IERC721 {
    function getCharisma(uint256 _tokenId) external view returns (string memory);
    function getConstitution(uint256 _tokenId) external view returns (string memory);
    function getDexterity(uint256 _tokenId) external view returns (string memory);
    function getIntelligence(uint256 _tokenId) external view returns (string memory);
    function getStrength(uint256 _tokenId) external view returns (string memory);
    function getWisdom(uint256 _tokenId) external view returns (string memory);
}
