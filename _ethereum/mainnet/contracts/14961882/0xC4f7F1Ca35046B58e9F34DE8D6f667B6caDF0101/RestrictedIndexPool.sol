// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import "./IndexPoolToken.sol";

contract RestrictedIndexPool is IndexPoolToken {
  function _pushUnderlying(
    address erc20,
    address to,
    uint256 amount
  ) internal {
    (bool success, bytes memory data) =
      erc20.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "ERR_ERC20_FALSE"
    );
  }

  function _redeemTokensTo(
    address src,
    address dst,
    uint256 poolAmountIn
  ) internal returns (uint256[] memory tokenAmountsOut) {
    uint256 len = _tokens.length;
    tokenAmountsOut = new uint256[](len);
    uint256 poolTotal = totalSupply;
    uint256 ratio = bdiv(poolAmountIn, poolTotal);
    _burn(src, poolAmountIn);

    for (uint256 i = 0; i < len; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      if (bal > 0) {
        uint256 tokenAmountOut = bmul(ratio, bal);
        _pushUnderlying(t, dst, tokenAmountOut);
        emit LOG_EXIT(src, t, tokenAmountOut);
        tokenAmountsOut[i] = tokenAmountOut;
      } else {
        tokenAmountsOut[i] = 0;
      }
    }
  }

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external
    override
    _lock_
    _initialized_
  {
    uint256 len = minAmountsOut.length;
    uint256[] memory tokenAmountsOut =
      _redeemTokensTo(msg.sender, msg.sender, poolAmountIn);
    require(len == tokenAmountsOut.length, "ERR_ARR_LEN");
    for (uint256 i = 0; i < len; i++) {
      require(tokenAmountsOut[i] >= minAmountsOut[i], "ERR_LIMIT_OUT");
    }
  }

  function exitPoolTo(address to, uint256 poolAmountIn)
    external
    override
    _lock_
    _initialized_
  {
    _redeemTokensTo(msg.sender, to, poolAmountIn);
  }

  function redeemAll() external override _lock_ _initialized_ {
    _redeemTokensTo(msg.sender, msg.sender, balanceOf[msg.sender]);
  }
}
