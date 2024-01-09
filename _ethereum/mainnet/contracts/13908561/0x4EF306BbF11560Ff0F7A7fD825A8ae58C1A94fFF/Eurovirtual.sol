// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./SafeMath.sol";

/// @custom:security-contact security@eurovirtual.eu
contract Eurovirtual is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable {
    
    using SafeMath for uint256;

    // address that will receive the fees
    address public _feeWallet;

    // fee in basis points
    uint256 public _fee;

    // make sure that the initialize function is called one time only
    bool private initialized;

    event SetFee(uint256 newFee);
    event SetFeeWallet(address newFeeWallet);

    function initialize(address feeWallet, uint256 fee) initializer public {

        require(!initialized, "Contract instance has already been initialized");
        initialized = true;

        __ERC20_init("EuroVirtual", "EURV");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("EuroVirtual");

        setFee(fee);
        setFeeWallet(feeWallet);
    }

    function setFee(uint256 _newFee) public onlyOwner {
        require(
            (_newFee >= 0) && (_newFee < 10000),
            "New fee must be equal or bigger then zero."
        );
        _fee = _newFee;
        emit SetFee(_newFee);
    }

    function setFeeWallet(address _newFeeWallet)
        public
        onlyOwner
        validAddress(_newFeeWallet)
    {
        _feeWallet = _newFeeWallet;
        emit SetFeeWallet(_newFeeWallet);
    }

    function calculateFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_fee).add(10000 - 1).div(10000);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount)
        internal
        override
        virtual
        validAddress(recipient)
    {
        if (_fee == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 fee = calculateFee(amount);
            uint256 newAmount = amount.sub(fee);
            super._transfer(sender, _feeWallet, fee);
            super._transfer(sender, recipient, newAmount);
        }
    }

    function _approve(address owner, address spender, uint256 amount)
        internal
        override
        virtual
        validAddress(spender)
    {
        super._approve(owner, spender, amount);
    }

    modifier validAddress(address _recipient) virtual {
        require(_recipient != address(this), "invalid address");
        _;
    }
}