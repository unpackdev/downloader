// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20Capped.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract MottoToken is ERC20Capped, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public maxSupply;
    uint256 public rate;
    uint256 public totalEthReceived;

    constructor(uint256 initialSupply, address owner, uint256 _rate) ERC20Capped(initialSupply) ERC20("MOTTO", "MOTTO") public {
        _mint(address(this), initialSupply);
        transferOwnership(owner);
        maxSupply = initialSupply;
        rate = _rate;
    }
    
    receive() external payable nonReentrant {
        require(msg.value > 0, "Not enough funds");
        uint256 tokensToTransfer = msg.value.mul(rate);
        totalEthReceived = totalEthReceived.add(msg.value);
        
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Transfer failed");

        _transfer(address(this), msg.sender, tokensToTransfer);
    }
}
