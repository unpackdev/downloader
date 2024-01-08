// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./FixedPoint.sol";
import "./IYieldSource.sol";
import "./CTokenInterface.sol";

contract ArchiBankYieldSource is IYieldSource {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event ArchiBankYieldSourceInitialized(address indexed cToken);

  CTokenInterface internal _cToken;
  mapping(address => uint256) public balances;

  constructor(CTokenInterface cToken) public
  {
    _cToken = cToken;
    emit ArchiBankYieldSourceInitialized(address(cToken));
  }

  function depositToken() public override view returns (address) {
    return _tokenAddress();
  }

  function _tokenAddress() internal view returns (address) {
    return _cToken.underlying();
  }

  function _token() internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(_tokenAddress());
  }

  function balanceOfToken(address addr) external override returns (uint256) {
    uint256 totalUnderlying = _cToken.balanceOfUnderlying(address(this));
    uint256 total = _cToken.balanceOf(address(this));
    if (total == 0) {
      return 0;
    }
    return balances[addr].mul(totalUnderlying).div(total);
  }

  function supplyTokenTo(uint256 amount, address to) external override {
    _token().transferFrom(msg.sender, address(this), amount);
    IERC20Upgradeable(_cToken.underlying()).approve(address(_cToken), amount);
    uint256 cTokenBalanceBefore = _cToken.balanceOf(address(this));
    require(_cToken.mint(amount) == 0, "CTOKENYIELDSOURCE: MINT_FAILED");
    uint256 cTokenDiff = _cToken.balanceOf(address(this)).sub(cTokenBalanceBefore);
    balances[to] = balances[to].add(cTokenDiff);
  }

  function redeemToken(uint256 redeemAmount) external override returns (uint256) {
    uint256 cTokenBalanceBefore = _cToken.balanceOf(address(this));
    uint256 balanceBefore = _token().balanceOf(address(this));
    require(_cToken.redeemUnderlying(redeemAmount) == 0, "CTOKENYIELDSOURCE: REDEEM_FAILED");
    uint256 cTokenDiff = cTokenBalanceBefore.sub(_cToken.balanceOf(address(this)));
    uint256 diff = _token().balanceOf(address(this)).sub(balanceBefore);
    balances[msg.sender] = balances[msg.sender].sub(cTokenDiff);
    _token().transfer(msg.sender, diff);
    return diff;
  }
}
