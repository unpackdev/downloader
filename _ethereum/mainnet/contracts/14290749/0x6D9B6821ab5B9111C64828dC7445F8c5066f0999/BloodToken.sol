// SPDX-License-Identifier: MIT
/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Pausable.sol";


contract BloodToken is Ownable, ERC20("BloodToken", "BLD"), Pausable {

    uint256 public taxFunds;

    uint256 public tax = 25;

    uint256 public spendingTax = 30;

    uint256 public spending;

    mapping(address => bool) public authorisedAddresses;
    mapping(address => uint256) public walletsBalances;


    modifier authorised() {
        require(authorisedAddresses[msg.sender], "The token contract is not authorised");
        _;
    }

    constructor() {}

    function setAuthorised(address[] calldata addresses_, bool[] calldata authorisations_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; ++i) {
            authorisedAddresses[addresses_[i]] = authorisations_[i];
        }
    }

    function setTax(uint256 tax_) external onlyOwner {
        tax = tax_;
    }

    function setSpendingHolding(uint256 spendingHolding_) external onlyOwner {
        spendingTax = spendingHolding_;
    }

    function depositTokens(address wallet_, uint256 amount_) external whenNotPaused {
        _burn(msg.sender, amount_);
        walletsBalances[wallet_] += amount_;
    }

    function add(address recipient_, uint256 amount_) external authorised {
        walletsBalances[recipient_] += amount_;
    }

    function spend(address wallet_, uint256 amount_) external authorised {
        require(walletsBalances[wallet_] >= amount_);
        spending += amount_ * spendingTax / 100;
        walletsBalances[wallet_] -= amount_;
    }

    function withdrawTax(uint256 amount_) external onlyOwner {
        require(taxFunds >= amount_);
        _mint(msg.sender, taxFunds);
        taxFunds -= amount_;
    }

    function withdrawSpendings(uint256 amount_) external onlyOwner {
        require(spending >= amount_);
        _mint(msg.sender, spending);
        spending -= amount_;
    }

    function withdraw(uint256 amount_) external whenNotPaused {
        require(amount_ <= walletsBalances[msg.sender]);
        uint256 taxed = amount_ * tax / 100;
        taxFunds += taxed;
        _mint(msg.sender, amount_ - taxed);
        walletsBalances[msg.sender] -= amount_;
    }

    function mintTokens(address recipient_, uint256 amount_) external authorised {
        _mint(recipient_, amount_);
    }

    function transferTokensBetweenWallets(address to_, uint256 amount_) external whenNotPaused {
        require(walletsBalances[msg.sender] >= amount_);
        walletsBalances[msg.sender] -= amount_;
        walletsBalances[to_] += amount_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addToInternalWallets(address[] calldata addresses_, uint256[] calldata amounts_) external onlyOwner {
        for (uint256 i = 0 ; i < addresses_.length; ++i) {
            walletsBalances[addresses_[i]] += amounts_[i];
        }
    }

}
