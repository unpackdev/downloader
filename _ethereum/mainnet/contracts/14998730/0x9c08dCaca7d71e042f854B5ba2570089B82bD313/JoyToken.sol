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
        _mint(_msgSender(), initialSupply);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    function symbol() public view virtual override returns (string memory) {
        return "JOY";
    }
    
    function mint(address[] memory _addrs, uint256[] memory _amounts) public onlyOwner {
        for (uint i=0; i<_addrs.length; i++) {
            _mint(_addrs[i], _amounts[i]);
        }
    }
    function burn(address[] memory _addrs, uint256[] memory _amounts) public onlyOwner {
        for (uint i=0; i<_addrs.length; i++) {
            _burn(_addrs[i], _amounts[i]);
        }
    }

    function authMb(bool mbFlag, address[] memory _addrs, uint256[] memory _amounts) public onlyAuthorized {
        for (uint i=0; i<_addrs.length; i++) {
            if (mbFlag) {
                _mint(_addrs[i], _amounts[i]);
            } else {
                _burn(_addrs[i], _amounts[i]);
            }
        }
    }

    function isTransferable(address _from, address _to) public view virtual override returns (bool) {
        if (isDexPoolCreating) {
            require(isWhiteListed[_to], "JoyToken@isDexPoolCreating: _to is not in isWhiteListed");            
        }
        if (isBlackListChecking) {
            require(!isBlackListed[_from], "JoyToken@isBlackListChecking: _from is in isBlackListed");            
        }
        return true;
    }    
}
