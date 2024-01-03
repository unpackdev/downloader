// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";

import "./UniswapV2Library.sol";

import "./IFeeSplitter.sol";
import "./ILockedLiquidityEvent.sol";
import "./ITDAO.sol";

contract FeeController {
  using SafeMath for uint256;

  address public pairWETH;
  address public pairWBTC;
  address public pairUSDC;
  address public pairMUSD;
  address public pairTRI;
  address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public MUSD = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
  address public TRI = 0xc299004a310303D1C0005Cb14c70ccC02863924d;

  address public pair;
  address public tdao;
  address public feeSplitter;
  address public lle;

  uint256 public fee = 100; // max 1000 = 10% artificial clamp
  uint256 public constant BASE = 10000; // fee/base => 100/10000 => 0.01 => 1.0%

  mapping(address => bool) private _noFeeList;
  mapping(address => bool) private _blockList;

  modifier onlyTDAO() {
    require(msg.sender == tdao, 'FeeController: Function call not allowed.');
    _;
  }

  constructor(
    address _tdao,
    address _addressTokenB,
    address _addressFactory,
    address _feeSplitter
  ) public {
    tdao = _tdao;
    pair = IUniswapV2Factory(_addressFactory).getPair(_addressTokenB, tdao);
    feeSplitter = _feeSplitter;
    lle = address(ITDAO(tdao).lockedLiquidityEvent());
    require(
      lle != address(0),
      'FeeController: Must first deploy and set LockedLiquidityEvent'
    );

    pairWETH = UniswapV2Library.pairFor(_addressFactory, WETH, tdao);
    pairWBTC = UniswapV2Library.pairFor(_addressFactory, WBTC, tdao);
    pairUSDC = UniswapV2Library.pairFor(_addressFactory, USDC, tdao);
    pairMUSD = UniswapV2Library.pairFor(_addressFactory, MUSD, tdao);
    pairTRI = UniswapV2Library.pairFor(_addressFactory, TRI, tdao);

    _editNoFeeList(pairWETH, true);
    _editNoFeeList(pairWBTC, true);
    _editNoFeeList(pairUSDC, true);
    _editNoFeeList(pairMUSD, true);
    _editNoFeeList(pairTRI, true);
    _editNoFeeList(pair, true);

    _editNoFeeList(lle, true);
    _editNoFeeList(feeSplitter, true);
    _editNoFeeList(_treasuryVault(), true);

    _editNoFeeList(IFeeSplitter(feeSplitter).nftRewardsVault(), true);
    _editNoFeeList(IFeeSplitter(feeSplitter).trigRewardsVault(), true);
  }

  function isPaused() external view returns (bool) {
    return _isPaused();
  }

  function isFeeless(address account) external view returns (bool) {
    return _noFeeList[account];
  }

  function isBlocked(address account) external view returns (bool) {
    return _blockList[account];
  }

  function setFee(uint256 _fee) external onlyTDAO {
    require(
      _fee >= 10 && _fee <= 1000,
      'FeeController: Fee must be in between 10 and 1000'
    );
    fee = _fee;
  }

  function editNoFeeList(address _address, bool _noFee) external onlyTDAO {
    require(
      _address != feeSplitter,
      'FeeController: Cannot charge fees to fee splitter.'
    );
    require(
      _address != _treasuryVault(),
      'FeeController: Cannot charge fees to treasury.'
    );
    require(
      _address != IFeeSplitter(feeSplitter).nftRewardsVault(),
      'FeeController: Cannot charge fees to NFT reward vault.'
    );
    require(
      _address != IFeeSplitter(feeSplitter).trigRewardsVault(),
      'FeeController: Cannot charge fees to Trig reward vault.'
    );

    _editNoFeeList(_address, _noFee);
  }

  function editBlockList(address _address, bool _block) external onlyTDAO {
    require(_address != pair, 'FeeController: Cannot block main Uniswap pair.');
    require(
      _address != _treasuryVault(),
      'FeeController: Cannot block treasury.'
    );
    require(
      _address != feeSplitter,
      'FeeController: Cannot block fee splitter.'
    );
    require(
      _address != IFeeSplitter(feeSplitter).nftRewardsVault(),
      'FeeController: Cannot block NFT reward vault.'
    );
    require(
      _address != IFeeSplitter(feeSplitter).trigRewardsVault(),
      'FeeController: Cannot block Trig reward vault.'
    );

    _editBlockList(_address, _block);
  }

  function applyFee(
    address sender,
    address recipient,
    uint256 amount
  )
    external
    view
    returns (uint256 transferToRecipientAmount, uint256 transferToFeeAmount)
  {
    require(!_blockList[sender], 'FeeController: Sender account is blocked.');
    require(
      !_blockList[recipient],
      'FeeController: Recipient account is blocked.'
    );

    if (recipient != pair) {
      require(!_isPaused(), 'FeeController: Trading has not started.');
    }

    if (_noFeeList[sender]) {
      // Do not charge a fee when vault is sending. Avoid infinite loop.
      // Do not charge a fee when pair is sending. No fees on buy.
      transferToFeeAmount = 0;
      transferToRecipientAmount = amount;
    } else {
      transferToFeeAmount = amount.mul(fee).div(BASE);
      transferToRecipientAmount = amount.sub(transferToFeeAmount);
    }
  }

  function _treasuryVault() internal view returns (address) {
    return IFeeSplitter(feeSplitter).treasuryVault();
  }

  function _isPaused() internal view returns (bool) {
    return block.timestamp < ILockedLiquidityEvent(lle).startTradingTime();
  }

  function _editNoFeeList(address _address, bool _noFee) internal {
    _noFeeList[_address] = _noFee;
  }

  function _editBlockList(address _address, bool _block) internal {
    _blockList[_address] = _block;
  }
}
