// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Address{

    function isContract(address account) internal view returns(bool){
        return account.code.length > 0;
    }

    function sendValue(address payable recepient , uint amount) internal{
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recepient.call{value:amount}("");
        require(success,"transaction failed");

    }
}