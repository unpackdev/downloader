// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IAdminStructure.sol";

/**
 * @title Dollet IStrategyHelper
 * @author Dollet Team
 * @notice Interface for StrategyHelper contract.
 */
interface IStrategyHelper {
    /**
     * Structure for storing of swap path and the swap venue.
     */
    struct Path {
        address venue;
        bytes path;
    }

    /**
     * @notice Logs information when a new oracle was set.
     * @param _asset An asset address for which oracle was set.
     * @param _oracle A new oracle address.
     */
    event OracleSet(address indexed _asset, address indexed _oracle);

    /**
     * @notice Logs information when a new swap path was set.
     * @param _from From asset.
     * @param _to To asset.
     * @param _venue A venue which swap path was used.
     * @param _path A swap path itself.
     */
    event PathSet(address indexed _from, address indexed _to, address indexed _venue, bytes _path);

    /**
     * @notice Allows the super admin to change the admin structure contract.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a new oracle for the specified asset.
     * @param _asset An asset address for which to set an oracle.
     * @param _oracle A new oracle address.
     */
    function setOracle(address _asset, address _oracle) external;

    /**
     * @notice Sets a new swap path for two assets.
     * @param _from From asset.
     * @param _to To asset.
     * @param _venue A venue which swap path is used.
     * @param _path A swap path itself.
     */
    function setPath(address _from, address _to, address _venue, bytes calldata _path) external;

    /**
     * @notice Executes a swap of two assets.
     * @param _from From asset.
     * @param _to To asset.
     * @param _amount Amount of the first asset to swap.
     * @param _slippageTolerance Slippage tolerance percentage (with 2 decimals).
     * @param _recipient Recipient of the second asset.
     * @return _amountOut The second asset output amount.
     */
    function swap(
        address _from,
        address _to,
        uint256 _amount,
        uint16 _slippageTolerance,
        address _recipient
    )
        external
        returns (uint256 _amountOut);

    /**
     * @notice Returns an oracle address for the specified asset.
     * @param _asset An address of the asset for which to get the oracle address.
     * @return _oracle An oracle address for the specified asset.
     */
    function oracles(address _asset) external view returns (address _oracle);

    /**
     * @notice Returns the address of the venue where the swap should be executed and the swap path.
     * @param _from From asset.
     * @param _to To asset.
     * @return _venue The address of the venue where the swap should be executed.
     * @return _path The swap path.
     */
    function paths(address _from, address _to) external view returns (address _venue, bytes memory _path);

    /**
     * @notice Returns AdminStructure contract address.
     * @return _adminStructure AdminStructure contract address.
     */
    function adminStructure() external returns (IAdminStructure _adminStructure);

    /**
     * @notice Returns the price of the specified asset.
     * @param _asset The asset to get the price for.
     * @return _price The price of the specified asset.
     */
    function price(address _asset) external view returns (uint256 _price);

    /**
     * @notice Returns the value of the specified amount of the asset.
     * @param _asset The asset to value.
     * @param _amount The amount of asset to value.
     * @return _value The value of the specified amount of the asset.
     */
    function value(address _asset, uint256 _amount) external view returns (uint256 _value);

    /**
     * @notice Converts the first asset to the second asset.
     * @param _from From asset.
     * @param _to To asset.
     * @param _amount Amount of the first asset to convert.
     * @return _amountOut Amount of the second asset after the conversion.
     */
    function convert(address _from, address _to, uint256 _amount) external view returns (uint256 _amountOut);

    /**
     * @notice Returns 100.00% constant value (with to decimals).
     * @return 100.00% constant value (with to decimals).
     */
    function ONE_HUNDRED_PERCENTS() external pure returns (uint16);
}

/**
 * @title Dollet IStrategyHelperVenue
 * @author Dollet Team
 * @notice Interface for StrategyHelperVenue contracts.
 */
interface IStrategyHelperVenue {
    /**
     * @notice Executes a swap of two assets.
     * @param _asset First asset.
     * @param _path Path of the swap.
     * @param _amount Amount of the first asset to swap.
     * @param _minAmountOut Minimum output amount of the second asset.
     * @param _recipient Recipient of the second asset.
     * @param _deadline Deadline of the swap.
     */
    function swap(
        address _asset,
        bytes calldata _path,
        uint256 _amount,
        uint256 _minAmountOut,
        address _recipient,
        uint256 _deadline
    )
        external;
}
