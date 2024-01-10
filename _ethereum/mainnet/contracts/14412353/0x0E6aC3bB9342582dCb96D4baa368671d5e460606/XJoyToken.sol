// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./BlackListToken.sol";

contract XJoyToken is BlackListToken {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    uint256 public manualMinted;

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
        __BlackList_init();
        _mint(_msgSender(), initialSupply);
        addAuthorized(_msgSender());
        manualMinted = 0;
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

    function manualMint(address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
        manualMinted = manualMinted.add(_amount);
    }

    // add purchaser
    function addPurchaser(address addr) public onlyAuthorized {
      addBlackList(addr);
    }
}