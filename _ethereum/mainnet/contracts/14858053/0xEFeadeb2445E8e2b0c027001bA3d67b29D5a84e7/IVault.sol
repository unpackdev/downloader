// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

interface IVault {
    
    function depositSmallCircle(uint256 amount) external returns (uint256 bigCircles);

    function sellSmallCircle(address _LPToken, uint256 amount) external returns (uint256 claimedBack);
    
}
