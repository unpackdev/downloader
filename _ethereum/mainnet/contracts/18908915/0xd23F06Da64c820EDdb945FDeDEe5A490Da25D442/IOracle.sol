// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet IOracle
 * @author Dollet Team
 * @notice An interface that all oracles implement.
 */
interface IOracle {
    /**
     * @notice Allows the super admin to change the admin structure contract.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Returns the latest answer.
     * @return The latest answer.
     */
    function latestAnswer() external view returns (int256);

    /**
     * @notice Returns the data from the latest round.
     * @return _roundId The round ID.
     * @return _answer The answer from the latest round.
     * @return _startedAt Timestamp of when the round started.
     * @return _updatedAt Timestamp of when the round was updated.
     * @return _answeredInRound Deprecated. Previously used when answers could take multiple rounds to be computed.
     */
    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound);

    /**
     * @notice Returns the number of decimals in the answer.
     * @return The number of decimals in the answer.
     */
    function decimals() external pure returns (uint8);
}
