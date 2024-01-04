// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2ETHFactory {
    function feeReceiver() external view returns (address);
    function interestReceiver() external view returns (address);
    function setAppFee(address market, uint256 appFeeBasisPoints) external;
    function createMarket(
        address _priceFeed,
        uint256 _multiplierBasisPoints,
        uint256 _maxProfitBasisPoints,
        uint256 _fundingDivisor,
        uint256 _appFeeBasisPoints
    ) external returns (address, address, address);
}
