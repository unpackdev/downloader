/*
  $EXP by @scholarznft
  (inspired by ACYCapital - https://etherscan.io/address/0xb56a1f3310578f23120182fb2e58c087efe6e147)

  Buy tax ($EXP):
  - 10% of each buy goes into endowment fund and distributed as backend tokens

  Sell tax (ETH):
  - 5% goes to buyback wallet
  - 4% goes to EXP shop
  - 1% goes to team
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20Upgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Exp is ERC20Upgradeable, ERC20PausableUpgradeable, OwnableUpgradeable {
  using ECDSAUpgradeable for bytes32;
  uint public minimumTokensToSwap;
  address payable public walletAddress1; // 5%
  address payable public walletAddress2; // 4%
  address payable public walletAddress3; // 1%

  // verification
  address private _signer;
  mapping(bytes32 => bool) private _usedKey;
  mapping(address => uint) public lastClaimed;
  uint public durationBetweenClaim;
  uint public costToClaim;

  // taxes
  uint public buyTaxPercentage;
  uint public buyTaxCount;
  uint public sellTaxPercentage;
  uint public toWallet1Percentage;
  uint public toWallet2Percentage;
  uint public toWallet3Percentage;
  
  mapping(address => bool) private _isExcludedFromTaxes;
  
  // uniswap V2
  address private uniDefault;
  IUniswapV2Router02 public uniswapV2Router;
  bool private _inSwap; 
  address public uniswapV2Pair;

  event BuyTax(uint indexed count, uint amount);
  event MintedExp(address indexed sender, bytes32 indexed key, uint amount);
  event DepositExp(address indexed sender, bytes32 indexed key, uint amount);
  event ExternalBurn(address indexed sender, uint amount);

  // prevent loop when _swapTokensForEth is called
  modifier lockTheSwap() {
    _inSwap = true;
    _;
    _inSwap = false;
  }

  // receive ETH from Uniswap
  receive() external payable {
    return;
  }

  function initialize() public initializer {
    __ERC20_init("Exp", "EXP");
    __Ownable_init();
    _signer = 0xBc9eebF48B2B8B54f57d6c56F41882424d632EA7;
    uniDefault = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    buyTaxPercentage = 10;
    sellTaxPercentage = 10;
    toWallet1Percentage = 50;
    toWallet2Percentage = 40;
    toWallet3Percentage = 10;
    durationBetweenClaim = 2 days;
    costToClaim = 10 * 10**18;
    uniswapV2Router = IUniswapV2Router02(uniDefault);

    // setup uniswap pair
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    walletAddress1 = payable(0x1F5652E7f240CC2bA2A99d5cd9AE19E75c1bB32F);
    walletAddress2 = payable(0x41f727E0F74ed199E42cC7af16b56DE0Cb5ecE83);
    walletAddress3 = payable(0x7A2708B9cb7951ddC8f7b800a2a22D035Cc391ae);

    _isExcludedFromTaxes[owner()] = true;
    _isExcludedFromTaxes[address(this)] = true;
    _isExcludedFromTaxes[walletAddress1] = true;
    _isExcludedFromTaxes[walletAddress2] = true;
    _isExcludedFromTaxes[walletAddress3] = true;
  }

  // owner functions
  function setSignerAddress(address adr) external onlyOwner {
    _signer = adr;
  }

  function setWallet1(address payable wallet1) external onlyOwner {
    require(wallet1 != address(0), "Address cannot be null.");
    address _previousWalletAddress = walletAddress1;
    walletAddress1 = wallet1;
    _isExcludedFromTaxes[walletAddress1] = true;
    _isExcludedFromTaxes[_previousWalletAddress] = false;
  }

  function setWallet2(address payable wallet2) external onlyOwner {
    require(wallet2 != address(0), "Address cannot be null.");
    address _previousWalletAddress = walletAddress2;
    walletAddress2 = wallet2;
    _isExcludedFromTaxes[walletAddress2] = true;
    _isExcludedFromTaxes[_previousWalletAddress] = false;
  }

  function setWallet3(address payable wallet3) external onlyOwner {
    require(wallet3 != address(0), "Address cannot be null.");
    address _previousWalletAddress = walletAddress3;
    walletAddress3 = wallet3;
    _isExcludedFromTaxes[walletAddress3] = true;
    _isExcludedFromTaxes[_previousWalletAddress] = false;
  }

  function excludeFromTaxes(address account, bool excluded) external onlyOwner {
    _isExcludedFromTaxes[account] = excluded;
  }

  function setMinimumTokensToSwap(uint amount) external onlyOwner {
    minimumTokensToSwap = amount;
  }

  function setBuyTaxPercentage(uint buyTax) external onlyOwner {
    buyTaxPercentage = buyTax;
  }

  function setSellTaxPercentage(uint sellTax, uint taxTo1, uint taxTo2, uint taxTo3) external onlyOwner {
    require(taxTo1 + taxTo2 + taxTo3 == 100, "Invalid tax total");
    toWallet1Percentage = taxTo1;
    toWallet2Percentage = taxTo2;
    toWallet3Percentage = taxTo3;
    sellTaxPercentage = sellTax;
  }

  function manualSend() external onlyOwner {
    uint contractETHBalance = address(this).balance;
    payable(msg.sender).transfer(contractETHBalance);
  }

  function manualSwapAndWithdraw() external onlyOwner {
    _swapTokensForEth(balanceOf(address(this)));
    uint contractETHBalance = address(this).balance;
    payable(walletAddress1).transfer(toWallet1Percentage * contractETHBalance / 100);
    payable(walletAddress2).transfer(toWallet2Percentage * contractETHBalance / 100);
    payable(walletAddress3).transfer(toWallet3Percentage * contractETHBalance / 100);
  }

  function setDurationBetweenClaim(uint duration) external onlyOwner {
    durationBetweenClaim = duration;
  }

  function setCostToClaim(uint amount) external onlyOwner {
    costToClaim = amount;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  // internal
  function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "ERC20: Amount is less than or equal to zero");
    require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
    _beforeTokenTransfer(sender, recipient, amount);

    // if either recipient or sender is excluded from taxes, set taxed to false
    bool taxed = true;
    if (_isExcludedFromTaxes[sender] || _isExcludedFromTaxes[recipient]) {
      taxed = false;
    }

    bool buy = false;
    if (sender == address(uniswapV2Pair)) {
      buy = true;
    }

    uint amountAfterTax;

    if (!taxed) {
      amountAfterTax = amount;
    } else if (buy) {
      uint buyCut = buyTaxPercentage * amount / 100;
      _burn(sender, buyCut);
      buyTaxCount++;
      emit BuyTax(buyTaxCount, buyCut);
      amountAfterTax = amount - buyCut;

    } else {
      uint sellCut = sellTaxPercentage * amount / 100;
      _balances[sender] -= sellCut;
      _balances[address(this)] += sellCut;
      emit Transfer(sender, address(this), sellCut);

      // if not currently in a swap, swap tokens to ETH and distribute the ETH to 3 wallets
      if (!_inSwap && _balances[address(this)] >= minimumTokensToSwap) {
        _swapTokensForEth(_balances[address(this)]);
      }
      uint contractETHBalance = address(this).balance;
      if (contractETHBalance > 0) {
        payable(walletAddress1).transfer(contractETHBalance * toWallet1Percentage / 100);
        payable(walletAddress2).transfer(contractETHBalance * toWallet2Percentage / 100);
        payable(walletAddress3).transfer(contractETHBalance * toWallet3Percentage / 100);
      }

      amountAfterTax = amount - sellCut;
    }

    // transfer
    _balances[sender] -= amountAfterTax;
    _balances[recipient] += amountAfterTax;    
    emit Transfer(sender, recipient, amountAfterTax);
    // _afterTokenTransfer(sender, recipient, amountAfterTax);
  }

  function _swapTokensForEth(uint tokenAmount) private lockTheSwap {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC20Upgradeable, ERC20PausableUpgradeable) {
    // super._beforeTokenTransfer(from, to, tokenId);
  }

  // public
  // withdraw tokens from backend
  function createInternetCoin(bytes32 key, bytes calldata signature, uint amount, uint timestamp) external whenNotPaused {
    require(block.timestamp - lastClaimed[msg.sender] > durationBetweenClaim, "Cooldown is not finished");
    require(amount > costToClaim, "ERC20: Amount is smaller than claim cost");
    require(!_usedKey[key], "Key has been used");
    require(block.timestamp < timestamp, "Expired claim time");
    require(keccak256(abi.encode(msg.sender, "ERC20-EXP", amount, timestamp, key)).toEthSignedMessageHash().recover(signature) == _signer, "Invalid signature");
    _mint(msg.sender, amount - costToClaim);
    _usedKey[key] = true;
    lastClaimed[msg.sender] = block.timestamp;
    emit MintedExp(msg.sender, key, amount - costToClaim);
  }

  // deposit tokens to backend
  function depositInternetCoin(bytes32 key, bytes calldata signature, uint amount, uint timestamp) external whenNotPaused {
    require(amount > 0, "ERC20: Amount is less than or equal to zero");
    require(!_usedKey[key], "Key has been used");
    require(block.timestamp < timestamp, "Expired deposit time");
    require(keccak256(abi.encode(msg.sender, "ERC20-EXP-BURN", amount, timestamp, key)).toEthSignedMessageHash().recover(signature) == _signer, "Invalid signature");
    _burn(msg.sender, amount);    
    _usedKey[key] = true;
    emit DepositExp(msg.sender, key, amount);
  }

  // external function if other contract needs to burn EXP as their additional utility
  function burn(address tokenOwner, uint amount) external whenNotPaused {
    require(msg.sender == tokenOwner || allowance(tokenOwner, msg.sender) >= amount, "Not enough allowances");
    if (msg.sender != tokenOwner) {
      _approve(tokenOwner, msg.sender, _allowances[tokenOwner][msg.sender] - amount);
    }
    _burn(tokenOwner, amount);
    emit ExternalBurn(tokenOwner, amount);
  }

  // view
  function isExcludedFromTaxes(address account) public view returns (bool) {
    return _isExcludedFromTaxes[account];
  }

}