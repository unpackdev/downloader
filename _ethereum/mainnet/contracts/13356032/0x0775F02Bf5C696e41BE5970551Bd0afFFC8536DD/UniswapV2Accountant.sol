// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./IBasicIssuanceModule.sol";
import "./IUniswapRouterV2.sol";
import "./IWETH.sol";

contract UniswapV2Accountant is OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 internal constant PRECISE_UNIT = 10**18;
  uint8 internal constant DECR_INTEREST = 2;
  uint8 internal constant MAX_DECR_ITERATION = 3;

  event TotalETH(uint256 quantity, uint256 eth);

  address public weth;
  IBasicIssuanceModule private bi;
  UniswapRouterV2 private uni;

  // 0x8a070235a4B9b477655Bf4Eb65a1dB81051B3cC1
  // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  function initialize(address _router, address _issuer) external initializer {
    uni = UniswapRouterV2(_router);
    weth = uni.WETH();
    bi = IBasicIssuanceModule(_issuer);
  }

  // // 0x7f9134790db23eeF1AF32335d4aF3841f0491b29
  function deposit(address _setToken) public payable {
    address[] memory tokens;
    uint256[] memory amountsOut;
    uint256[] memory amountsIn;
    uint256 totalETH = 0;

    (tokens, amountsIn, amountsOut, totalETH) = _getTotalEthForComponents(
      _setToken,
      1e18
    );

    uint256 quantity = msg.value.mul(PRECISE_UNIT).div(totalETH);

    for (uint8 j = 0; j < MAX_DECR_ITERATION; j++) {
      (tokens, amountsIn, amountsOut, totalETH) = _getTotalEthForComponents(
        _setToken,
        quantity
      );
      if (totalETH <= msg.value) {
        break;
      }

      quantity = _decrease(msg.value.mul(quantity).div(totalETH));
    }

    emit TotalETH(quantity, totalETH);
    require(totalETH <= msg.value, 'Wrong ETH estimation');

    address[] memory path = new address[](2);
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] != weth) {
        path[0] = weth;
        path[1] = tokens[i];

        uni.swapETHForExactTokens{value: amountsIn[i]}(
          amountsOut[i],
          path,
          address(this),
          block.timestamp + 300
        );
      } else {
        IWETH(weth).deposit{value: amountsOut[i]}();
      }

      IERC20 token = IERC20(tokens[i]);
      token.safeApprove(address(bi), amountsOut[i]);
    }

    bi.issue(_setToken, quantity, address(msg.sender));

    // refund remaining ETH.
    if (totalETH < msg.value)
      payable(msg.sender).transfer(msg.value.sub(totalETH));
  }

  function _getTotalEthForComponents(address _setToken, uint256 _quantity)
    internal
    view
    returns (
      address[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256
    )
  {
    (address[] memory tokens, uint256[] memory amountsOut) = bi
      .getRequiredComponentUnitsForIssue(_setToken, _quantity);
    uint256[] memory amountsIn = new uint256[](tokens.length);
    uint256 totalETH = 0;
    address[] memory path = new address[](2);

    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] != weth) {
        path[0] = weth;
        path[1] = tokens[i];
        amountsIn[i] = uni.getAmountsIn(amountsOut[i], path)[0];
      } else {
        amountsIn[i] = amountsOut[i];
      }

      totalETH = totalETH.add(amountsIn[i]);
    }

    return (tokens, amountsIn, amountsOut, totalETH);
  }

  function _decrease(uint256 _num) internal pure returns (uint256) {
    return _num.sub(_num.mul(DECR_INTEREST).div(100));
  }
}
