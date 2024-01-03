// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./FixedPoint.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./UniswapV2OracleLibrary.sol";

import "./IJusDeFi.sol";
import "./IStakingPool.sol";
import "./IJDFIStakingPool.sol";
import "./FeePool.sol";
import "./DevStakingPool.sol";
import "./JDFIStakingPool.sol";
import "./UNIV2StakingPool.sol";

contract JusDeFi is IJusDeFi, ERC20 {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;
  using SafeMath for uint;

  // _weth and _uniswapPair cannot be immutable because they are referenced in _beforeTokenTransfer
  address private _weth;
  address private immutable _uniswapRouter;
  address public _uniswapPair;

  address payable override public _feePool;
  address public immutable _devStakingPool;
  address public immutable _jdfiStakingPool;
  address public immutable _univ2StakingPool;

  uint private constant LIQUIDITY_EVENT_PERIOD = 3 days;
  bool public _liquidityEventOpen;
  uint public immutable _liquidityEventClosedAt;

  mapping (address => bool) private _implicitApprovalWhitelist;

  uint private constant RESERVE_TEAM = 1980 ether;
  uint private constant RESERVE_JUSTICE = 10020 ether;
  uint private constant RESERVE_LIQUIDITY_EVENT = 10000 ether;
  uint private constant REWARDS_SEED = 2000 ether;

  uint private constant JDFI_PER_ETH = 4;

  uint private constant ORACLE_PERIOD = 5 minutes;

  FixedPoint.uq112x112 private _priceAverage;
  uint private _priceCumulativeLast;
  uint32 private _blockTimestampLast;

  constructor (
    address airdropToken,
    address uniswapRouter
  )
    ERC20('JusDeFi', 'JDFI')
  {
    address weth = IUniswapV2Router02(uniswapRouter).WETH();
    _weth = weth;

    address uniswapPair = IUniswapV2Factory(
      IUniswapV2Router02(uniswapRouter).factory()
    ).createPair(weth, address(this));

    _uniswapRouter = uniswapRouter;
    _uniswapPair = uniswapPair;

    address devStakingPool = address(new DevStakingPool(weth));
    _devStakingPool = devStakingPool;
    address jdfiStakingPool = address(new JDFIStakingPool(airdropToken, RESERVE_LIQUIDITY_EVENT, weth, devStakingPool));
    _jdfiStakingPool = jdfiStakingPool;
    address univ2StakingPool = address(new UNIV2StakingPool(uniswapPair, uniswapRouter));
    _univ2StakingPool = univ2StakingPool;

    // mint staked JDFI after-the-fact to match minted JDFI/S
    _mint(jdfiStakingPool, RESERVE_LIQUIDITY_EVENT);

    // mint JDFI for conversion to locked JDFI/S
    _mint(airdropToken, RESERVE_JUSTICE);

    // mint team JDFI
    _mint(msg.sender, RESERVE_TEAM);

    // transfer all minted JDFI/E to sender
    IStakingPool(devStakingPool).transfer(msg.sender, IStakingPool(devStakingPool).balanceOf(address(this)));

    _liquidityEventClosedAt = block.timestamp + LIQUIDITY_EVENT_PERIOD;
    _liquidityEventOpen = true;

    // enable trusted addresses to transfer tokens without approval
    _implicitApprovalWhitelist[jdfiStakingPool] = true;
    _implicitApprovalWhitelist[univ2StakingPool] = true;
    _implicitApprovalWhitelist[uniswapRouter] = true;
  }

  /**
   * @notice get average JDFI price over the last ORACLE_PERIOD
   * @dev adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
   * @param amount quantity of ETH used for purchase
   * @return uint quantity of JDFI purchased, or zero if ORACLE_PERIOD has passed since las tupdate
   */
  function consult (uint amount) override external view returns (uint) {
    if (block.timestamp - uint(_blockTimestampLast) > ORACLE_PERIOD) {
      return 0;
    } else {
      return _priceAverage.mul(amount).decode144();
    }
  }

  /**
   * @notice OpenZeppelin ERC20#transferFrom: enable transfers by staking pools without allowance
   * @param from sender
   * @param to recipient
   * @param amount quantity transferred
   */
  function transferFrom (address from, address to, uint amount) override(IERC20, ERC20) public returns (bool) {
    if (_implicitApprovalWhitelist[msg.sender]) {
      _transfer(from, to, amount);
      return true;
    } else {
      return super.transferFrom(from, to, amount);
    }
  }

  /**
   * @notice burn tokens held by sender
   * @param amount quantity of tokens to burn
   */
  function burn (uint amount) override external {
    _burn(msg.sender, amount);
  }

  /**
   * @notice transfer tokens, deducting fee
   * @param account recipient of transfer
   * @param amount quantity of tokens to transfer, before deduction
   */
  function burnAndTransfer (address account, uint amount) override external {
    uint withheld = FeePool(_feePool).calculateWithholding(amount);
    _transfer(msg.sender, _feePool, withheld);
    _burn(_feePool, withheld / 2);
    _transfer(msg.sender, account, amount - withheld);
  }

  /**
   * @notice deposit ETH to receive JDFI/S at rate of 1:4
   */
  function liquidityEventDeposit () external payable {
    require(_liquidityEventOpen, 'JusDeFi: liquidity event has closed');

    try IStakingPool(_jdfiStakingPool).transfer(msg.sender, msg.value * JDFI_PER_ETH) returns (bool) {} catch {
      revert('JusDeFi: deposit amount surpasses available supply');
    }
  }

  /**
   * @notice close liquidity event, add Uniswap liquidity, burn undistributed JDFI
   */
  function liquidityEventClose () external {
    require(block.timestamp >= _liquidityEventClosedAt, 'JusDeFi: liquidity event still in progress');
    require(_liquidityEventOpen, 'JusDeFi: liquidity event has already ended');
    _liquidityEventOpen = false;

    uint remaining = IStakingPool(_jdfiStakingPool).balanceOf(address(this));
    uint distributed = RESERVE_LIQUIDITY_EVENT - remaining;

    // require minimum deposit to avoid nonspecific Uniswap error: ds-math-sub-underflow
    require(distributed >= 1 ether, 'JusDeFi: insufficient liquidity added');

    // prepare Uniswap for minting my FeePool
    IUniswapV2Pair pair = IUniswapV2Pair(_uniswapPair);

    address weth = _weth;
    IWETH(weth).deposit{ value: distributed / JDFI_PER_ETH }();
    IWETH(weth).transfer(address(pair), distributed / JDFI_PER_ETH);
    _mint(address(pair), distributed);

    _feePool = payable(new FeePool(
      _jdfiStakingPool,
      _univ2StakingPool,
      _uniswapRouter,
      _uniswapPair
    ));

    // UNI-V2 has been minted, so price is available
    _priceCumulativeLast =  address(this) > _weth ? pair.price0CumulativeLast() : pair.price1CumulativeLast();
    _blockTimestampLast = UniswapV2OracleLibrary.currentBlockTimestamp();

    // unstake and burn (including fee accrued on unstaking)
    IJDFIStakingPool(_jdfiStakingPool).unstake(remaining);
    _burn(address(this), balanceOf(address(this)));
    _burn(_feePool, balanceOf(_feePool));

    // seed staking pools
    _mint(_feePool, REWARDS_SEED);
  }

  /**
   * @notice OpenZeppelin ERC20 hook: prevent transfers during liquidity event, update oracle price
   * @dev adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
   * @param from sender
   * @param to recipient
   * @param amount quantity transferred
   */
  function _beforeTokenTransfer (address from, address to, uint amount) override internal {
    require(!_liquidityEventOpen, 'JusDeFi: liquidity event still in progress');
    super._beforeTokenTransfer(from, to, amount);

    address pair = _uniswapPair;

    if (from == pair || (to == pair && from != address(0))) {
      (
        uint price0Cumulative,
        uint price1Cumulative,
        uint32 blockTimestamp
      ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);

      uint32 timeElapsed = blockTimestamp - _blockTimestampLast; // overflow is desired

      // only store the ETH -> JDFI price
      uint priceCumulative = address(this) > _weth ? price0Cumulative : price1Cumulative;

      if (timeElapsed >= ORACLE_PERIOD) {
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        _priceAverage = FixedPoint.uq112x112(uint224((priceCumulative - _priceCumulativeLast) / timeElapsed));

        _priceCumulativeLast = priceCumulative;
        _blockTimestampLast = blockTimestamp;
      }
    }
  }
}
