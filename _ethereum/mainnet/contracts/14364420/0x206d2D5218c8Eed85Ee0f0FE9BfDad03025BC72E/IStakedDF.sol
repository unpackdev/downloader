// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20Upgradeable.sol";

interface IStakedDF is IERC20Upgradeable {
    function stake(address _recipient, uint256 _rawUnderlyingAmount)
        external
        returns (uint256 _tokenAmount);

    function unstake(address _recipient, uint256 _rawTokenAmount)
        external
        returns (uint256 _tokenAmount);

    function getCurrentExchangeRate()
        external
        view
        returns (uint256 _exchangeRate);

    function DF() external view returns (address);
}
