// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract DnhTest is ERC20 {
    uint256 private _transferFeePercentage;
    // _fundAddress is where the transfer fee/tax is moved to
    address private _fundAddress;
    // owner is deployer of the contract
    address owner;
    mapping(address => bool) whitelistedAddresses;

    constructor() ERC20("DNH Test", "DNHT") {
        _transferFeePercentage = 5;
        _fundAddress = msg.sender;
        _mint(msg.sender, 10000000 * 10**18);
        owner = msg.sender;
        whitelistAddress(owner);
    }

    modifier onlyOwner() {
    require(msg.sender == owner, "Caller must be the owner");
    _;
    }

    function whitelistAddress(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function removeAddressFromWhitelist (address _addressToRemove) public onlyOwner {
        delete whitelistedAddresses[_addressToRemove];
    }

    // Takes an address and returns true if it is whitelisted
    function isWhitelisted(address _whitelistAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistAddress];
        return userIsWhitelisted;
    }

    function setFundAddress(address _newFundAddress) public onlyOwner {
        _fundAddress = _newFundAddress;
    }

    function fundAddress() public view returns (address) {
        return _fundAddress;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address fromAddress = _msgSender();

        // Check if owner is transfering, or owner is the recipient - then don't take the
        // fees, to save gas.
        if (isWhitelisted(fromAddress) || recipient == _fundAddress){
            _transfer(fromAddress, recipient, amount);
        }

        else {
        uint256 fee = (amount * _transferFeePercentage) / 1000;
        uint256 taxedValue = amount - fee;
        uint256 funds = fee;
        _transfer(fromAddress, recipient, taxedValue);
        _transfer(fromAddress, _fundAddress, funds);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        if (isWhitelisted(spender) || to == _fundAddress) {
            _transfer(from, to, amount);
        }
        else {
        uint256 fee = (amount * _transferFeePercentage) / 1000;
        uint256 taxedValue = amount - fee;
        uint256 funds = fee;
        _transfer(from, to, taxedValue);
        _transfer(from, _fundAddress, funds);
        }
        return true;
    }
}