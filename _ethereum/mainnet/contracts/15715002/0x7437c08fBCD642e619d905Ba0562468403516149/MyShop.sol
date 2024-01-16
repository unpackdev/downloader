// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyShop {
    address owner;

    constructor(){
        owner = msg.sender;
    }

    function payForItem() public payable {

    }

    function wAll () public {
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);

    }
}