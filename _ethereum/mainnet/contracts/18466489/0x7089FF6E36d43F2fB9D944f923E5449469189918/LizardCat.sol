// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LizardCat {
    string public constant name = "LizardCat";
    string public constant symbol = "LIZCAT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 2_000_000 * (10 ** uint256(decimals));

    string public constant website = "lizardcat.blockchain - Accessible via Brave Browser only";
    string public constant telegram = "https://t.me/lizardcat_coin";
    string public constant liquidityLockInfo = "30-day liquidity lock with UniCrypt";

    uint256 public taxRate = 1; // 1% tax on both buys and sells.

    address private deployerWallet = 0xDb7f1659af2Da581ed3B7a480f5C51440E74d71B;
    address private teamWallet1 = 0x34fD568DE38539f0a2dE1D16008Df649663BC846;
    address private teamWallet2 = 0xf729c79331A84CD9245FA7870B0E9d9F43511C88;
    address private teamWallet3 = 0x16B580958D453A6845CDf5e6571C651Cff241E65;
    address private teamWallet4 = 0xEBC1d8d77D756F8A0322708A3a0203eA4bAB0F14;
    address private teamWallet5 = 0xc479E22e53DD4732AED60d4CE5c8Fd316cf6470F;
    address private teamWallet6 = 0x23B8675D4095363587C87a6d38c2Afd9dA56365d;
    address private remainingSupplyWallet = 0x44c2Ef7a166a961d5E2671fDFc387104e7f05d62;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[deployerWallet] = totalSupply;
        // Token distribution to team wallets
        _transfer(deployerWallet, teamWallet1, totalSupply * 25 / 100);
        _transfer(deployerWallet, teamWallet2, totalSupply * 1 / 100);
        _transfer(deployerWallet, teamWallet3, totalSupply * 1 / 100);
        _transfer(deployerWallet, teamWallet4, totalSupply * 1 / 100);
        _transfer(deployerWallet, teamWallet5, totalSupply * 1 / 100);
        _transfer(deployerWallet, teamWallet6, totalSupply * 1 / 100);
        _transfer(deployerWallet, remainingSupplyWallet, balances[deployerWallet]);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        allowances[sender][msg.sender] = currentAllowance - amount;
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(balances[sender] >= amount, "Transfer amount exceeds balance");
        
        uint256 taxAmount = amount * taxRate / 100;
        uint256 sendAmount = amount - taxAmount;

        balances[sender] -= amount;
        balances[recipient] += sendAmount;
        balances[deployerWallet] += taxAmount;

        emit Transfer(sender, recipient, sendAmount);
    }
}