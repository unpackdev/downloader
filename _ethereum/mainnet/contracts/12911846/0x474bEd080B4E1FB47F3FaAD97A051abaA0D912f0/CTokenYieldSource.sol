// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./FixedPoint.sol";
import "./IYieldSource.sol";
import "./CTokenInterface.sol";

contract CTokenYieldSource is IYieldSource {
  using SafeMathUpgradeable for uint256;

  event CTokenYieldSourceInitialized(address indexed cToken);

  mapping(address => uint256) public balances;
  CTokenInterface public cToken;

  constructor(CTokenInterface _cToken) public
  {
    cToken = _cToken;
    emit CTokenYieldSourceInitialized(address(cToken));
  }

  function depositToken() public override view returns (address) {
    return _tokenAddress();
  }

  function _tokenAddress() internal view returns (address) {
    return cToken.underlying();
  }

  function _token() internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(_tokenAddress());
  }

  function balanceOfToken(address addr) external override returns (uint256) {
    uint256 totalUnderlying = cToken.balanceOfUnderlying(address(this));
    uint256 total = cToken.balanceOf(address(this));
    if (total == 0) {
      return 0;
    }
    return balances[addr].mul(totalUnderlying).div(total);
  }

  function supplyTokenTo(uint256 amount, address to) external override {
    _token().transferFrom(msg.sender, address(this), amount);
    IERC20Upgradeable(cToken.underlying()).approve(address(cToken), amount);
    uint256 cTokenBalanceBefore = cToken.balanceOf(address(this));
    require(cToken.mint(amount) == 0, "CTOKENYIELDSOURCE: MINT_FAILED");
    uint256 cTokenDiff = cToken.balanceOf(address(this)).sub(cTokenBalanceBefore);
    balances[to] = balances[to].add(cTokenDiff);
  }

  function redeemToken(uint256 redeemAmount) external override returns (uint256) {
    uint256 cTokenBalanceBefore = cToken.balanceOf(address(this));
    uint256 balanceBefore = _token().balanceOf(address(this));
    require(cToken.redeemUnderlying(redeemAmount) == 0, "CTOKENYIELDSOURCE: REDEEM_FAILED");
    uint256 cTokenDiff = cTokenBalanceBefore.sub(cToken.balanceOf(address(this)));
    uint256 diff = _token().balanceOf(address(this)).sub(balanceBefore);
    balances[msg.sender] = balances[msg.sender].sub(cTokenDiff);
    _token().transfer(msg.sender, diff);
    return diff;
  }
}
