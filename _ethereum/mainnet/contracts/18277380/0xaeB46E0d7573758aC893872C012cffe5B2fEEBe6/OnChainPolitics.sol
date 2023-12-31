// https://onchainpolitics.com
// https://x.com/OnChainPolitics
// https://t.me/OnChainPolitics
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./PoolAddress.sol";
import "./Rewards.sol";
import "./WrappedTokenWithRewards.sol";

contract OnChainPolitics is ERC20 {
  using SafeERC20 for IERC20;

  address immutable V2_ROUTER;
  address immutable V3_FACTORY;
  address immutable WETH9;

  Rewards public rewards;
  address public multisig;

  mapping(address => bool) public wrappers;
  mapping(address => bool) _excluded;
  address _v2Pool;
  bool _swapping;
  bool _swapTaxOn = true;

  event CreateWrapped(address _newToken, string _name, string _symbol);

  modifier noSwapTax() {
    _swapTaxOn = false;
    _;
    _swapTaxOn = true;
  }

  modifier onlyMultisig() {
    require(_msgSender() == multisig, 'AUTH');
    _;
  }

  constructor(
    address _multisig,
    address _v2Router,
    address _v3Factory
  ) ERC20('OnChainPolitics', 'OCP') {
    multisig = _multisig;
    V2_ROUTER = _v2Router;
    V3_FACTORY = _v3Factory;
    WETH9 = IUniswapV2Router02(V2_ROUTER).WETH();

    rewards = new Rewards(address(this));
    _v2Pool = IUniswapV2Factory(IUniswapV2Router02(V2_ROUTER).factory())
      .createPair(address(this), WETH9);

    _excluded[address(0)] = true;
    _excluded[address(this)] = true;
    _excluded[address(0xdead)] = true;
    _excluded[_v2Pool] = true;
    _excluded[_v3Pool(500)] = true;
    _excluded[_v3Pool(3000)] = true;
    _excluded[_v3Pool(10000)] = true;

    _mint(_msgSender(), 1_000_000_000 * 10 ** 18);
  }

  function createWrapped(
    string memory _name,
    string memory _symbol
  ) external onlyMultisig {
    WrappedTokenWithRewards _newToken = new WrappedTokenWithRewards(
      _name,
      _symbol,
      address(this)
    );
    wrappers[address(_newToken)] = true;
    emit CreateWrapped(address(_newToken), _name, _symbol);
  }

  function setMultisig(address _multisig) external onlyMultisig {
    multisig = _multisig;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) public virtual override returns (bool) {
    if (wrappers[_msgSender()]) {
      _transfer(_from, _to, _amount);
      return true;
    }
    return super.transferFrom(_from, _to, _amount);
  }

  function addLiquidityETH(
    uint256 _tokens,
    uint256 _slippage // 10 == 1%, 100 == 10%, 1000 == 100%
  ) external payable noSwapTax {
    uint256 _lpETH = msg.value;
    require(_tokens > 0 && _lpETH > 0, 'LPFUNDS');

    uint256 _tokensBefore = balanceOf(address(this));
    uint256 _ethBefore = address(this).balance - _lpETH;

    _transfer(_msgSender(), address(this), _tokens);
    _approve(address(this), V2_ROUTER, _tokens);
    IUniswapV2Router02(V2_ROUTER).addLiquidityETH{ value: _lpETH }(
      address(this),
      _tokens,
      (_tokens * (1000 - _slippage)) / 1000,
      (_lpETH * (1000 - _slippage)) / 1000,
      _msgSender(),
      block.timestamp
    );
    if (balanceOf(address(this)) > _tokensBefore) {
      _transfer(
        address(this),
        _msgSender(),
        balanceOf(address(this)) - _tokensBefore
      );
    }
    if (address(this).balance > _ethBefore) {
      (bool _refund, ) = payable(_msgSender()).call{
        value: address(this).balance - _ethBefore
      }('');
      require(_refund, 'ETHREFUND');
    }
  }

  function removeLiquidityETH(
    uint256 _lpTokens,
    uint256 _minTokens, // 0 means 100% slippage
    uint256 _minETH // 0 means 100% slippage
  ) external noSwapTax {
    _lpTokens = _lpTokens == 0
      ? IERC20(_v2Pool).balanceOf(_msgSender())
      : _lpTokens;
    require(_lpTokens > 0, 'LPREMOVE');

    uint256 _lpBalBefore = IERC20(_v2Pool).balanceOf(address(this));
    IERC20(_v2Pool).safeTransferFrom(_msgSender(), address(this), _lpTokens);
    IERC20(_v2Pool).approve(V2_ROUTER, _lpTokens);
    IUniswapV2Router02(V2_ROUTER).removeLiquidityETH(
      address(this),
      _lpTokens,
      _minTokens,
      _minETH,
      _msgSender(),
      block.timestamp
    );
    if (IERC20(_v2Pool).balanceOf(address(this)) > _lpBalBefore) {
      IERC20(_v2Pool).safeTransfer(
        _msgSender(),
        IERC20(_v2Pool).balanceOf(address(this)) - _lpBalBefore
      );
    }
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    bool _buying = _from == _v2Pool && _to != V2_ROUTER;
    bool _selling = _to == _v2Pool;
    uint256 _tax = 0;
    if (_swapTaxOn) {
      uint256 _bal = balanceOf(address(this));
      uint256 _min = (totalSupply() * 5) / 100000; // 0.005%
      if (!_swapping && _from != _v2Pool && _bal >= _min) {
        _swapping = true;
        _swap(_bal >= _min * 10 ? _min * 10 : _min);
        _swapping = false;
      }
      if (!_swapping && (_buying || _selling)) {
        _tax = (_amount * 142069) / 10000000; // 1.42069%
        super._transfer(_from, address(this), _tax);
      }
    }
    super._transfer(_from, _to, _amount - _tax);
  }

  function _swap(uint256 _amount) internal {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = WETH9;
    _approve(address(this), V2_ROUTER, _amount);
    IUniswapV2Router02(V2_ROUTER)
      .swapExactTokensForETHSupportingFeeOnTransferTokens(
        _amount,
        0,
        path,
        multisig,
        block.timestamp
      );
  }

  function _v3Pool(uint24 _poolFee) internal view returns (address) {
    (address _token0, address _token1) = _lpTokensOrdered();
    PoolAddress.PoolKey memory _key = PoolAddress.PoolKey({
      token0: _token0,
      token1: _token1,
      fee: _poolFee
    });
    return PoolAddress.computeAddress(V3_FACTORY, _key);
  }

  function _lpTokensOrdered() internal view returns (address, address) {
    return
      WETH9 < address(this) ? (WETH9, address(this)) : (address(this), WETH9);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    if (!_excluded[_from]) {
      try rewards.setShare(_from, _amount, true) {} catch {}
    }
    if (!_excluded[_to]) {
      try rewards.setShare(_to, _amount, false) {} catch {}
    }
  }
}
