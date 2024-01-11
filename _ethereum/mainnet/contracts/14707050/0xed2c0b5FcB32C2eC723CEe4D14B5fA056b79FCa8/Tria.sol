// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Tria is ERC20, Ownable {
    
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public allowanceByPasser;
    mapping(address => bool) public allowedMinter;

    constructor(
        address[] memory _wallets,
        uint256[] memory _amounts
    ) ERC20("Tria", "$TRIA") {
        require(_wallets.length > 0 && _amounts.length > 0, "NO WALLETS OR BALANCES PROVIDED");
        require(_wallets.length == _amounts.length, "WALLETS DO NOT MATCH AMOUNTS");
        for (uint256 i = 0; i < _wallets.length; i++) {
            _mint(_wallets[i], _amounts[i]);
        }
    }

    function mintRewardForUser(address user, uint256 amount) external {
        require(allowedMinter[msg.sender], "Sender not allowed to mint reward");
        if (amount > 0) {
            _mint(user, amount);
        }
    }

    function burnTria(address user, uint256 amount) external {
        require(allowedMinter[msg.sender], "Sender not allowed to burn tria");
        if (amount > 0) {
            _burn(user, amount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[from] && !isBlacklisted[to], "Sender or recipient blacklisted");
        super._transfer(from, to, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        if (!allowanceByPasser[spender]) {
            super._spendAllowance(owner, spender, amount);
        }       
    }

    function setBlackListed(address wallet, bool isBlackList) 
        external 
        onlyOwner {
        isBlacklisted[wallet] = isBlackList;
    }

    function setAllowanceByPasser(address bypasser, bool canBypass)
        external 
        onlyOwner {
            allowanceByPasser[bypasser] = canBypass;
        }

    function setAllowedMinter(address _allowed, bool _isAllowed)
        external
        onlyOwner {
            allowedMinter[_allowed] = _isAllowed;
        }
}
