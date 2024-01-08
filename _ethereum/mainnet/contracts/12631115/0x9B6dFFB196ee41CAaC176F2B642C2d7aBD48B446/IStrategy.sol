// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStrategy {
    function setTreasury(address payable _feeAddress) external;

    function setCap(uint256 _cap) external;

    function setLockTime(uint256 _lockTime) external;

    function setFeeAddress(address payable _feeAddress) external;

    function setFee(uint256 _fee) external;

    function rescueDust() external;

    function rescueAirdroppedTokens(address _token, address to) external;

    function setSushiswapRouter(address _sushiswapRouter) external;
}
