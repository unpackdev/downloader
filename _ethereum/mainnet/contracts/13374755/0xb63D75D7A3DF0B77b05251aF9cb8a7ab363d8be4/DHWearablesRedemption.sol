// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

interface IDeadHeadsWearables {
    function burn(address account, uint256 id, uint256 value) external;
    function balanceOf(address account, uint256 id) external view returns (uint);
}

contract DHWearablesRedemption {
    using EnumerableSet for EnumerableSet.UintSet;
    
    IDeadHeadsWearables _deadHeadsWearables;
    
    struct BurntToken {
        address burner;
        uint tokenId;
        uint timestamp;
        uint burnId;
    }
    
    event TokenBurnt(address burner, uint tokenId, uint burnId);
    
    uint public totalBurntTokens;
    
    mapping(uint => BurntToken) _burntTokens;
    
    mapping(address => EnumerableSet.UintSet) _userBurntTokens;
    
    constructor() {
        _deadHeadsWearables = IDeadHeadsWearables(0x18E4f33b727e4658832576379d4549E31aB7c4cb);
    }
    
    function userTotalBurnt(address userAddress) public view returns (uint) {
        return _userBurntTokens[userAddress].length();
    }
    
    function userBurntTokenByIndex(address userAddress, uint index) public view returns (BurntToken memory) {
        require(index < userTotalBurnt(userAddress), "index out of bounds");
        
        return _burntTokens[_userBurntTokens[userAddress].at(index)];
    }
    
    function burntTokenByIndex(uint index) public view returns (BurntToken memory) {
        require(index < totalBurntTokens, "index out of bounds");
        
        return _burntTokens[index];
    }
    
    function burn(uint tokenId, uint quantity) public {
        require(quantity > 0, "quantity must not be zero");
        
        _deadHeadsWearables.burn(msg.sender, tokenId, quantity);
        
        for(uint i = 0; i < quantity; i++) {
            uint burntIndex = totalBurntTokens++;
            
            _burntTokens[burntIndex] = BurntToken({
                burner: msg.sender,
                tokenId: tokenId,
                timestamp: block.timestamp,
                burnId: burntIndex
            });
            _userBurntTokens[msg.sender].add(burntIndex);
            
            emit TokenBurnt(msg.sender, tokenId, burntIndex);
        }
    }
    
    function balanceOf(address userId, uint tokenId) public view returns (uint) {
        return _deadHeadsWearables.balanceOf(userId, tokenId);
    }
}