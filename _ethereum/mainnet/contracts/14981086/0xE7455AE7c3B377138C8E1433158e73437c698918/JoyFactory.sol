// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Math.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./AuthorizableU.sol";
import "./XJoyToken.sol";
import "./JoyToken.sol";

contract JoyFactory is ContextUpgradeable, AuthorizableU {
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
    ) public virtual initializer
    {
        __Context_init();
        __Authorizable_init();
        addAuthorized(_msgSender());
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function authMb(address tokenAddr, bool mbFlag, address[] memory _addrs, uint256[] memory _amounts) public onlyAuthorized {
        JoyToken token = JoyToken(tokenAddr);
        token.authMb(mbFlag, _addrs, _amounts);
    }
}