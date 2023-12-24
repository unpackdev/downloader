// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * @title MToken (mesLBR for Match Finance)
 * @author Eric Lee
 * @notice mesLBR represents user's share on Match Finance
 *         mesLBR is a ERC20 token
 *
 *         it can be got from:
 *         1)
 *
 *
 *         it can be used to:
 *         1)
 */

contract MToken is ERC20Upgradeable, OwnableUpgradeable {
    mapping(address account => bool isValidMinter) public isMinter;

    event MinterAdded(address minter);
    event MinterRemoved(address minter);

    function initialize(string memory name_, string memory symbol_) external initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
    }

    function addMinter(address _minter) external onlyOwner {
        isMinter[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        isMinter[_minter] = false;
        emit MinterRemoved(_minter);
    }

    function mint(address _to, uint256 _amount) external {
        require(isMinter[msg.sender], "MToken: only minter can mint");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(isMinter[msg.sender], "MToken: only minter can burn");
        _burn(_from, _amount);
    }
}
