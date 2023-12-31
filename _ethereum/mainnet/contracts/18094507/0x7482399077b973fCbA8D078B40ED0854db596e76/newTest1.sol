// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./Utils.sol";

contract NewTest1 is Context, IERC20, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _rewards;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcludedFromMaxTx;

  mapping(address => bool) public isBlacklisted;
  mapping(address => uint256) public nextAvailableClaimDate;

  uint256 private _totalSupply = 100000000 * 10 ** 18;
  uint8 private _decimals = 18;
  string private _name = "NewTest1";
  string private _symbol = "NEWTEST1";

  uint256 public rewardCycleBlock = 7 days;
  uint256 public easyRewardCycleBlock = 1 days;
  uint256 public threshHoldTopUpRate = 2; // 2 percent
  uint256 public _maxTxAmount = _totalSupply; // should be 0.05% percent per transaction, will be set again at activateContract() function
  uint256 public disableEasyRewardFrom = 0;
  uint256 public totalETHClaimed = 0;

  bool public tradingEnabled = false;

  IUniswapV2Router02 public immutable uniswapV2Router;

  address public immutable uniswapV2Pair;
  address public marketingAddress;

  Taxes public taxes;
  Taxes public sellTaxes;

  uint256 private _totalMarketing;
  uint256 private _totalReward;

  struct Taxes {
    uint256 marketing;
    uint256 reward;
  }

  event ClaimETHSuccessfully(
    address recipient,
    uint256 ethReceived,
    uint256 nextAvailableClaimDate
  );

  constructor(address payable routerAddress) {
    _balances[_msgSender()] = _totalSupply;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
    // Create a uniswap v2 pair for this new token
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uniswapV2Router = _uniswapV2Router;

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    _isExcludedFromMaxTx[owner()] = true;
    _isExcludedFromMaxTx[address(this)] = true;
    _isExcludedFromMaxTx[
      address(0x000000000000000000000000000000000000dEaD)
    ] = true;
    _isExcludedFromMaxTx[address(0)] = true;

    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function allowance(
    address owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  function transfer(
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function _transfer(address from, address to, uint256 amount) private {
    require(!isBlacklisted[from], "Sender is blacklisted");
    require(!isBlacklisted[to], "Recipient is blacklisted");
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
      require(tradingEnabled, "Trading is not enabled yet");
    }
    if (!_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to]) {
      require(
        amount <= _maxTxAmount,
        "Transfer amount exceeds the maxTxAmount."
      );
    }
    //indicates if fee should be deducted from transfer
    bool takeFee = true;
    bool isSell = to == uniswapV2Pair;
    bool isSwapping = (to == uniswapV2Pair || from == uniswapV2Pair);
    uint256 tMarketing = calculateTaxFee(
      amount,
      isSell ? sellTaxes.marketing : taxes.marketing
    );
    uint256 tReward = calculateTaxFee(
      amount,
      isSell ? sellTaxes.reward : taxes.reward
    );

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
      tMarketing = 0;
      tReward = 0;
    }
    if (tMarketing != 0 || tReward != 0) {
      _tokenTransfer(from, address(this), tMarketing.add(tReward));
      _totalReward = _totalReward.add(tReward);
      _totalMarketing = _totalMarketing.add(tMarketing);
    }

    _tokenTransfer(from, to, amount.sub(tMarketing).sub(tReward));

    uint256 contractTokenBalance = balanceOf(address(this));
    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    if (takeFee && marketingAddress != address(0) && !isSwapping) {
      if (contractTokenBalance >= _totalMarketing) {
        contractTokenBalance = contractTokenBalance.sub(_totalMarketing);
        Utils.swapTokensForEth(
          address(uniswapV2Router),
          _totalMarketing,
          marketingAddress
        );
        _totalMarketing = 0;
      }
    }
    if (takeFee && !isSwapping) {
      if (contractTokenBalance >= _totalReward) {
        _takeReward(_totalReward, from);
        _totalReward = 0;
      }
    }
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    topUpClaimCycleAfterTransfer(recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function topUpClaimCycleAfterTransfer(
    address recipient,
    uint256 amount
  ) private {
    uint256 currentRecipientBalance = balanceOf(recipient);
    uint256 basedRewardCycleBlock = getRewardCycleBlock();

    nextAvailableClaimDate[recipient] =
      nextAvailableClaimDate[recipient] +
      Utils.calculateTopUpClaim(
        currentRecipientBalance,
        basedRewardCycleBlock,
        threshHoldTopUpRate,
        amount
      );
  }

  function _takeReward(uint256 reward, address taker) private {
    uint256 initialBalance = address(this).balance;
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      reward,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp + 20 * 60
    );

    uint256 deltaBalance = address(this).balance.sub(initialBalance);
    _rewards[taker] = _rewards[taker].add(
      deltaBalance.mul(balanceOf(taker)).div(totalSupply())
    );
  }

  function calculateTaxFee(
    uint256 _amount,
    uint256 _fee
  ) private pure returns (uint256) {
    return _amount.mul(_fee).div(10 ** 2);
  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function calculateETHReward(address ofAddress) public view returns (uint256) {
    return
      Utils.calculateETHReward(
        balanceOf(ofAddress),
        address(this).balance,
        totalSupply()
      );
  }

  function getRewardCycleBlock() public view returns (uint256) {
    if (block.timestamp >= disableEasyRewardFrom) return rewardCycleBlock;
    return easyRewardCycleBlock;
  }

  function claimETHReward() public nonReentrant {
    require(tx.origin == msg.sender, "sorry humans only");
    require(
      nextAvailableClaimDate[msg.sender] <= block.timestamp,
      "Error: next available not reached"
    );
    require(
      balanceOf(msg.sender) >= 0,
      "Error: must own Token to claim reward"
    );

    uint256 reward = calculateETHReward(msg.sender);

    // update rewardCycleBlock
    nextAvailableClaimDate[msg.sender] =
      block.timestamp +
      getRewardCycleBlock();

    emit ClaimETHSuccessfully(
      msg.sender,
      reward,
      nextAvailableClaimDate[msg.sender]
    );

    totalETHClaimed = totalETHClaimed.add(reward);
    (bool sent, ) = address(msg.sender).call{value: reward}("");
    require(sent, "Error: Cannot withdraw reward");
  }

  function addToBlacklist(address account) external onlyOwner {
    isBlacklisted[account] = true;
  }

  function removeFromBlacklist(address account) external onlyOwner {
    isBlacklisted[account] = false;
  }

  function setExcludeFromMaxTx(address _address, bool value) public onlyOwner {
    _isExcludedFromMaxTx[_address] = value;
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
    _maxTxAmount = _totalSupply.mul(maxTxPercent).div(10000);
  }

  function setBuyFeePercents(
    uint256 marketingFee,
    uint256 rewardFee
  ) external onlyOwner {
    taxes.marketing = marketingFee;
    taxes.reward = rewardFee;
  }

  function setSellFeePercents(
    uint256 marketingFee,
    uint256 rewardFee
  ) external onlyOwner {
    sellTaxes.marketing = marketingFee;
    sellTaxes.reward = rewardFee;
  }

  function setMarketingWallet(address marketingWallet) external onlyOwner {
    marketingAddress = marketingWallet;
  }

  function activateContract() public onlyOwner {
    // reward claim
    disableEasyRewardFrom = block.timestamp + 1 weeks;
    rewardCycleBlock = 7 days;
    easyRewardCycleBlock = 1 days;

    tradingEnabled = true;

    setMaxTxPercent(200);

    taxes.marketing = 1;
    taxes.reward = 1;

    sellTaxes.marketing = 1;
    sellTaxes.reward = 1;

    // approve contract
    _approve(address(this), address(uniswapV2Router), 2 ** 256 - 1);
  }

  receive() external payable {
    // To receive ETH from UniswapV2Router when swapping
  }
}
