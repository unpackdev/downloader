// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract EuphoriaToken is ERC20 ,Ownable{
    uint256 public giveawayTokensSupply = 30000 ether;
    uint256 public givawayTokensMinted;
    uint256 public maxSupply = 1271842500 ether;
    bool public paused = true;
    mapping(address => bool) controllers;

    constructor() ERC20("EuphoriaToken", "EUPHORIA"){}
    
    function giveawayTokens(address to, uint256 amount) public onlyOwner {
        require(givawayTokensMinted <= giveawayTokensSupply && giveawayTokensSupply + totalSupply() <= maxSupply, "Giveaway token supply mints exceeded");
        _mint(to, amount);
        givawayTokensMinted +=amount;
    }
    function mint(address to, uint256 amount) external {
        require(!paused, "Contract is Paused");
        require(controllers[msg.sender], "Only controllers can mint");
        require(amount + totalSupply() <= maxSupply, "Total supply exceeded" );
        _mint(to, amount);
    }
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
    function setMaxSupply(uint256 _maxSupply) public onlyOwner{
        maxSupply = _maxSupply;
    }
    function pause() public onlyOwner {
        paused = !paused;
    }
}