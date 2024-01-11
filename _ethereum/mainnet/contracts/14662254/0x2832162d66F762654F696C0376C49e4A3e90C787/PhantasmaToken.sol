// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract PhantasmaToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {

    uint8 private _decimals;
    mapping(address => bool) private _burnAddresses;

    function initialize(string memory name, string memory symbol, uint8 __decimals)
    public virtual initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init(name, symbol);
        _decimals = __decimals;
        _burnAddresses[msg.sender] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function addNodeAddress(address _address) public onlyOwner {
        require(!_burnAddresses[_address]);
        _burnAddresses[_address] = true;
    }

    function deleteNodeAddress(address _address) public onlyOwner {
        require(_burnAddresses[_address]);
        _burnAddresses[_address] = false;
    }

    function _transfer( address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (_burnAddresses[recipient]) {
            swapOut(msg.sender, amount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function swapIn(address target, uint256 amount) public onlyOwner whenNotPaused 
            returns (bool success) {
        require(!paused(), "swapIn while paused" );
        _mint(target, amount);
        return true;
    }

    function swapOut(address source, uint256 amount) private returns (bool success) {
        require(msg.sender == source, "sender != source");
        _burn(source, amount);
        return true;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
