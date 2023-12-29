// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract HoodyToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("HoodyGang Token", "$GANG") Ownable(msg.sender) {}

    uint256 public maxSupply = 100000000 ether;

    function airDrop(address _receiver, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Reach out Max Supply.");
        _mint(_receiver, _amount);
    }
}
