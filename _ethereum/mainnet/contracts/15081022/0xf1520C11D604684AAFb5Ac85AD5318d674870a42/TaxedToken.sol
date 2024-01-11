// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TaxedToken is ERC20 {
    uint256 private _transferFeePercentage;
    address private _fundAddress;
    address owner;
    mapping(address => bool) whitelistedAddresses;

    constructor(
        address fundAddress_
    ) ERC20("Taxed Token", "TTC") {
        _transferFeePercentage = 5;
        _fundAddress = fundAddress_;
        _mint(msg.sender, 10000000 * 10**18);
        owner = msg.sender;
        whitelistAddress(owner);
    }

    modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not the owner");
    _;
    }

    function whitelistAddress(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function isWhitelisted(address _whitelistAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistAddress];
        return userIsWhitelisted;
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
        address owner2 = _msgSender();
        if (isWhitelisted(owner2)) {
            _transfer(owner2, recipient, amount);
        }
        else {
        uint256 fee = (amount * _transferFeePercentage) / 1000;
        uint256 taxedValue = amount - fee;
        uint256 funds = fee;
        _transfer(owner2, recipient, taxedValue);
        _transfer(owner2, _fundAddress, funds);
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
        if (isWhitelisted(spender)) {
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