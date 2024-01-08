// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";


contract CompoundInteractor {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public ctoken;
  address public comptroller;
  address public comp;

  constructor(address _ctoken) public {
    ctoken = _ctoken;
    comptroller = CTokenInterface(ctoken).comptroller();
    comp = ComptrollerInterface(comptroller).getCompAddress();

    // Enter the market
    address[] memory cTokens = new address[](1);
    cTokens[0] = ctoken;
    ComptrollerInterface(comptroller).enterMarkets(cTokens);
  }

  /**
  * Supplies to Compound
  */
  function _compoundSupply() internal {
    uint256 balance = IERC20(CTokenInterface(ctoken).underlying()).balanceOf(address(this));

    if (balance > 0) {
        IERC20(CTokenInterface(ctoken).underlying()).safeApprove(address(ctoken), 0);
        IERC20(CTokenInterface(ctoken).underlying()).safeApprove(address(ctoken), balance);
        require(CTokenInterface(ctoken).mint(balance) == 0, "Mint failed");
    }
  }

  function _compoundRedeemUnderlying(uint256 amountUnderlying) internal {
    if (amountUnderlying > 0) {
      require(CTokenInterface(ctoken).redeemUnderlying(amountUnderlying) == 0, "Redeem underlying failed");
    }
  }

  function _compoundRedeem(uint256 amount) internal {
    if (amount > 0) {
      require(CTokenInterface(ctoken).redeem(amount) == 0, "Redeem failed");
        }
    }

}
