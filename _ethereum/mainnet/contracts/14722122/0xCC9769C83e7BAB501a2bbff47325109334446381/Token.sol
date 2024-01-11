// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {
    address public admin;

    // constructor for creating a new token and setting the admin for the Token
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        admin = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    // method for updating the admin

    function updateAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can access this method");
        _;
    }
}
