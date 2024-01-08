// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";

contract TestContract is Ownable {
    constructor() public {
    }

    function refund(uint256 amount) public onlyOwner {
        address payable _owner = payable(owner());
        (bool succ,) = _owner.call{value : amount}("");
        require(succ, "FixedSale: Owner transfer failed");
    }
}