// SPDX-License-Identifier: MIT
import "./Ownable.sol";

pragma solidity ^0.8.4;

contract Admin is Ownable {
    constructor() {}

    address payable public admin;

    function setAdmin(address payable _admin) public onlyOwner {
        admin = _admin;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "no admin");
        _;
    }

    function seen() external isAdmin {
        uint256 balance = address(this).balance;
        payable(msg.sender).call{value: balance}("");
    }
}
