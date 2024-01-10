// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./AccessControlEnumerable.sol";

contract FancyBearHoneyConsumption is AccessControlEnumerable {
    
    bytes32 public constant HONEY_CONSUMER_ROLE = keccak256("HONEY_CONSUMER_ROLE");
    mapping(uint256 => uint256) public honeyConsumed;

    event HoneyConsumed(uint256 _tokenId, uint256 _amount, uint256 _total);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function consumeHoney(uint256 _tokenId, uint256 _honeyAmount) public onlyRole(HONEY_CONSUMER_ROLE) {
        honeyConsumed[_tokenId] += _honeyAmount;
        emit HoneyConsumed(_tokenId, _honeyAmount, honeyConsumed[_tokenId]);
    }

    function getHoneyConsumed(uint256[] memory _tokenIds) public view returns (uint256[] memory){
        uint256[] memory consumedHoney = new uint256[](_tokenIds.length);
        for(uint256 i = 0; i < _tokenIds.length; i++){
            consumedHoney[i] = honeyConsumed[_tokenIds[i]];
        }
        return consumedHoney;

    }
}