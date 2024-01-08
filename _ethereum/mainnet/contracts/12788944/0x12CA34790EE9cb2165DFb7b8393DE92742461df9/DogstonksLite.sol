// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

/**
 * @notice ERC20 token with cost basis tracking and restricted loss-taking
 */
contract DogstonksLite is ERC20 {
  using Address for address payable;

  enum Phase { PENDING, OPEN, CLOSED }

  uint private immutable INITIAL_LIQUIDITY;

  Phase public _phase;
  uint public _phaseChangedAt;

  address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private immutable WETH;

  uint private constant SUPPLY = 1e12 ether;

  // rates defined as amount needed in addition to sale amount
  uint private constant TAX_RATE_ITM = 2500;
  uint private constant TAX_RATE_OTM = 10000;
  uint private constant BP_DIVISOR = 10000;

  address private _owner;
  address private _pair;

  mapping (address => uint) public basisOf;
  mapping (address => uint) public cooldownOf;

  // all time high
  uint private _ath;
  uint private _athTimestamp;

  // values to prevent adding liquidity directly
  address private _lastOrigin;
  uint private _lastBlock;

  struct Minting {
    address recipient;
    uint amount;
  }

  modifier phase (Phase p) {
    require(_phase == p, 'ERR: invalid phase');
    _;
  }

  /**
   * @notice deploy
   */
  constructor () payable ERC20('DogstonksLite (dogstonks.com)', 'DOGLITE') {
    _owner = msg.sender;
    _phaseChangedAt = block.timestamp;

    INITIAL_LIQUIDITY = msg.value - 1;

    address weth = IUniswapV2Router02(UNISWAP_ROUTER).WETH();
    WETH = weth;

    // setup uniswap pair and store address

    _pair = IUniswapV2Factory(
      IUniswapV2Router02(UNISWAP_ROUTER).factory()
    ).createPair(weth, address(this));

    // prepare to add/remove liquidity

    _approve(address(this), UNISWAP_ROUTER, type(uint).max);
    IERC20(_pair).approve(UNISWAP_ROUTER, type(uint).max);
  }

  receive () external payable {}

  /**
   * @inheritdoc ERC20
   * @dev reverts if Uniswap pair holds more WETH than accounted for in reserves (suggesting liquidity is being added)
   */
  function balanceOf (
    address account
  ) override public view returns (uint) {
    if (msg.sender == _pair && tx.origin == _lastOrigin && block.number == _lastBlock) {
      (uint res0, uint res1, ) = IUniswapV2Pair(_pair).getReserves();
      require(
        (address(this) > WETH ? res0 : res1) > IERC20(WETH).balanceOf(_pair),
        'ERR: liquidity add'
      );
    }
    return super.balanceOf(account);
  }

  /**
   * @notice calculate current cost basis for sale of given quantity of tokens
   * @param amount quantity of tokens sold
   * @return cost basis for sale
   */
  function basisOfSale (
    uint amount
  ) public view returns (uint) {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = WETH;

    uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(
      amount,
      path
    );

    return (1 ether) * amounts[1] / amount;
  }

  /**
   * @notice calculate tax for given cost bases and sale amount
   * @param fromBasis cost basis of seller
   * @param toBasis cost basis for sale
   * @param amount quantity of tokens sold
   * @return tax amount
   */
  function taxFor (
    uint fromBasis,
    uint toBasis,
    uint amount
  ) public pure returns (uint) {
    return amount * (toBasis >= fromBasis ? TAX_RATE_ITM : TAX_RATE_OTM) / BP_DIVISOR;
  }

  /**
   * @notice open trading
   * @dev sender must be owner
   * @dev trading must not yet have been opened
   */
  function open () external phase(Phase.PENDING) {
    require(msg.sender == _owner, 'ERR: sender must be owner');

    _incrementPhase();

    // add liquidity

    _mint(address(this), SUPPLY);

    IUniswapV2Router02(
      UNISWAP_ROUTER
    ).addLiquidityETH{
      value: address(this).balance
    }(
      address(this),
      balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );

    // prevent close before first trade takes place

    _athTimestamp = block.timestamp;
  }

  /**
   * @notice close trading
   * @dev trading must not yet have been closed
   * @dev minimum time since open must have elapsed
   */
  function close () external phase(Phase.OPEN) {
    require(
      block.timestamp > _athTimestamp + (1 weeks),
      'ERR: recent ATH'
    );

    _incrementPhase();

    uint univ2 = IERC20(_pair).balanceOf(address(this));

    (uint amountToken, ) = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).removeLiquidityETH(
      address(this),
      univ2,
      0,
      0,
      address(this),
      block.timestamp
    );

    _burn(address(this), amountToken);

    payable(_owner).sendValue(INITIAL_LIQUIDITY);
  }

  /**
   * @notice exchange DOGLITE for proportion of ETH in contract
   * @dev trading must have been closed
   */
  function liquidate () external phase(Phase.CLOSED) {
    uint balance = balanceOf(msg.sender);

    require(balance != 0, 'ERR: zero balance');

    uint payout = address(this).balance * balance / totalSupply();

    _burn(msg.sender, balance);
    payable(msg.sender).sendValue(payout);
  }

  /**
   * @notice withdraw remaining ETH from contract
   * @dev trading must have been closed
   * @dev minimum time since close must have elapsed
   */
  function liquidateUnclaimed () external phase(Phase.CLOSED) {
    require(block.timestamp > _phaseChangedAt + (52 weeks), 'ERR: too soon');
    payable(_owner).sendValue(address(this).balance);
  }

  /**
   * @notice update contract phase and track timestamp
   */
  function _incrementPhase () private {
    _phase = Phase(uint8(_phase) + 1);
    _phaseChangedAt = block.timestamp;
  }

  /**
   * @notice ERC20 hook: enforce transfer restrictions and cost basis; collect tax
   * @param from tranfer sender
   * @param to transfer recipient
   * @param amount quantity of tokens transferred
   */
  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) override internal {
    super._beforeTokenTransfer(from, to, amount);

    // ignore minting and burning
    if (from == address(0) || to == address(0)) return;

    // ignore add/remove liquidity
    if (from == address(this) || to == address(this)) return;
    if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

    require(uint8(_phase) >= uint8(Phase.OPEN));

    require(
      msg.sender == UNISWAP_ROUTER || msg.sender == _pair,
      'ERR: sender must be uniswap'
    );

    require(amount <= 5e9 ether /* revert message not returned by Uniswap */);

    if (from == _pair) {
      require(cooldownOf[to] < block.timestamp /* revert message not returned by Uniswap */);
      cooldownOf[to] = block.timestamp + (5 minutes);

      address[] memory path = new address[](2);
      path[0] = WETH;
      path[1] = address(this);

      uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsIn(
        amount,
        path
      );

      uint balance = balanceOf(to);
      uint fromBasis = (1 ether) * amounts[0] / amount;
      basisOf[to] = (fromBasis * amount + basisOf[to] * balance) / (amount + balance);

      if (fromBasis > _ath) {
        _ath = fromBasis;
        _athTimestamp = block.timestamp;
      }
    } else if (to == _pair) {
      _lastOrigin = tx.origin;
      _lastBlock = block.number;

      require(cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */);
      cooldownOf[from] = block.timestamp + (5 minutes);

      uint fromBasis = basisOf[from];
      uint toBasis = basisOfSale(amount);

      // collect tax
      _burn(from, taxFor(fromBasis, toBasis, amount));
    }
  }
}
