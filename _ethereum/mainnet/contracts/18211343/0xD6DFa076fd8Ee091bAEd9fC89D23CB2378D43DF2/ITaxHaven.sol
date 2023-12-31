// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaxHaven {
    function withdrawPanamaVrf(address _user, uint256 _randNum) external;
    function withdrawVenezuelaVrf(address _user, uint256 _randNum, uint256 randNum2) external;
    function claimBribeVrf(address _user, uint256 _reward, uint256 _randNum) external;
}