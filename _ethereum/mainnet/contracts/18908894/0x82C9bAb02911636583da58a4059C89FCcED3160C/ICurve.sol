// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title ICurvePool interface
 * @author Dollet Team
 * @notice Curve pool interface. This interface defines the functions for interacting with the Curve pool contract.
 */
interface ICurvePool {
    /**
     * @notice Performs an exchange inside of pool.
     * @param _i Index of the `from` token.
     * @param _j Index of the `to` token.
     * @param _dx Desired output amount.
     * @param _minDy Minimum final output token received in an exchange.
     */
    function exchange(uint256 _i, uint256 _j, uint256 _dx, uint256 _minDy) external payable;

    /**
     * @notice Performs an exchange inside of pool.
     * @param _i Index of the `from` token.
     * @param _j Index of the `to` token.
     * @param _dx Desired output amount.
     * @param _minDy Minimum final output token received in an exchange.
     */
    function exchange(int128 _i, int128 _j, uint256 _dx, uint256 _minDy) external payable;

    /**
     * @notice Returns the address of the token at an index.
     * @param _i Index of the token to get the address for.
     * @return The address of the token at an index.
     */
    function coins(uint256 _i) external view returns (address);

    /**
     * @notice Returns price of a Curve pair token given in another Curve pair token.
     * @param _i Index of the `from` token.
     * @param _j Index of the `to` token.
     * @param _dx Decimal precision.
     */
    function get_dy(int128 _i, int128 _j, uint256 _dx) external view returns (uint256);
}
