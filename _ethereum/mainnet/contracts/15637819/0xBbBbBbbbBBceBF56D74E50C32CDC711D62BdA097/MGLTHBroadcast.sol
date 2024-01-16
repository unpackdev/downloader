//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./Owned.sol";

interface MGLTH {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract MGLTHBroadcast is Owned {
    
    bool public broadcastActive;
    bool public vandalizeActive;
    uint public vandalFee;
    address immutable mglthContract = 0xabaCAdabA4A41e86092847d7b07D00094B8203F8;

    
    event Broadcast(address indexed injector, uint indexed token, string mediaHash);
    event Vandalize(address indexed injector, uint indexed token, string mediaHash);

    constructor()Owned(msg.sender) {}

    function broadcast(uint token, string memory mediaHash) external {
        require(broadcastActive, "MGLTHBroadcast: Broadcast is not active");
        require(MGLTH(mglthContract).ownerOf(token) == msg.sender, "MGLTHBroadcast: Not your token");
        emit Broadcast(msg.sender, token, mediaHash);
    }

    function vandalize(uint token, string memory mediaHash) external payable {
        require(vandalizeActive, "MGLTHBroadcast: Vandalize is not active");
        require(MGLTH(mglthContract).ownerOf(token) == msg.sender, "MGLTHBroadcast: Not your token");
        require(_isPrime(token), "MGLTHBroadcast: Token is not prime");
        require(msg.value >= vandalFee, "MGLTHBroadcast: Insufficient vandal fee");
        emit Vandalize(msg.sender, token, mediaHash);
    }

    function _isPrime(uint n) private pure returns (bool) {
        if (n <= 1) {
            return false;
        }
        for (uint256 i = 2; i < n; i++) {
            if (n % i == 0){
                return false;
            }        
        }
        return true;
    }

    function flipBroadcastActive() external onlyOwner {
        broadcastActive = !broadcastActive;
    }

    function flipVandalizeActive() external onlyOwner {
        vandalizeActive = !vandalizeActive;
    }

    function setVandalFee(uint fee) external onlyOwner {
        vandalFee = fee;
    }

    function withdraw() external onlyOwner {
        assembly {
            let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
            switch result
            case 0 { revert(0, 0) }
            default { return(0, 0) }
        }
    }
}