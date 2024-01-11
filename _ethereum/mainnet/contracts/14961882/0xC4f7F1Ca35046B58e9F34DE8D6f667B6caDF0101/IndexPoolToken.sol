// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import "./IndexPoolMath.sol";

abstract contract IndexPoolToken is IndexPoolMath {
  function _move(
    address src,
    address dst,
    uint256 amt
  ) internal {
    require(src != pair && dst != pair, "ERR_UNI_TRANSFER");
    require(balanceOf[src] >= amt, "ERR_INSUFFICIENT_BAL");
    balanceOf[src] = bsub(balanceOf[src], amt);
    balanceOf[dst] = badd(balanceOf[dst], amt);
    emit Transfer(src, dst, amt);
  }

  function _burn(address src, uint256 amount) internal {
    require(amount > 0, "ERR_NULL_AMOUNT");
    require(balanceOf[src] >= amount, "ERR_INSUFFICIENT_BAL");
    balanceOf[src] = bsub(balanceOf[src], amount);
    totalSupply = bsub(totalSupply, amount);
    emit Transfer(src, address(0), amount);
  }

  function approve(address dst, uint256 amt) external override returns (bool) {
    allowance[msg.sender][dst] = amt;
    emit Approval(msg.sender, dst, amt);
    return true;
  }

  function transfer(address dst, uint256 amt)
    external
    override
    _initialized_
    returns (bool)
  {
    _move(msg.sender, dst, amt);
    return true;
  }

  function transferFrom(
    address src,
    address dst,
    uint256 amt
  ) external override _initialized_ returns (bool) {
    require(
      msg.sender == src || amt <= allowance[src][msg.sender],
      "ERR_BTOKEN_BAD_CALLER"
    );
    _move(src, dst, amt);
    if (msg.sender != src && allowance[src][msg.sender] != type(uint256).max) {
      allowance[src][msg.sender] = bsub(allowance[src][msg.sender], amt);
      emit Approval(src, msg.sender, allowance[src][msg.sender]);
    }
    return true;
  }
}
