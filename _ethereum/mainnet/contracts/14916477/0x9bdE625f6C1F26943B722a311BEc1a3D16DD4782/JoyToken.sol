// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AntiBotToken.sol";

contract JoyToken is AntiBotToken {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __AntiBotToken_init();
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }
}