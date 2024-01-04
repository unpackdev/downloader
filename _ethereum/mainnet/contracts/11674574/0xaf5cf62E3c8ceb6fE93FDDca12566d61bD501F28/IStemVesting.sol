pragma solidity >=0.6 <0.7.0;
pragma experimental ABIEncoderV2;


/**
* @title STEM token Interface
*/
interface IStemVesting {

    /// @dev Params of a vesting pool
    struct StemVestingPool {
        bool isRestricted; // if `true`, the 'wallet' only may trigger withdrawal
        uint32 startBlock;
        uint32 endBlock;
        uint32 lastVestedBlock;
        uint96 perBlockStemScaled; // scaled (multiplied) by 1e6
    }

    /**
     * @notice Initializes the contract, sets the token name and symbol, creates vesting pools
     * @param foundationWallet The foundation wallet
     * @param reserveWallet The reserve wallet
     * @param foundersWallet The founders wallet
     * @param marketWallet The market wallet
     */
    function initialize(
        address foundationWallet,
        address reserveWallet,
        address foundersWallet,
        address marketWallet
    ) external;

    /**
     * @notice Returns params of a vesting pool
     * @param wallet The address of the pool' wallet
     * @return Vesting pool params
     */
    function getVestingPoolParams(address wallet) external view returns(StemVestingPool memory);

    /**
     * @notice Returns the amount of STEM pending to be vested to a pool
     * @param wallet The address of the pool' wallet
     * @return amount Pending STEM token amount
     */
    function getPoolPendingStem(address wallet) external view returns(uint256 amount);

    /**
     * @notice Withdraw pending STEM tokens to a pool
     * @param wallet The address of the pool' wallet
     * @return amount Withdrawn STEM token amount
     */
    function withdrawPoolStem(address wallet) external returns (uint256 amount);

    /// @dev New vesting pool registered
    event VestingPool(address indexed wallet);
    /// @dev STEM tokens mint to a pool
    event StemWithdrawal(address indexed wallet, uint256 amount);
}
