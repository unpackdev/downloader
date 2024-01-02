//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
    
    function claimDividend() external;
}
