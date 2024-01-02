//SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./AccessControlEnumerable.sol";
import "./Clones.sol";

import "./NFTStakingPool.sol";

/**
 * @title NFTStakingAggregator
 * @author gotbit
 * @notice Contract is an aggregator for staking pools. It is responsible for creating, initializing and freezing staking pools.
 */
contract NFTStakingAggregator is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN_ROLE =
        keccak256(abi.encodePacked('ADMIN_ROLE'));

    address payable[] public pools;

    address payable public immutable baseImplementation;

    // name => pool
    mapping(string => address) public poolByName;

    modifier onlySupportedPool(uint256 poolIndex) {
        require(poolIndex < pools.length, 'Pool not supported');
        _;
    }

    modifier onlyFundsManager(uint256 poolIndex) {
        address pool = pools[poolIndex];
        require(hasRole(roleForPool(pool), msg.sender), 'Not funds manager');
        _;
    }

    /// @notice Creates a new contract
    /// @param impl - NFT StakingPool base implementation address
    constructor(address payable impl) {
        require(impl != address(0), 'Impl 0x0');
        baseImplementation = impl;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Creates a role for each pool contract
    /// @param poolAddr - NFTStakingPool address
    /// @return role - bytes32 role hash("FUNDS_MANAGER_ROLE" + poolAddr)
    function roleForPool(address poolAddr) public pure returns (bytes32) {
        string memory role = 'FUNDS_MANAGER_ROLE';
        string memory roleStr = string.concat(
            role,
            string(abi.encodePacked(poolAddr))
        );
        return keccak256(abi.encode(roleStr));
    }

    /// @notice Adds bonus tokens to a pool
    /// @param poolIndex - NFTStakingPool index
    /// @param from - token holder
    /// @param amount - token amount
    function addBonusForPool(
        uint256 poolIndex,
        address from,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) onlySupportedPool(poolIndex) {
        NFTStakingPool(pools[poolIndex]).addBonus(from, amount);
    }

    /// @notice Creates a new pool
    /// @param rewardToken_ - reward token address
    /// @param nftConfigs_ - NFTConfig struct array
    /// @param periods_ - array of structs with stakingPeriods, APRs
    /// @param unstakeData_ - struct with instant / early unstake fees and instant / liquidation delays
    /// @param bonusToken_ - bonus token address
    /// @param bonusQuoteForUnstake_ - amount of a bonus quote which is given to a user after unstake
    function createPool(
        IERC20 rewardToken_,
        NFTStakingPool.NFTConfig[] calldata nftConfigs_,
        NFTStakingPool.Period[] calldata periods_,
        NFTStakingPool.UnstakeData calldata unstakeData_,
        IERC20 bonusToken_,
        uint256 bonusQuoteForUnstake_
    ) external onlyRole(ADMIN_ROLE) {
        address pool = Clones.clone(baseImplementation);

        NFTStakingPool(payable(pool)).initialize(
            rewardToken_,
            nftConfigs_,
            periods_,
            unstakeData_,
            bonusToken_,
            bonusQuoteForUnstake_
        );

        pools.push(payable(pool));
    }

    /// @notice Sets new name and image link for the pool contract
    /// @param pool - staking pool index in pools array
    /// @param name_ New name string
    /// @param imageLink_ New image link string
    function setNameAndLink(
        uint256 pool,
        string calldata name_,
        string calldata imageLink_
    ) external onlyRole(ADMIN_ROLE) onlySupportedPool(pool) {
        address payable poolAddr = pools[pool];
        require(poolByName[name_] == address(0), 'Name is already taken');
        // remove previous name
        string memory oldName = NFTStakingPool(poolAddr).name();
        if ((bytes(oldName)).length != 0) {
            // remove only if name has been set
            poolByName[oldName] = address(0);
        }
        // set the new name
        poolByName[name_] = poolAddr;
        NFTStakingPool(poolAddr).setNameAndLink(name_, imageLink_);
    }

    /// @notice Sets new whitelist for a certain nft in a pool
    /// @param pool - staking pool index in pools array
    /// @param nftIndex - nft index in pool
    /// @param whitelist_ New whitelist
    function setWhitelistForNFT(
        uint256 pool,
        uint256 nftIndex,
        NFTStakingPool.Range[] memory whitelist_
    ) external onlyRole(ADMIN_ROLE) onlySupportedPool(pool) {
        NFTStakingPool(pools[pool]).setWhitelist(nftIndex, whitelist_);
    }

    /// @notice Allows owner to liquidate stake position
    /// @param pool - staking pool index in pools array
    /// @param id Stake id
    /// @param transferFunds Flag (true if transfer principal and rewards to recepient address, else if leave funds on contract address)
    /// @param recepient Fees receiver address
    function liquidate(
        uint256 pool,
        uint256 id,
        bool transferFunds,
        address payable recepient
    ) external onlyRole(ADMIN_ROLE) onlySupportedPool(pool) {
        NFTStakingPool(pools[pool]).liquidate(id, transferFunds, recepient);
    }

    /// @notice Can withdraw extra funds from the pool contract (can be called by the owner only)
    /// @param pool - staking pool index in pools array
    /// @param recepient - recepient address
    /// @param amount - bonus amount
    function withdrawAvailableRewards(
        uint256 pool,
        address payable recepient,
        uint256 amount
    ) external onlySupportedPool(pool) onlyFundsManager(pool) {
        NFTStakingPool(pools[pool]).emergencyWithdrawFunds(recepient, amount);
    }

    /// @notice Can withdraw extra bonus tokens from the pool contract (can be called by the owner only)
    /// @param pool - staking pool index in pools array
    /// @param recepient - recepient address
    /// @param amount - bonus amount
    function withdrawAvailableBonus(
        uint256 pool,
        address recepient,
        uint256 amount
    ) external onlySupportedPool(pool) onlyFundsManager(pool) {
        NFTStakingPool(pools[pool]).emergencyWithdrawBonus(recepient, amount);
    }

    /// @notice Locks a specific staking pool
    /// @param pool - staking pool index in pools array
    function lockPool(
        uint256 pool
    ) external onlyRole(ADMIN_ROLE) onlySupportedPool(pool) {
        require(!NFTStakingPool(pools[pool]).paused(), 'Paused');
        NFTStakingPool(pools[pool]).setPaused(true);
    }

    /// @notice Unlocks a specific staking pool
    /// @param pool - staking pool index in pools array
    function unlockPool(
        uint256 pool
    ) external onlyRole(ADMIN_ROLE) onlySupportedPool(pool) {
        require(NFTStakingPool(pools[pool]).paused(), 'Unpaused');
        NFTStakingPool(pools[pool]).setPaused(false);
    }

    /// @notice Allows to get a slice of pools array
    /// @param offset Starting index in user ids array
    /// @param length return array length
    /// @return Array-slice of pools
    function getPoolsSlice(
        uint256 offset,
        uint256 length
    ) external view returns (address[] memory) {
        address[] memory res = new address[](length);
        for (uint256 i; i < length; ) {
            res[i] = pools[i + offset];
            unchecked {
                ++i;
            }
        }

        return res;
    }

    /// @notice Allows to get a length of pools array
    /// @return Length of user pools array
    function getPoolsLength() external view returns (uint256) {
        return pools.length;
    }
}
