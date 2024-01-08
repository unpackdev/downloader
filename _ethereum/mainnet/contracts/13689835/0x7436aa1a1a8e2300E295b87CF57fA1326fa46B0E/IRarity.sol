// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IRarity {
    //enum Rarity {Simple, SimpleUpgraded, Rare, Legendary, F1, F2, F3}
    function loadRaritiesBatch(address _contract, uint256[] memory _tokens, uint8[] memory _rarities) external; 
    function getRarity(address _contract, uint256 _tokenId) external view returns(uint8 r);
    function getRarity2(address _contract, uint256 _tokenId) external view returns(uint8 r);
}

