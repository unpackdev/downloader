// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IERC20.sol";
import "./ERC20.sol";

contract XRPETF is ERC20("XRPETF", "XRPETF") {

    mapping(address => bool) public whitelist;
    address public admin;
    uint256 public constant initialSupply = 53652766196 * 10**18; // 1 token with 18 decimals
    bool public limitActive;

    constructor() {
        admin = msg.sender;
        _mint(admin, initialSupply);
        limitActive = false; // Initially, the limit is not active
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier ensureNoMoreThan1PercentIfNotWhitelisted(address to, uint256 amount) {
        uint256 toBalance = balanceOf(to);
        uint256 onePercentOfTotalSupply = totalSupply() / 10;

        if (limitActive && !whitelist[to]) {
            require(msg.sender == admin || (msg.sender != admin && toBalance + amount <= onePercentOfTotalSupply), "Illegal operation. Account would have more than 10% of the total supply.");
        }

        _;
    }

    function toggleLimit() public onlyAdmin {
        limitActive = !limitActive;
    }

    function transfer(address to, uint256 amount) public override ensureNoMoreThan1PercentIfNotWhitelisted(to, amount) returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override ensureNoMoreThan1PercentIfNotWhitelisted(to, amount) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function addToWhitelist(address addr) public onlyAdmin {
        whitelist[addr] = true;
    }

    function removeFromWhitelist(address addr) public onlyAdmin {
        delete whitelist[addr];
    }

    function renounceOwnership() public onlyAdmin {
        admin = address(0);
    }
}
