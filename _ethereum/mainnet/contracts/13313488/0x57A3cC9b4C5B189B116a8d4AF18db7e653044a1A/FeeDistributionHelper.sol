// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;
import "./IFeeDistribution.sol";
import "./IFoundation.sol";
import "./IERC20.sol";

contract FeeDistributionHelper {

  IFeeDistribution public constant feeDistribution = IFeeDistribution(0x3f93dE882dA8150Dc98a3a1F4626E80E3282df46);
  IFoundation public constant foundation = IFoundation(0x492530fc97522d142bc57710bE57fA57A43Dc911);
  IERC20 public constant usdp = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);

  modifier s() {
    require(feeDistribution.canSwap(msg.sender), "FeeDistributionHelper: can't claim, swap and distribute");
    _;
  }

  /**
    @notice minDuckAmount must be set to prevent sandwich attack
    @param usdpAmount The amount of USDP being swapped and distributed
    @param minDuckAmount The minimum amount of DUCK being distributed
  **/
  function claimSwapAndDistribute(uint usdpAmount, uint minDuckAmount) public s returns(uint) {
    foundation.distribute();
    return feeDistribution.swapAndDistribute(usdpAmount, minDuckAmount);
  }

  // @dev This function should be manually changed to "view" in the ABI
  function viewDistribution() external s returns(uint usdp_, uint duck_) {
    foundation.distribute();
    return feeDistribution.viewDistribution();
  }
}
