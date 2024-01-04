// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IProtocol.sol";
import "./ICover.sol";
import "./IBPool.sol";
import "./IERC20.sol";

interface IFlashBorrower is IERC3156FlashBorrower {
    struct FlashLoanData {
        bool isBuy;
        IBPool bpool;
        IProtocol protocol;
        address caller;
        address collateral;
        uint48 timestamp;
        uint256 amount;
        uint256 limit;
    }

    function flashBuyClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy, 
        uint256 _maxAmountToSpend
    ) external;
    
    function flashSellClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell, 
        uint256 _minAmountToReturn
    ) external;

    function getBuyClaimCost(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy
    ) external view returns (uint256 totalCost);

    function getSellClaimReturn(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell,
        uint256 _redeemFeeNumerator
    ) external view returns (uint256 totalReturn);

    function setFlashLender(address _flashLender) external;
    function collect(IERC20 _token) external;
}