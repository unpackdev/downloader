// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20.sol";
import "./StakingPool.sol";

/**
 * @notice ERC20 token with cost basis tracking and restricted loss-taking
 */
contract DogstonksPro is ERC20, StakingPool {
  using Address for address payable;

  enum Phase { PENDING, LIQUIDITY_EVENT, OPEN, CLOSED }

  Phase public _phase;
  uint public _phaseChangedAt;

  string public override name = 'DogstonksPro (dogstonks.com)';
  string public override symbol = 'DOGPRO';

  address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private constant DOGSTONKS = 0xC9aA1007b1619d04C1911E48A8a7a95770BE21a2;

  uint private constant SUPPLY = 1e12 ether;

  uint private constant TAX_RATE = 1000;
  uint private constant BP_DIVISOR = 10000;

  // V1 token redemption rate
  uint private constant V1_VALUE = 12.659726999081298826 ether;
  uint private constant V1_SUPPLY = 913290958465.509630323815153677 ether;

  address private _owner;
  address private _pair;

  uint private _initialBasis;

  mapping (address => uint) private _basisOf;
  mapping (address => uint) public cooldownOf;

  // credits for ETH LE deposits
  mapping (address => uint) private _lpCredits;
  uint private _lpCreditsTotal;

  // quantity of UNI-V2 tokens corresponding to initial liquidity, shared among token holders
  uint private _holderDistributionUNIV2;
  // quantity of ETH to be distributed to token holders, set after trading close
  uint private _holderDistributionETH;
  // quantity of ETH to be distributed to liquidity providers, set after trading close
  uint private _lpDistributionETH;

  // all time high
  uint private _ath;
  uint private _athTimestamp;

  // values to prevent adding liquidity directly
  address private _lastOrigin;
  uint private _lastBlock;

  bool private _nohook;

  struct Minting {
    address recipient;
    uint amount;
  }

  modifier phase (Phase p) {
    require(_phase == p, 'ERR: invalid phase');
    _;
  }

  modifier nohook () {
    _nohook = true;
    _;
    _nohook = false;
  }

  /**
   * @notice deploy
   * @param mintings structured minting data (recipient, amount)
   */
  constructor (
    Minting[] memory mintings
  ) payable {
    _owner = msg.sender;
    _phaseChangedAt = block.timestamp;

    // setup uniswap pair and store address

    _pair = IUniswapV2Factory(
      IUniswapV2Router02(UNISWAP_ROUTER).factory()
    ).createPair(WETH, address(this));

    // prepare to add/remove liquidity

    _approve(address(this), UNISWAP_ROUTER, type(uint).max);
    IERC20(_pair).approve(UNISWAP_ROUTER, type(uint).max);

    // mint team tokens

    uint mintedSupply;

    for (uint i; i < mintings.length; i++) {
      Minting memory m = mintings[i];
      uint amount = m.amount;
      address recipient = m.recipient;

      mintedSupply += amount;
      _balances[recipient] += amount;
      emit Transfer(address(0), recipient, amount);
    }

    _totalSupply = mintedSupply;
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
   * @notice get cost basis for given address
   * @param account address to query
   * @return cost basis
   */
  function basisOf (
    address account
  ) public view returns (uint) {
    uint basis = _basisOf[account];

    if (basis == 0 && balanceOf(account) > 0) {
      basis = _initialBasis;
    }

    return basis;
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
    return amount * (toBasis - fromBasis) / toBasis * TAX_RATE / BP_DIVISOR;
  }

  /**
   * @notice enable liquidity event participation
   */
  function openLiquidityEvent () external phase(Phase.PENDING) {
    require(
      msg.sender == _owner || block.timestamp > _phaseChangedAt + (2 weeks),
      'ERR: sender must be owner'
    );

    _incrementPhase();

    // track lp credits to be used for distribution

    _lpCredits[address(this)] = address(this).balance;
    _lpCreditsTotal += address(this).balance;

    // add liquidity

    _mint(address(this), SUPPLY - totalSupply());

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
  }

  /**
   * @notice buy in to liquidity event using DOGSTONKS V1 tokens
   */
  function contributeV1 () external {
    require(_phase == Phase.LIQUIDITY_EVENT || _phase == Phase.OPEN, 'ERR: invalid phase');

    uint amount = IERC20(DOGSTONKS).balanceOf(msg.sender);
    IERC20(DOGSTONKS).transferFrom(msg.sender, DOGSTONKS, amount);

    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(this);

    uint[] memory amounts = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).getAmountsOut(
      amount * V1_VALUE / V1_SUPPLY,
      path
    );

    // credit sender with deposit

    _mintTaxCredit(msg.sender, amounts[1]);
  }

  /**
   * @notice buy in to liquidity event using ETH
   */
  function contributeETH () external payable phase(Phase.LIQUIDITY_EVENT) nohook {
    if (block.timestamp < _phaseChangedAt + (15 minutes)) {
      // at beginning of LE, only V1 depositors and team token holders may contribute
      require(
        taxCreditsOf(msg.sender) >= 1e6 ether || balanceOf(msg.sender) > 0,
        'ERR: must contribute V1 tokens'
      );
    }

    // add liquidity via purchase to simulate price action by purchasing tokens

    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(this);

    uint[] memory amounts = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).swapExactETHForTokens{
      value: msg.value
    }(
      0,
      path,
      msg.sender,
      block.timestamp
    );

    _transfer(msg.sender, _pair, amounts[1]);
    IUniswapV2Pair(_pair).sync();

    // credit sender with deposit

    _mintTaxCredit(msg.sender, amounts[1]);
    _lpCredits[msg.sender] += msg.value;
    _lpCreditsTotal += msg.value;
  }

  /**
   * @notice open trading
   * @dev sender must be owner
   * @dev trading must not yet have been opened
   */
  function open () external phase(Phase.LIQUIDITY_EVENT) {
    require(
      msg.sender == _owner || block.timestamp > _phaseChangedAt + (1 hours),
      'ERR: sender must be owner'
    );

    _incrementPhase();

    // set initial cost basis

    _initialBasis = (1 ether) * IERC20(WETH).balanceOf(_pair) / balanceOf(_pair);

    // calculate proportion of UNI-V2 tokens for distribution

    _holderDistributionUNIV2 = IERC20(_pair).totalSupply() * _lpCredits[address(this)] / _lpCreditsTotal;
  }

  /**
   * @notice add Uniswap liquidity
   * @param amount quantity of DOGPRO to add
   */
  function addLiquidity (
    uint amount
  ) external payable phase(Phase.OPEN) {
    _transfer(msg.sender, address(this), amount);

    uint liquidityETH = IERC20(WETH).balanceOf(_pair);

    (uint amountToken, uint amountETH, ) = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).addLiquidityETH{
      value: msg.value
    }(
      address(this),
      amount,
      0,
      0,
      address(this),
      block.timestamp
    );

    if (amountToken < amount) {
      _transfer(address(this), msg.sender, amount - amountToken);
    }

    if (amountETH < msg.value) {
      payable(msg.sender).sendValue(msg.value - amountETH);
    }

    uint lpCreditsDelta = _lpCreditsTotal * amountETH / liquidityETH;
    _lpCredits[msg.sender] += lpCreditsDelta;
    _lpCreditsTotal += lpCreditsDelta;

    _mintTaxCredit(msg.sender, amountToken);
  }

  /**
   * @notice close trading
   * @dev trading must not yet have been closed
   * @dev minimum time since open must have elapsed
   */
  function close () external phase(Phase.OPEN) {
    require(block.timestamp > _phaseChangedAt + (1 days), 'ERR: too soon');

    _incrementPhase();

    require(
      block.timestamp > _athTimestamp + (1 weeks),
      'ERR: recent ATH'
    );

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

    // split liquidity between holders and liquidity providers

    _holderDistributionETH = address(this).balance * _holderDistributionUNIV2 / univ2;
    _lpDistributionETH = address(this).balance - _holderDistributionETH;

    // stop tracking LP credit for original deposit

    _lpCreditsTotal -= _lpCredits[address(this)];
    delete _lpCredits[address(this)];
  }

  /**
   * @notice exchange DOGPRO for proportion of ETH in contract
   * @dev trading must have been closed
   */
  function liquidate () external phase(Phase.CLOSED) {
    // claim tax rewards

    if (taxCreditsOf(msg.sender) > 0) {
      _transfer(address(this), msg.sender, taxRewardsOf(msg.sender));
      _burnTaxCredit(msg.sender);
    }

    // calculate share of holder rewards

    uint balance = balanceOf(msg.sender);
    uint holderPayout;

    if (balance > 0) {
      holderPayout = _holderDistributionETH * balance / totalSupply();
      _holderDistributionETH -= holderPayout;
      _burn(msg.sender, balance);
    }

    // calculate share of liquidity

    uint lpCredits = _lpCredits[msg.sender];
    uint lpPayout;

    if (lpCredits > 0) {
      lpPayout = _lpDistributionETH * lpCredits / _lpCreditsTotal;
      _lpDistributionETH -= lpPayout;

      delete _lpCredits[msg.sender];
      _lpCreditsTotal -= lpCredits;
    }

    payable(msg.sender).sendValue(holderPayout + lpPayout);
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

    if (_nohook) return;

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
      _basisOf[to] = (fromBasis * amount + basisOf(to) * balance) / (amount + balance);

      if (fromBasis > _ath) {
        _ath = fromBasis;
        _athTimestamp = block.timestamp;
      }
    } else if (to == _pair) {
      _lastOrigin = tx.origin;
      _lastBlock = block.number;

      require(cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */);
      cooldownOf[from] = block.timestamp + (5 minutes);

      uint fromBasis = basisOf(from);
      uint toBasis = basisOfSale(amount);

      require(fromBasis <= toBasis /* revert message not returned by Uniswap */);

      // collect tax
      uint tax = taxFor(fromBasis, toBasis, amount);
      _transfer(from, address(this), tax);
      _distributeTax(tax);
    }
  }
}
