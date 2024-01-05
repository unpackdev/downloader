// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title SLARegistry
 * @dev SLARegistry is a contract for handling creation of service level
 * agreements and keeping track of the created agreements
 */
contract PeriodRegistry is Ownable {
    using SafeMath for uint256;

    enum PeriodType {Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly}

    /// @dev struct to store the definition of a period
    struct PeriodDefinition {
        bool initialized;
        uint256[] starts;
        uint256[] ends;
    }

    /// @dev (periodType=>PeriodDefinition) hourly/weekly/biWeekly/monthly/yearly are periodTypes
    mapping(PeriodType => PeriodDefinition) public periodDefinitions;

    /**
     * @dev event to log a new period initialized
     *@param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param periodsAdded 2. amount of periods added
     */
    event PeriodInitialized(PeriodType periodType, uint256 periodsAdded);

    /**
     * @dev event to log a new period initialized
     *@param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param periodsAdded 2. amount of periods added
     */
    event PeriodModified(PeriodType periodType, uint256 periodsAdded);

    /**
     * @dev public function for creating canonical service level agreements
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodStarts 2. array of the starts of the period
     *@param _periodEnds 3. array of the ends of the period
     */
    function initializePeriod(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) public onlyOwner {
        PeriodDefinition storage periodDefinition =
            periodDefinitions[_periodType];
        require(
            !periodDefinition.initialized,
            "Period type already initialized"
        );
        require(
            _periodStarts.length == _periodEnds.length,
            "Period type starts and ends should match"
        );
        require(_periodStarts.length > 0, "Period length can't be 0");
        for (uint256 index = 0; index < _periodStarts.length; index++) {
            require(
                _periodStarts[index] < _periodEnds[index],
                "Start should be before end"
            );
            if (index < _periodStarts.length - 1) {
                require(
                    _periodStarts[index + 1].sub(_periodEnds[index]) == 1,
                    "Start of a period should be 1 second after the end of the previous period"
                );
            }
            periodDefinition.starts.push(_periodStarts[index]);
            periodDefinition.ends.push(_periodEnds[index]);
        }
        periodDefinition.initialized = true;
        emit PeriodInitialized(_periodType, _periodStarts.length);
    }

    /**
     * @dev function to add new periods to certain period type
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodStarts 2. array of uint256 of the period starts to add
     *@param _periodEnds 3. array of uint256 of the period starts to add
     */
    function addPeriodsToPeriodType(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) public onlyOwner {
        require(_periodStarts.length > 0, "Period length can't be 0");
        PeriodDefinition storage periodDefinition =
            periodDefinitions[_periodType];
        require(periodDefinition.initialized, "Period was not initialized yet");
        for (uint256 index = 0; index < _periodStarts.length; index++) {
            require(
                _periodStarts[index] < _periodEnds[index],
                "Start should be before end"
            );
            if (index < _periodStarts.length.sub(1)) {
                require(
                    _periodStarts[index + 1].sub(_periodEnds[index]) == 1,
                    "Start of a period should be 1 second after the end of the previous period"
                );
            }
            periodDefinition.starts.push(_periodStarts[index]);
            periodDefinition.ends.push(_periodEnds[index]);
        }
        emit PeriodModified(_periodType, _periodStarts.length);
    }

    /**
     * @dev public function to get the start and end of a period
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function getPeriodStartAndEnd(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (uint256 start, uint256 end)
    {
        start = periodDefinitions[_periodType].starts[_periodId];
        end = periodDefinitions[_periodType].ends[_periodId];
    }

    /**
     * @dev public function to check if a periodType id is initialized
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     */
    function isInitializedPeriod(PeriodType _periodType)
        public
        view
        returns (bool initialized)
    {
        PeriodDefinition memory periodDefinition =
            periodDefinitions[_periodType];
        initialized = periodDefinition.initialized;
    }

    /**
     * @dev public function to check if a period id is valid i.e. it belongs to the added id array
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function isValidPeriod(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (bool valid)
    {
        PeriodDefinition memory periodDefinition =
            periodDefinitions[_periodType];
        valid = periodDefinition.starts.length.sub(1) >= _periodId;
    }

    /**
     * @dev public function to check if a period has finished
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function periodIsFinished(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (bool finished)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            "Period data is not valid"
        );
        finished =
            periodDefinitions[_periodType].ends[_periodId] < block.timestamp;
    }

    /**
     * @dev public function to check if a period has started
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function periodHasStarted(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (bool started)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            "Period data is not valid"
        );
        started =
            periodDefinitions[_periodType].starts[_periodId] < block.timestamp;
    }

    /**
     * @dev public function to get the periodDefinitions
     */
    function getPeriodDefinitions()
        public
        view
        returns (PeriodDefinition[] memory)
    {
        // 6 period types
        PeriodDefinition[] memory periodDefinition = new PeriodDefinition[](6);
        periodDefinition[0] = periodDefinitions[PeriodType.Hourly];
        periodDefinition[1] = periodDefinitions[PeriodType.Daily];
        periodDefinition[2] = periodDefinitions[PeriodType.Weekly];
        periodDefinition[3] = periodDefinitions[PeriodType.BiWeekly];
        periodDefinition[4] = periodDefinitions[PeriodType.Monthly];
        periodDefinition[5] = periodDefinitions[PeriodType.Yearly];
        return periodDefinition;
    }
}
