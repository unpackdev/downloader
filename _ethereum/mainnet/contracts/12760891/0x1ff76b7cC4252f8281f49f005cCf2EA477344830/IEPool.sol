// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

import "./IEToken.sol";

interface IEPool {
    struct Tranche {
        IEToken eToken;
        uint256 sFactorE;
        uint256 reserveA;
        uint256 reserveB;
        uint256 targetRatio;
    }

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function tokenA() external view returns (IERC20);

    function tokenB() external view returns (IERC20);

    function sFactorA() external view returns (uint256);

    function sFactorB() external view returns (uint256);

    function getTranche(address eToken) external view returns (Tranche memory);

    function getTranches() external view returns(Tranche[] memory _tranches);

    function addTranche(uint256 targetRatio, string memory eTokenName, string memory eTokenSymbol) external returns (bool);

    function getAggregator() external view returns (address);

    function setAggregator(address oracle, bool inverseRate) external returns (bool);

    function rebalanceMinRDiv() external view returns (uint256);

    function rebalanceInterval() external view returns (uint256);

    function lastRebalance() external view returns (uint256);

    function feeRate() external view returns (uint256);

    function cumulativeFeeA() external view returns (uint256);

    function cumulativeFeeB() external view returns (uint256);

    function setFeeRate(uint256 _feeRate) external returns (bool);

    function transferFees() external returns (bool);

    function getRate() external view returns (uint256);

    function rebalance(uint256 fracDelta) external returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv);

    function issueExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function redeemExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}
