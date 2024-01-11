//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITypeBVault {

    ///@dev When you claim, the amount corresponding to the round goes to the vault
    ///@param _to give token Address
    ///@param _amount give token amount
    function claim(
        address _to, 
        uint256 _amount
    ) 
        external;
}