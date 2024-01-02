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
     * @dev Emitted when a fee claim is redirected to the challenger who succesfully slashed the sentinel.
     *
     * @param sentinel The slashed sentinel
     * @param challenger The challenger
     * @param epoch The epoch
     */
    event ClaimRedirectedToChallenger(address indexed sentinel, address indexed challenger, uint16 indexed epoch);

    /**
     * @dev Emitted when a fee is deposited.
     *
     * @param asset The asset address
     * @param epoch The epoch
     * @param amount The amount
     */
    event FeeDeposited(address indexed asset, uint16 indexed epoch, uint256 amount);

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
        uint16 indexed epoch,
        address asset,
        uint256 amount
    );

    /*
     * @notice Claim a fee for a given asset in a specific epoch.
     *
     * @param owner
     * @param asset
     * @param epoch
     *
     */
    function claimFeeByEpoch(address owner, address asset, uint16 epoch) external;

    /*
     * @notice Claim a fee for a given asset in an epochs range.
     *
     * @param owner
     * @param asset
     * @param startEpoch
     * @param endEpoch
     *
     */
    function claimFeeByEpochsRange(address owner, address asset, uint16 startEpoch, uint16 endEpoch) external;

    /*
     * @notice Indicates the claimable asset fee amount in a specific epoch.
     *
     * @paran actor
     * @param asset
     * @param epoch
     *
     * @return uint256 an integer representing the claimable asset fee amount in a specific epoch.
     */
    function claimableFeeByEpochOf(address actor, address asset, uint16 epoch) external view returns (uint256);

    /*
     * @notice Indicates the claimable asset fee amount in an epochs range.
     *
     * @paran actor
     * @param assets
     * @param startEpoch
     * @param endEpoch
     *
     * @return uint256 an integer representing the claimable asset fee amount in an epochs range.
     */
    function claimableFeesByEpochsRangeOf(
        address actor,
        address[] calldata assets,
        uint16 startEpoch,
        uint16 endEpoch
    ) external view returns (uint256[] memory);

    /*
     * @notice returns the addresses of the challengers who are entitled to claim the fees in the event of slashing.
     *
     * @param actor
     * @param startEpoch
     * @params endEpoch
     *
     * @return address[] representing the addresses of the challengers who are entitled to claim the fees in the event of slashing.
     */
    function challengerClaimRedirectByEpochsRangeOf(
        address actor,
        uint16 startEpoch,
        uint16 endEpoch
    ) external view returns (address[] memory);

    /*
     * @notice returns the address of the challenger who are entitled to claim the fees in the event of slashing.
     *
     * @param actor
     * @params epoch
     *
     * @return address[] representing the address of the challenger who are entitled to claim the fees in the event of slashing.
     */
    function challengerClaimRedirectByEpochOf(address actor, uint16 epoch) external returns (address);

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

    /*
     * @notice Redirect the fees claiming to the challenger who succesfully slashed the sentinel/guardian for a given epoch.
     *         This function potentially allows to be called also for staking sentinel so it is up to who call it (RegistrationManager)
     *         to call it only for the borrowing sentinels.
     *
     * @param actor
     * @params challenger
     * @params epoch
     *
     */
    function redirectClaimToChallengerByEpoch(address actor, address challenger, uint16 epoch) external;
}
