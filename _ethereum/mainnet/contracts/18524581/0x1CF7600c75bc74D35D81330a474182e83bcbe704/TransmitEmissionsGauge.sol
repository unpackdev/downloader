// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "./Ownable2Step.sol";
import "./TransferHelper.sol";

interface ILT {
    function rate() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Update mining rate and supply at the start of the epoch
     * @dev   Callable by any address, but only once per epoch
     *        Total supply becomes slightly larger if this function is called late
     */
    function updateMiningParameters() external;

    /**
     * @notice Get timestamp of the next mining epoch start while simultaneously updating mining parameters
     * @return Timestamp of the next epoch
     */
    function futureEpochTimeWrite() external returns (uint256);
}

interface IGaugeController {
    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauge
     * @param addr Gauge address
     */
    function checkpointGauge(address addr) external;

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gaugeAddress Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address gaugeAddress, uint256 time) external view returns (uint256);
}

interface IMinter {
    function mint(address gaugeAddress) external;
}

contract TransmitEmissionsGauge is Ownable2Step {
    event UpdateReceiver(address oldReceiver, address newReceiver);
    event UpdateStatus(bool isKilled, uint timestamp);

    struct InflationParams {
        uint256 rate;
        uint256 finishTime;
    }

    uint256 private constant WEEK = 604800;
    uint256 private constant YEAR = 86400 * 365;
    uint256 private constant RATE_DENOMINATOR = 10 ** 18;
    uint256 private constant RATE_REDUCTION_COEFFICIENT = 1189207115002721024; // 2 ** (1/4) * 1e18
    uint256 private constant RATE_REDUCTION_TIME = YEAR;

    address public immutable ltToken;
    address public immutable minter;
    address public immutable gaugeController;
    address public receiver; // receive the lt token

    uint256 public lastPeriod;
    uint256 public totalEmissions;

    bool public isKilled;

    InflationParams public inflationParams;

    constructor(address _ltToken, address _gaugeController, address _minter, address _receiver) {
        require(_ltToken != address(0), "CANNOT BE ZERO ADDRESS");
        require(_gaugeController != address(0), "CANNOT BE ZERO ADDRESS");
        require(_minter != address(0), "CANNOT BE ZERO ADDRESS");
        require(_receiver != address(0), "CANNOT BE ZERO ADDRESS");
        ltToken = _ltToken;
        gaugeController = _gaugeController;
        minter = _minter;
        receiver = _receiver;

        inflationParams = InflationParams({rate: ILT(_ltToken).rate(), finishTime: ILT(_ltToken).futureEpochTimeWrite()});
        assert(inflationParams.rate != 0);

        lastPeriod = block.timestamp / WEEK;

        emit UpdateReceiver(address(0), _receiver);
    }

    /***
     * @notice Mint any new emissions and transmit to receiver, can be called by anyone
     */
    function transmitEmissions() external {
        IMinter(minter).mint(address(this));
        uint256 minted = ILT(ltToken).balanceOf(address(this));
        assert(minted != 0);
        TransferHelper.doTransferOut(ltToken, receiver, minted);
    }

    /***
     * @notice Query the total emissions `_user` is entitled to
     * @dev Any value of `_user` other than the gauge address will return 0
     */
    function integrateFraction(address _user) external view returns (uint256) {
        if (_user == address(this)) return totalEmissions;
        return 0;
    }

    /***
     * @notice Checkpoint the gauge updating total emissions
     * @dev _user Vestigial parameter with no impact on the function
     */
    function userCheckpoint(address _user) external returns (bool) {
        uint256 _lastPeriod = lastPeriod;
        uint256 currentPeriod = block.timestamp / WEEK;

        //only checkpoint if the current period is greater than the last period
        //last period is always less than or equal to current period and we only calculate
        //emissions up to current period (not including it)
        if (_lastPeriod != currentPeriod) {
            //checkpoint the gauge filling in any missing weight data
            IGaugeController(gaugeController).checkpointGauge(address(this));

            InflationParams memory _inflationParams = inflationParams;
            uint256 emissions = 0;
            //only calculate emissions for at most 256 periods since the last checkpoint
            for (uint256 i = _lastPeriod; i < _lastPeriod + 256; i++) {
                if (i == currentPeriod) break;
                uint256 periodTime = i * WEEK;
                uint256 weight = IGaugeController(gaugeController).gaugeRelativeWeight(address(this), periodTime);
                if (periodTime <= _inflationParams.finishTime && _inflationParams.finishTime < periodTime + WEEK) {
                    //calculate with old rate
                    emissions += (weight * _inflationParams.rate * (_inflationParams.finishTime - periodTime)) / 10 ** 18;
                    //update rate
                    _inflationParams.rate = (_inflationParams.rate * RATE_DENOMINATOR) / RATE_REDUCTION_COEFFICIENT;
                    //calculate with new rate
                    emissions += (weight * _inflationParams.rate * (periodTime + WEEK - _inflationParams.finishTime)) / 10 ** 18;
                    //update finish time
                    _inflationParams.finishTime += RATE_REDUCTION_TIME;
                    //update storage
                    inflationParams = _inflationParams;
                } else {
                    emissions += (weight * _inflationParams.rate * WEEK) / 10 ** 18;
                }
            }

            lastPeriod = currentPeriod;
            totalEmissions += emissions;
        }

        return true;
    }

    /***
     * @notice Set the killed status for this contract
     * @dev When killed, the gauge always yields a rate of 0 and so cannot mint LT
     * @param _is_killed Killed status to set
     */
    function setKilled(bool _isKilled) external onlyOwner {
        if (_isKilled) {
            inflationParams.rate = 0;
        } else {
            inflationParams.rate = ILT(ltToken).rate();
            inflationParams.finishTime = ILT(ltToken).futureEpochTimeWrite();
            lastPeriod = block.timestamp / WEEK;
        }

        isKilled = _isKilled;

        emit UpdateStatus(_isKilled, block.timestamp);
    }

    /***
     * @notice update the receiver
     * @param newReceiver the new receiver
     */
    function updateReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0), "CANNOT BE ZERO ADDRESS");
        require(newReceiver != receiver, "THE SAME RECEIVER");
        receiver = newReceiver;
        emit UpdateReceiver(receiver, newReceiver);
    }
}
