// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";

import "./IUpgradedStandardToken.sol";
import "./BlackList.sol";

contract SperaV3 is Initializable, OwnableUpgradeable, PausableUpgradeable, BlackList, ERC20Upgradeable {
    // Called when new token are issued
    event Issue(uint256 amount);
    // Called when tokens are redeemed
    event Redeem(uint256 amount);
    // Called when contract is deprecated
    event Deprecate(address newAddress);

    address public upgradedAddress;
    bool public deprecated;

    function initialize() public initializer {
        __ERC20_init("Spera", "SPRA");
        _mint(msg.sender, 10000000000000000000);
        __Ownable_init();
    }

    function destroyBlackFunds(address _blackListedUser) public override onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = balanceOf(_blackListedUser);
        _burn(_blackListedUser, dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint256 _value) public override whenNotPaused returns (bool) {
        require(!isBlackListed[msg.sender], "Blacklisted Member");
        if (deprecated) {
            IUpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            super.transfer(_to, _value);
        }
        return true;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool) {
        require(!isBlackListed[_from], "Blacklisted Member");
        if (deprecated) {
            IUpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            super.transferFrom(_from, _to, _value);
        }
        return true;
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public view override returns (uint256) {
        if (deprecated) {
            return IERC20Upgradeable(upgradedAddress).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint256 amount) whenNotPaused external onlyOwner {
        require(totalSupply() + amount > totalSupply(), "Invalide value");
        uint256 addValue;
        bool addBoolValue;
        (addBoolValue, addValue) = SafeMathUpgradeable.tryAdd(balanceOf(owner()), amount);
        require(addBoolValue &&(addValue > balanceOf(owner())), "Invalide value");
        _mint(owner(), amount);
        emit Issue(amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint256 amount) public onlyOwner {
        require(balanceOf(owner()) >= amount);
        _burn(owner(), amount);
        emit Redeem(amount);
    }

    // Pause functions from Pausable.sol contract
    function pause() public onlyOwner{
        _pause();
    }
    // Unpause functions from Pausable.sol contract
    function unpause() public onlyOwner{
        _unpause();
    }

      // minting function to mint the coin
    function mint(uint256 amount, address recipient) public onlyOwner whenNotPaused{
        _mint(recipient, amount);
    }

    // burning function to burn the coin
    function burn(address account, uint256 amount) public onlyOwner whenNotPaused{
        _burn(account, amount);
    }
    
}