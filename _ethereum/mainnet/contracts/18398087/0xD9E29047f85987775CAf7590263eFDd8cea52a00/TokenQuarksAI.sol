// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2.sol";

error QuarksAI_InvalidAddress();

contract TokenQuarksAI is ERC20, Ownable {
  uint256 public constant initialTotalSupply = 300_000_000 * 10**18;

  IUniswapV2Router02 router;
  address[] public pairAddresses;

  uint256 public constant SELL_AND_BUY_FEE = 600; // 6%

  constructor(address owner_, address router_) ERC20('QUARKS AI', 'QUARKSAI') Ownable(owner_) {
    _mint(owner_, initialTotalSupply);
    router = IUniswapV2Router02(router_);
    address pairAddress_ = IUniswapFactory(router.factory()).createPair(address(this), router.WETH());
    pairAddresses.push(pairAddress_);
  }

  /**
    * @notice Calculate the percentage of a number.
    * @param x Number.
    * @param y Percentage of number.
    * @param scale Division.
  */
  function mulScale(uint x, uint y, uint128 scale) internal pure returns (uint) {
    uint a = x / scale;
    uint b = x % scale;
    uint c = y / scale;
    uint d = y % scale;

    return a * c * scale + a * d + b * c + b * d / scale;
  }

  function transfer(address to_, uint256 value_) public override returns(bool) {
    uint256 feeAmount_;
    for (uint256 i; i < pairAddresses.length; ++i) {
      if (msg.sender == pairAddresses[i] || to_ == pairAddresses[i]) {
        feeAmount_ = mulScale(value_, SELL_AND_BUY_FEE, 10000);
        break;
      }
    }
    value_ -= feeAmount_;

    super.transfer(to_, value_);
    super.transfer(owner(), feeAmount_);
    return true;
  }

  function setPairAddress(address pairAddress_) public onlyOwner() {
    if (pairAddress_ == address(0)) revert QuarksAI_InvalidAddress();

    pairAddresses.push(pairAddress_);
  }
}
