// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract F4C is IERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public _name = "FIGHT4CRYPTO";
    string public _symbol = "F4C";
    uint8 public _decimals = 8;

    uint256 public override totalSupply = 1000e9; 
    uint256 private _initialSupply = totalSupply.mul(10**uint256(_decimals));

    uint256 public taxPercentage = 3;

    address public teamWallet;
    address public marketingWallet;
    address public contributorsWallet;

    bool public paused = true; 

    mapping(address => uint256) private _balances;
    mapping(address => bool) public taxExempt;
    mapping(address => uint256) public userRewardDebt;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public totalReflectedRewards = 0;
    uint256 public totalRewardsPerToken = 0;

    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    constructor(address _teamWallet, address _marketingWallet, address _contributorsWallet) Ownable(msg.sender) { 
        teamWallet = _teamWallet;
        marketingWallet = _marketingWallet;
        contributorsWallet = _contributorsWallet;

        taxExempt[owner()] = true;  
        taxExempt[teamWallet] = true;
        taxExempt[marketingWallet] = true;
        taxExempt[contributorsWallet] = true;
        _balances[owner()] = _initialSupply;  
        emit Transfer(address(0), owner(), _initialSupply);  
}

    function transfer(address recipient, uint256 amount) public override nonReentrant whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalBalanceOf(address account) public view returns (uint256) {
        return _balances[account].add(pendingRewards(account));
    }

    function approve(address spender, uint256 amount) public override nonReentrant returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public nonReentrant override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance.sub(amount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        // If sender or recipient is a contract, or if sender is not tax-exempt, calculate tax
        if (!taxExempt[sender] && (isContract(sender) || isContract(recipient))) {
           uint256 tax = amount.mul(taxPercentage).div(100);
           uint256 transferAmount = amount.sub(tax);
           _distributeTax(sender, tax);

           _balances[sender] = senderBalance.sub(amount);
           _balances[recipient] = _balances[recipient].add(transferAmount);
           emit Transfer(sender, recipient, transferAmount);
        } else {
            _balances[sender] = senderBalance.sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _distributeTax(address from, uint256 taxAmount) internal {
        uint256 teamAmount = taxAmount.mul(1).div(4); // 1%  
        uint256 marketingAmount = taxAmount.mul(1).div(8); // 0.5%
        uint256 contributorsAmount = taxAmount.mul(3).div(16); // 0.75%
        uint256 holdersAmount = taxAmount.mul(3).div(16); // 0.75%

            _balances[teamWallet] = _balances[teamWallet].add(teamAmount);
            _balances[marketingWallet] = _balances[marketingWallet].add(marketingAmount);
            _balances[contributorsWallet] = _balances[contributorsWallet].add(contributorsAmount);
            totalReflectedRewards = totalReflectedRewards.add(holdersAmount);

        // The holders' rewards are not distributed immediately in this function.
        // They are reflected in 'totalRewardsPerToken' which is used to calculate holder rewards.
        if (totalSupply > 0) {
            totalRewardsPerToken = totalRewardsPerToken.add(holdersAmount.mul(1e18).div(totalSupply));
        }

        // Emit events for the transfers
        emit Transfer(from, teamWallet, teamAmount);
        emit Transfer(from, marketingWallet, marketingAmount);
        emit Transfer(from, contributorsWallet, contributorsAmount);
       // Note: The holders' rewards are not transferred here, they are calculated when holders transfer or withdraw tokens.
    }

    function pendingRewards(address account) public view returns (uint256) {
        return _balances[account].mul(totalRewardsPerToken).div(1e18).sub(userRewardDebt[account]);
    }

    function _updateRewardDebt(address account) internal {
        uint256 reward = pendingRewards(account);
        _balances[account] = _balances[account].add(reward);
        userRewardDebt[account] = _balances[account].mul(totalRewardsPerToken).div(1e18);
    }

    function burnFromContract(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount to burn must be greater than 0");
        require(_balances[owner()] >= amount, "Insufficient balance to burn"); 
        _balances[owner()] = _balances[owner()].sub(amount); 
        totalSupply = totalSupply.sub(amount);
        emit Transfer(owner(), address(0), amount); 
    }

    function _approve(address owner, address spender, uint256 amount) internal nonReentrant {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }
    
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amounts) public onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    function addTaxExempt(address _address) external onlyOwner {
        taxExempt[_address] = true;
    }

    function removeTaxExempt(address _address) external onlyOwner {
        taxExempt[_address] = false;
    }

    function isContract(address _address) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
            }
        return (size > 0);
    }
    

}

