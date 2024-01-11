// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMoonForceSwapLocker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer) external payable;
}