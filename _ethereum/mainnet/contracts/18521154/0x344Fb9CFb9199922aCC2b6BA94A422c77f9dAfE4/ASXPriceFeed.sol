// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./EnumerableSet.sol";
import "./RewardsBoosterErrors.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IOracle.sol";

/**
 * @title Asymetrix Protocol V2 ASXPriceFeed
 * @author Asymetrix Protocol Inc Team
 * @notice A price feed for ASX token that uses different oracles to calculate average ASX price in USD.
 */
contract ASXPriceFeed is Ownable, IOracle {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    EnumerableSet.AddressSet private oracles;

    /**
     * @notice Deploy the ASXPriceFeed contract.
     * @param _oracles Oracles' addresses that will be used in time of ASX pricing.
     */
    constructor(address[] memory _oracles) {
        for (uint256 _i; _i < _oracles.length; ++_i) {
            onlyValidOracle(_oracles[_i]);
            oracles.add(_oracles[_i]);
        }
    }

    /**
     * @notice Adds a new oracle to the price feed by an owner.
     * @param _oracle An oracle address to add.
     */
    function addOracle(address _oracle) external onlyOwner {
        onlyValidOracle(_oracle);
        oracles.add(_oracle);
    }

    /**
     * @notice Adds an oracle from the price feed by an owner.
     * @param _oracle An oracle address to remove.
     */
    function removeOracle(address _oracle) external onlyOwner {
        oracles.remove(_oracle);
    }

    /**
     * @notice Returns oracles' addresses that are used in time of ASX pricing.
     * @return Oracles' addresses.
     */
    function getOracles() external view returns (address[] memory) {
        return oracles.values();
    }

    /// @inheritdoc IOracle
    function latestAnswer() external view returns (int256 _answer) {
        return getLatestAnswer();
    }

    /// @inheritdoc IOracle
    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound)
    {
        return (0, getLatestAnswer(), block.timestamp, block.timestamp, 0);
    }

    /// @inheritdoc IOracle
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @notice Checks if an oracle address is a contract.
     * @param _oracle An oracle address to check.
     */
    function onlyValidOracle(address _oracle) private view {
        if (!_oracle.isContract()) revert RewardsBoosterErrors.NotContract();
    }

    /**
     * @notice Returns the latest answer.
     * @return The latest answer.
     */
    function getLatestAnswer() private view returns (int256) {
        uint256 _length = oracles.length();
        uint256 _totalPrice;

        for (uint256 _i; _i < _length; ++_i) {
            IOracle _oracle = IOracle(oracles.at(_i));

            _totalPrice += (uint256(_oracle.latestAnswer()) * 10 ** decimals()) / 10 ** _oracle.decimals();
        }

        return int256(_totalPrice / _length);
    }
}
