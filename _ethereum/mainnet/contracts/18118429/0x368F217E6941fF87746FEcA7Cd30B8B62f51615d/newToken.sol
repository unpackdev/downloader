// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";


contract TokenLock is Ownable {
    

    address public constant beneficiary = 0xe1AaE8AB34b6522Bdba89e418812A6D47D849842;

    
    // unlock timestamp in seconds (5th SEP 2026 UTC)
    uint public constant unlockTime = 1788546600;

    function isUnlocked() public view returns (bool) {
        return block.timestamp > unlockTime;
    }
    
    function claim(address _tokenAddr, uint _amount) public onlyOwner {
        require(isUnlocked(), "Cannot transfer tokens while locked.");
        IERC20(_tokenAddr).transfer(beneficiary, _amount);
    }
}