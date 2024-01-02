//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./console.sol";
contract JonCoin is
    ERC20("JonCoin", "JNC"),
    ERC20Burnable,
    Ownable
{
    uint256 private cap = 50_000_000_000 * 10**uint256(18);
    constructor() {
        console.log("owner: %s maxcap: %s", msg.sender, cap);
        _mint(msg.sender, cap);
        transferOwnership(msg.sender);
    }
    function mint(address to, uint256 amount) public onlyOwner {
        require(
            ERC20.totalSupply() + amount <= cap,
            "JonCoin: cap exceeded"
        );
        _mint(to, amount);
    }
}