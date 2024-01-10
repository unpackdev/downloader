// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;
import "./IParams.sol";
import "./Ownable.sol";

contract Params is Ownable, IParams {
    uint256 public minimumSwapAmountForWBTC;
    uint256 public expirationTime;
    address public paraswapAddress;
    uint8 public nodeRewardsRatio;
    uint8 public depositFeesBPS;
    uint8 public withdrawalFeeBPS;
    uint8 public loopCount; //max loops when cleaning up expired SkyPools TXs

    constructor() {
        //Initialize minimumSwapAmountForWBTC
        minimumSwapAmountForWBTC = 24000;
        // Initialize expirationTime
        expirationTime = 172800; //2 days
        // Initialize paraswap address to current address
        paraswapAddress = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
        // Initialize nodeRewardsRatio
        nodeRewardsRatio = 66;
        // Initialize withdrawalFeeBPS
        withdrawalFeeBPS = 20;
        // Initialize depositFeesBPS
        depositFeesBPS = 0;
        // Initialize loopCount
        loopCount = 10;
    }

    function setMinimumSwapAmountForWBTC(uint256 _minimumSwapAmountForWBTC)
        external
        onlyOwner
    {
        require(
            _minimumSwapAmountForWBTC > 0,
            "_minimumSwapAmountForWBTC can not be 0"
        );
        minimumSwapAmountForWBTC = _minimumSwapAmountForWBTC;
    }

    function setExpirationTime(uint256 _expirationTime) external onlyOwner {
        require(_expirationTime >= 0, "_expirationTime can not be 0");
        expirationTime = _expirationTime;
    }

    function setParaswapAddress(address _paraswapAddress) external onlyOwner {
        paraswapAddress = _paraswapAddress;
    }

    function setNodeRewardsRatio(uint8 _nodeRewardsRatio) external onlyOwner {
        require(
            _nodeRewardsRatio >= 0 && _nodeRewardsRatio <= 100,
            "_nodeRewardsRatio is not valid"
        );
        nodeRewardsRatio = _nodeRewardsRatio;
    }

    function setWithdrawalFeeBPS(uint8 _withdrawalFeeBPS) external onlyOwner {
        require(
            _withdrawalFeeBPS >= 0 && _withdrawalFeeBPS <= 100,
            "_withdrawalFeeBPS is invalid"
        );
        withdrawalFeeBPS = _withdrawalFeeBPS;
    }

    function setDepositFeesBPS(uint8 _depositFeesBPS) external onlyOwner {
        require(
            _depositFeesBPS >= 0 && _depositFeesBPS <= 100,
            "_depositFeesBPS is invalid"
        );
        depositFeesBPS = _depositFeesBPS;
    }

    function setLoopCount(uint8 _loopCount) external onlyOwner {
        require(_loopCount != 0, "_loopCount can not equal 0");
        loopCount = _loopCount;
    }
}
