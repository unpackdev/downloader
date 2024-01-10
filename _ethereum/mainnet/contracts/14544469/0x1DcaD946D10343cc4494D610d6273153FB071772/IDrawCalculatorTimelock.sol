// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./IDrawCalculator.sol";

interface IDrawCalculatorTimelock {
    /**
     * @notice Emitted when target draw id is locked.
     * @param timestamp The epoch timestamp to unlock the current locked Draw
     * @param drawId    The Draw to unlock
     */
    struct Timelock {
        uint64 timestamp;
        uint32 drawId;
    }

    /**
     * @notice Emitted when target draw id is locked.
     * @param drawId    Draw ID
     * @param timestamp Block timestamp
     */
    event LockedDraw(uint32 indexed drawId, uint64 timestamp);

    /**
     * @notice Emitted event when the timelock struct is updated
     * @param timelock Timelock struct set
     */
    event TimelockSet(Timelock timelock);

    /**
     * @notice Routes claim/calculate requests between PrizeDistributor and DrawCalculator.
     * @dev    Will enforce a "cooldown" period between when a Draw is pushed and when users can start to claim prizes.
     * @param user    User address
     * @param drawIds Draw.drawId
     * @param data    Encoded pick indices
     * @return Prizes awardable array
     */
    function calculate(
        address user,
        uint32[] calldata drawIds,
        bytes calldata data
    ) external view returns (uint256[] memory, bytes memory);

    /**
     * @notice Lock passed draw id for `timelockDuration` seconds.
     * @dev    Restricts new draws by forcing a push timelock.
     * @param _drawId Draw id to lock.
     * @param _timestamp Epoch timestamp to unlock the draw.
     * @return True if operation was successful.
     */
    function lock(uint32 _drawId, uint64 _timestamp) external returns (bool);

    /**
     * @notice Read internal DrawCalculator variable.
     * @return IDrawCalculator
     */
    function getDrawCalculator() external view returns (IDrawCalculator);

    /**
     * @notice Read internal Timelock struct.
     * @return Timelock
     */
    function getTimelock() external view returns (Timelock memory);

    /**
     * @notice Set the Timelock struct. Only callable by the contract owner.
     * @param _timelock Timelock struct to set.
     */
    function setTimelock(Timelock memory _timelock) external;

    /**
     * @notice Returns bool for timelockDuration elapsing.
     * @return True if timelockDuration, since last timelock has elapsed, false otherwise.
     */
    function hasElapsed() external view returns (bool);
}
