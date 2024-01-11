// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity ^0.8.7;

import "Ownable.sol";

contract FairXYZWallets is Ownable{
    
    address internal signerAddress;

    address internal withdrawAddress;

    constructor(address addressForSigner, address addressForWithdraw){
        signerAddress = addressForSigner;
        withdrawAddress = addressForWithdraw;
    }

    function viewSigner() public view returns(address)
    {
        return(signerAddress);
    }

    function viewWithdraw() public view returns(address)
    {
        return(withdrawAddress);
    }

    function changeSigner(address newAddress) public onlyOwner returns(address)
    {
        signerAddress = newAddress;
        return signerAddress;
    }

    function changeWithdraw(address newAddress) public onlyOwner returns(address)
    {
        withdrawAddress = newAddress;
        return withdrawAddress;
    }


}