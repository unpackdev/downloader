// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IFeesManager
 * @author pNetwork
 *
 * @notice
 */
interface IFeesManager {
    /**
     * @dev Emitted when a fee is deposited.
     *
     * @param asset The asset address
     * @param epoch The epoch
     * @param amount The amount
     */
    event FeeDeposited(address indexed asset, uint256 indexed epoch, uint256 amount);

    /**
     * @dev Emitted when an user claims a fee for a given epoch.
     *
     * @param owner The owner addres
     * @param sentinel The sentinel addres
     * @param epoch The epoch
     * @param asset The asset addres
     * @param amount The amount
     */
    event FeeClaimed(
        address indexed owner,
        address indexed sentinel,
        uint256 indexed epoch,
        address asset,
        uint256 amount
    );

    /*
     * @notice Claim a fee for a given asset in a specific epoch.
     *
     * @param asset
     * @param epoch
     *
     */
    function claimFeeByEpoch(address asset, uint16 epoch) external;

    /*
     * @notice Claim a fee for a given asset in an epochs range.
     *
     * @param asset
     * @param startEpoch
     * @param endEpoch
     *
     */
    function claimFeeByEpochsRange(address asset, uint16 startEpoch, uint16 endEpoch) external;

    /*
     * @notice Indicates the claimable asset fee amount in a specific epoch.
     *
     * @paran sentinel
     * @param asset
     * @param epoch
     *
     * @return uint256 an integer representing the claimable asset fee amount in a specific epoch.
     */
    function claimableFeeByEpochOf(address sentinel, address asset, uint16 epoch) external view returns (uint256);

    /*
     * @notice Indicates the claimable asset fee amount in an epochs range.
     *
     * @paran sentinel
     * @param assets
     * @param startEpoch
     * @param endEpoch
     *
     * @return uint256 an integer representing the claimable asset fee amount in an epochs range.
     */
    function claimableFeesByEpochsRangeOf(
        address sentinel,
        address[] calldata assets,
        uint16 startEpoch,
        uint16 endEpoch
    ) external view returns (uint256[] memory);

    /*
     * @notice Deposit an asset fee amount in the current epoch.
     *
     * @param asset
     * @param amount
     *
     */
    function depositFee(address asset, uint256 amount) external;

    /*
     * @notice Indicates the K factor in a specific epoch. The K factor is calculated with the following formula: utilizationRatio^2 + minimumBorrowingFee
     *
     * @param epoch
     *
     * @return uint256 an integer representing the K factor in a specific epoch.
     */
    function kByEpoch(uint16 epoch) external view returns (uint256);

    /*
     * @notice Indicates the K factor in a specific epochs range.
     *
     * @param startEpoch
     * @params endEpoch
     *
     * @return uint256[] an integer representing the K factor in a specific epochs range.
     */
    function kByEpochsRange(uint16 startEpoch, uint16 endEpoch) external view returns (uint256[] memory);
}
