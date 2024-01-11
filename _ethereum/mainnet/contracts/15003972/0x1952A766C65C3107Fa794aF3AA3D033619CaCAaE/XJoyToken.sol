// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./BlackListToken.sol";
import "./JoyPresale.sol";

contract XJoyToken is BlackListToken {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    uint256 public manualMinted;
    address privatePresaleAddress;
    address seedPresaleAddress;

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
    function name() public view virtual override returns (string memory) {
        return "xJOY Token";
    }
    
    function symbol() public view virtual override returns (string memory) {
        return "xJOY";
    }
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

    function updatePresaleAddresses(address _privatePresaleAddress, address _seedPresaleAddress) public onlyAuthorized {
        privatePresaleAddress = _privatePresaleAddress;
        seedPresaleAddress = _seedPresaleAddress;
    }

    function isTransferable(address _from, address _to) public view virtual override returns (bool) {
        if (isBlackListChecking) {
            // require(!isBlackListed[_from], "BlackListToken@isTransferable: _from is in isBlackListed");
            // require(!isBlackListed[_to] || isWhiteListed[_to], "BlackListToken@isTransferable: _to is in isBlackListed");
            require(!isBlackListed[_from] || isWhiteListed[_to], "XJoyToken@isTransferable: _from is in isBlackListed");            
        }
        return true;
    }
}