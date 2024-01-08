// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/**
 * @title MCCSwap
 * @dev Swap MCC for ETH/OKLG on ETH
 */
contract MCCSwap is Ownable {
  IERC20 private mccV1 = IERC20(0x1a7981D87E3b6a95c1516EB820E223fE979896b3);
  IERC20 private mccV2 = IERC20(0x1454232149A0dC51e612b471fE6d3393e60D09Ad);
  IERC20 private mccV3 = IERC20(0x1454232149A0dC51e612b471fE6d3393e60D09Ad);

  AggregatorV3Interface internal priceFeed;

  mapping(address => bool) public v1WasSwapped;
  mapping(address => uint256) public v1SnapshotBalances;
  mapping(address => bool) public v2WasSwapped;
  mapping(address => uint256) public v2AirdropAmounts;
  mapping(address => uint256) public v2SnapshotBalances;

  uint256 public v2AirdropETHPool;
  uint256 public v2TotalAirdropped = 842714586113970000000;

  /**
   * Aggregator: ETH/USD
   */
  constructor() {
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    priceFeed = AggregatorV3Interface(
      0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
  }

  function swap() external {
    swapV1ForV3();
    swapV2ForETH();
  }

  function swapV1ForV3() public {
    require(!v1WasSwapped[msg.sender], 'already swapped V1 for V3');

    uint256 _amountV3ToReceive = v1SnapshotBalances[msg.sender];
    require(_amountV3ToReceive > 0, 'you did not have any V1 tokens');
    require(
      mccV3.balanceOf(address(this)) >= _amountV3ToReceive,
      'not enough V3 liquidity to complete swap'
    );
    v1WasSwapped[msg.sender] = true;
    mccV3.transfer(msg.sender, _amountV3ToReceive);
  }

  function swapV2ForETH() public {
    require(!v2WasSwapped[msg.sender], 'already swapped V2 for ETH');

    // 1. check and compensate for airdropped V2 tokens
    uint256 mccV2AirdroppedAmount = v2AirdropAmounts[msg.sender];
    if (mccV2AirdroppedAmount > 0) {
      msg.sender.call{
        value: (v2AirdropETHPool * mccV2AirdroppedAmount) / v2TotalAirdropped
      }('');
    }

    // 2. check and compensate for currently held V2 tokens
    uint256 mccV2Balance = mccV2.balanceOf(msg.sender);
    if (mccV2Balance > 0) {
      mccV2.transferFrom(msg.sender, address(this), mccV2Balance);
    }

    uint256 mccV2SnapshotBal = v2SnapshotBalances[msg.sender];
    if (mccV2SnapshotBal > 0) {
      uint256 weiToTransfer = getUserOwedETHFromV2(mccV2SnapshotBal);
      require(
        address(this).balance >= weiToTransfer,
        'not enough ETH liquidity to execute swap'
      );
      msg.sender.call{ value: weiToTransfer }('');
    }

    v2WasSwapped[msg.sender] = true;
  }

  function getUserOwedETHFromV2(uint256 v2Balance)
    public
    view
    returns (uint256)
  {
    // Creates a USD balance with 18 decimals
    // MCC has 9 decimals, so need to add 9 decimals to get USD balance to 18
    // Refund Rate = MCC * $0.00000825 * 30%
    uint256 balanceInUSD = (((v2Balance * 10**9 * 825) / 10**8) * 3) / 10;

    // adding back 18 decimals to get returned value in wei
    return (10**18 * balanceInUSD) / getLatestETHPrice();
  }

  /**
   * Returns the latest ETH/USD price with returned value at 18 decimals
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function getLatestETHPrice() public view returns (uint256) {
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price) * (10**18 / 10**decimals);
  }

  function setV1WasSwapped(address _wallet, bool _didSwap) external onlyOwner {
    v1WasSwapped[_wallet] = _didSwap;
  }

  function setV2WasSwapped(address _wallet, bool _didSwap) external onlyOwner {
    v2WasSwapped[_wallet] = _didSwap;
  }

  function addETHToV2AirdropPool() external payable onlyOwner {
    require(msg.value > 0, 'must sent some ETH to add to pool');
    v2AirdropETHPool += msg.value;
    payable(address(this)).call{ value: msg.value }('');
  }

  function removeETHFromV2AirdropPool() external onlyOwner {
    require(v2AirdropETHPool > 0, 'Need ETH in the pool to remove it');

    uint256 _finalAmount = address(this).balance < v2AirdropETHPool
      ? address(this).balance
      : v2AirdropETHPool;
    if (_finalAmount > 0) {
      payable(owner()).call{ value: _finalAmount }('');
    }
    v2AirdropETHPool = 0;
  }

  function seedV1Balances(address[] memory _wallets, uint256[] memory _amounts)
    external
    onlyOwner
  {
    require(
      _wallets.length == _amounts.length,
      'must be same number of wallets and amounts'
    );
    for (uint256 _i = 0; _i < _wallets.length; _i++) {
      v1SnapshotBalances[_wallets[_i]] = _amounts[_i];
    }
  }

  function seedV2AirdropAmounts(
    address[] memory _wallets,
    uint256[] memory _amounts
  ) external onlyOwner {
    require(
      _wallets.length == _amounts.length,
      'must be same number of wallets and amounts'
    );
    for (uint256 _i = 0; _i < _wallets.length; _i++) {
      v2AirdropAmounts[_wallets[_i]] = _amounts[_i];
    }
  }

  function seedV2Balances(address[] memory _wallets, uint256[] memory _amounts)
    external
    onlyOwner
  {
    require(
      _wallets.length == _amounts.length,
      'must be same number of wallets and amounts'
    );
    for (uint256 _i = 0; _i < _wallets.length; _i++) {
      v2SnapshotBalances[_wallets[_i]] = _amounts[_i];
    }
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH(uint256 _amount) external onlyOwner {
    _amount = _amount > 0 ? _amount : address(this).balance;
    require(_amount > 0, 'make sure there is ETH available to withdraw');
    payable(owner()).send(_amount);
  }

  function setMCCV3(address v3) external onlyOwner {
    mccV3 = IERC20(v3);
  }

  // to recieve ETH from external wallets
  receive() external payable {}
}
