//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract Whales is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    uint128 public maxSupply;
    mapping(address => bool) public controllers; // the addresses that can invoke mint and burn.

    function initialize() external initializer {
        __ERC20_init("Whales", "$WHALES");
        __Ownable_init();
        maxSupply = 200000000 ether;
    }

    function mint(address to, uint256 amount) external  {
        require(controllers[msg.sender], "Only controller can mint");
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply, "max supply eached");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external  {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

}
