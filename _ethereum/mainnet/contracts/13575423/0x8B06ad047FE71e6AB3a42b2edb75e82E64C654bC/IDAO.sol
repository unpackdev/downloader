//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IDAO {
 
    function getLockedTokens(address staker) external view returns(uint256 locked);
    
    function getAvailableTokens(address staker) external view returns(uint256 locked);

}
