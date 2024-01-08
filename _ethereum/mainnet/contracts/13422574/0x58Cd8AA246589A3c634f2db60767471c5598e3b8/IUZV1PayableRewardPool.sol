// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IUZV1RewardPool.sol";

interface IUZV1PayableRewardPool is IUZV1RewardPool {
    /* view functions */
    function getPurchaseableTokens(address _user)
        external
        view
        returns (uint256);

    function getTotalPriceForPurchaseableTokens(address _user)
        external
        view
        returns (uint256);

    function getPurchasedAllocationOfUser(address _user)
        external
        view
        returns (uint256);

    function getPaymentAddress() external view returns (address);

    /* control functions */
    function setNative(bool _isNative) external;

    function setPaymentAddress(address _receiver) external;

    function setPaymentToken(address _token, uint256 _pricePerReward) external;

    function setPaymentWindow(uint256 _startBlock, uint256 _endBlock) external;

    function setDistributionWindow(uint256 _startBlock, uint256 _endBlock)
        external;
}
