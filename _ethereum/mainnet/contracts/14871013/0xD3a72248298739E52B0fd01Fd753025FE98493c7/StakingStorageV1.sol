// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >= 0.8.0;

/// @dev
/// A `Pool` refers to the different "pools" users can lock their CNV into.
///
/// When a user locks into a `Pool`, their CNV cannot be withdrawn for a duration
/// of `term` seconds. The amount a user locks determines the amount of shares
/// they get of this `Pool`. This amount of shares is calculated by:
///
/// shares = amount * (pool.balance / pool.supply)
///
/// The pool `balance` is then increased by the amount locked, and the pool
/// `supply` is increased by the amount of shares.
///
/// On each rebase the percent change in CNV since last rebase is calculated,
/// and `g` determines how much of that percent change will be assigned to the
/// Pool. For example - if CNV supply increased by 10%, and `g` for a specific
/// pool is g=100%, then that pool will obtain a 10% increase in supply. These
/// are referred to as "anti-dilutive rewards". This increase in supply is
/// reflected by increasing the `balance` of the pool.
///
/// Additionally, on each rebase there are "excess rewards" given to each pool.
/// The amount of excess rewards each pool gets is determined by `excessRatio`,
/// and unlike "anti-dilutive rewards" these rewards are reflected by increasing
/// the `rewardsPerShare`.
///
/// When users unlock, the amount of shares they own is converted to an amount
/// of CNV:
///
/// amount = shares / (pool.balance / pool.supply)
///
/// this amount is then reduced from pool.balance, and the shares are reduced
/// from pool.supply.
struct Pool {
    uint64  term;                   // length in seconds a user must lock
    uint256 g;                      // pct of CNV supply growth to be matched to this pool on each rebase
    uint256 excessRatio;            // ratio of excess rewards for this pool on each rebase
    uint256 balance;                // balance of CNV locked (amount locked + anti-dilutive rewards)
    uint256 supply;                 // supply of shares of this pool assigned to users when they lock
    uint256 rewardsPerShare;        // index of excess rewards for each share
}

/// @dev
/// A `Position` refers to a users "position" when they lock into a Pool.
///
/// When a user locks into a Pool, they obtain a `Position` which contains the
/// `maturity` which is used to check when they can unlock their CNV, a `poolID`
/// which is used to then convert the amount of `shares` they own of that pool
/// into CNV, `shares` which is the number of shares they own of that pool to be
/// later converted into CNV, and `rewardDebt` which reflects the index of
/// pool rewardsPerShare at the time they entered the pool. This value is used
/// so that when they unlock, they only get the difference of current rewardsPerShare
/// and `rewardDebt`, thus only getting excess rewards for the time they were in
/// the pool and not for rewards distrobuted before they entered the Pool.
struct Position {
    uint32  poolID;                  // ID of pool to which position belongs to
    uint224 shares;                  // amount of pool shares assigned to this position
    uint32  maturity;                // timestamp when lock position can be unlocked
    uint224 rewardDebt;              // index of rewardsPerShare at time of entering pool
    uint256 deposit;                 // amount of CNV initially deposited on lock
}

contract StakingStorageV1 {

    /// @notice address of CNV ERC20 token, used to mint CNV rewards to this contract.
    address public CNV;

    /// @notice address of Bonding contract, used to retrieve information regarding
    /// bonding activity in a given rebase interval.
    address public BONDS;

    /// @notice address of COOP to send COOP funds to.
    address public COOP;

    /// @notice address of `ValueShuttle` contract. When Bonding occurs on
    /// `Bonding` contract, it sends all incoming bonded value to `VALUESHUTTLE`.
    /// Then during rebase, this contract calls `VALUESHUTTLE` to obtain
    /// the USD denominated value of bonding activity during rebase and instructs
    /// `ValueShuttle` to empty the funds to the Treasury.
    address public VALUESHUTTLE;

    /// @notice address of contract in charge of displaying lock position NFT
    address public URI_ADDRESS;

    /// @notice array containing pool info
    Pool[] public pools;

    /// @notice time in seconds that must pass before next rebase
    uint256 public rebaseInterval;

    /// @notice as an incentive for the public to call the "rebase()" method, and
    /// to not increase the gas of lock() and unlock() methods by including rebase
    /// in those methods, a rebase incentive is provided. This is an amount of CNV
    /// that will be transferred to callers of the "rebase()" method.
    uint256 public rebaseIncentive;

    /// @notice pct of CNV supply to be rewarded as excess rewards.
    /// @dev
    /// During each rebase, after anti-dilution rewards have been assigned, an
    /// additional "excess rewards" are distributed. The total amount of excess
    /// rewards to be distributed among all pools is given as a percentage of
    /// total CNV supply. For example - if apyPerRebase = 10%, then 10% of total
    /// CNV supply will be distributed to pools as "excess rewards".
    uint256 public apyPerRebase;

    /// @notice amount of CNV available to mint without breaking backing.
    /// @dev
    /// During Bonding activity, by design there is more value being received
    /// than CNV minted. This difference is accounted for in `globalExcess`.
    /// For example, if during bonding activity $100 has been accumulated and
    /// 70 CNV has been minted (for bonders, DAO, and anti-dilution rewards),
    /// then `globalExcess` will be increased by 30.
    ///
    /// This number also determines the availability of "excess rewards" as
    /// determined by `apyPerRebase`. For example - if a current rebase only
    /// produced an excess of 10 CNV, and `apyPerRebase` indicates that 20 CNV
    /// should be distributed, and `globalExcess` is 30, then rebasing will
    /// use from `globalExcess` to distribute those rewards and thus reduce
    /// globalExcess to 20.
    /// For this same logic - this numbers serves as a floor on excess rewards
    /// to prevent the protocol from minting more CNV than there is value in
    /// the Treasury.
    uint256 public globalExcess;

    //////////////////////////////

    /// @dev
    /// used to calculate the amount of CNV during each rebase that goes to COOP.
    /// see _calculateCOOPRate
    uint256 public coopRatePriceControl;

    /// @dev
    /// used to calculate the amount of CNV during each rebase that goes to COOP.
    /// see _calculateCOOPRate
    uint256 public haogegeControl;

    /// @dev
    /// used to calculate the amount of CNV during each rebase that goes to COOP.
    /// see _calculateCOOPRate
    uint256 public coopRateMax;

    /// @notice minimum CNV bond price denominated in USD (wad)
    /// used to calculate staking cap during _lock()
    uint256 public minPrice;

    /// @notice time of last rebase, used to determine whether a rebase is due.
    uint256 public lastRebaseTime;

    /// @notice supply of lock position NFTs, used for positionID
    uint256 public totalSupply;

    /// @notice amount of excess rewards in lock positions
    uint256 public lockedExcessRewards;

    /// @notice mapping that returns position info for a given NFT
    mapping(uint256 => Position) public positions;
}
