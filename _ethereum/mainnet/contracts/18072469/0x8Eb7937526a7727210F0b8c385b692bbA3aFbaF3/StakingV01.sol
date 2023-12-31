// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {IERC20Metadata} from "IERC20Metadata.sol";

import {ChainId, Timestamp, blockTimestamp, thisChainId, toChainId, toTimestamp, zeroTimestamp} from "IBaseTypes.sol";
import {BaseTypes} from "BaseTypes.sol";
import {UFixed, UFixedType, gtz} from "UFixedMath.sol";
import {Version, toVersion, toVersionPart, zeroVersion} from "IVersionType.sol";
import {IVersionable} from "IVersionable.sol";
import {Versionable} from "Versionable.sol";
import {VersionedOwnable} from "VersionedOwnable.sol";

import {IInstanceServiceFacade} from "IInstanceServiceFacade.sol";
import {NftId, gtz} from "IChainNft.sol";
import {IChainRegistry, ChainRegistryV01, ObjectType} from "ChainRegistryV01.sol";

import {IStaking} from "IStaking.sol";


contract StakingV01 is
    BaseTypes,
    UFixedType,
    VersionedOwnable,
    IStaking
{
    uint256 public constant MAINNET_ID = 1;
    // dip coordinates
    address public constant DIP_CONTRACT_ADDRESS = 0xc719d010B63E5bbF2C0551872CD5316ED26AcD83;
    uint256 public constant DIP_DECIMALS = 18;

    // max annual dip staking reward rate at 33.3%
    uint256 public constant MAX_REWARD_RATE_VALUE = 333;
    int8 public constant MAX_REWARD_RATE_EXP = -3;
    uint256 public constant YEAR_DURATION = 365 days;

    // staking wallet (ccount holding dips)
    IERC20Metadata internal _dip; 

    UFixed internal _rewardRate; // current apr for staking rewards
    UFixed internal _rewardRateMax; // max apr for staking rewards
    uint256 internal _rewardBalance; // current balance of accumulated rewards 
    uint256 internal _rewardReserves; // available funds to fund reward payments

    uint256 internal _stakeBalance; // current balance of staked dips
    address internal _stakingWallet; // address that holds staked dips and reward reserves

    // keep track of object types supported for staking
    mapping(ObjectType targetType => bool isSupported) internal _stakingSupported;

    // keep track of stakes
    mapping(NftId id => StakeInfo info) internal _info; // metadata per stake
    mapping(NftId target => uint256 amountStaked) internal _targetStakeBalance; // current sum of stakes per target

    // keep track of staking rates
    mapping(ChainId chain => mapping(address token => UFixed rate)) internal _stakingRate;

    // link to chain registry
    IChainRegistry internal _registry;
    ChainRegistryV01 internal _registryConstant;

    // staking internal data
    Version internal _version;


    modifier onlySameChain(NftId id) {
        require(_registry.getNftInfo(id).chain == thisChainId(),
        "ERROR:STK-001:DIFFERENT_CHAIN_NOT_SUPPORTET");
        _;
    }


    modifier onlyApprovedToken(ChainId chain, address token) {
        NftId id = _registry.getTokenNftId(chain, token);
        require(gtz(id), "ERROR:STK-005:NOT_REGISTERED");
        IChainRegistry.NftInfo memory info = _registry.getNftInfo(id);
        require(info.objectType == _registryConstant.TOKEN(), "ERROR:STK-006:NOT_TOKEN");
        require(
            info.state == IChainRegistry.ObjectState.Approved, 
            "ERROR:STK-007:TOKEN_NOT_APPROVED");
        _;
    }


    modifier onlyStakeOwner(NftId id) {
        require(_registry.ownerOf(id) == msg.sender, "ERROR:STK-010:USER_NOT_OWNER");
        _;
    }


    // IMPORTANT 1. version needed for upgradable versions
    // _activate is using this to check if this is a new version
    // and if this version is higher than the last activated version
    function version()
        public
        virtual override(IVersionable, Versionable)
        pure
        returns(Version)
    {
        return toVersion(
            toVersionPart(1),
            toVersionPart(0),
            toVersionPart(0));
    }

    // IMPORTANT 2. activate implementation needed
    // is used by proxy admin in its upgrade function
    function activateAndSetOwner(address implementation, address newOwner, address activatedBy)
        external
        virtual override
        initializer
    {
        // ensure proper version history
        _activate(implementation, activatedBy);

        // initialize open zeppelin contracts
        __Ownable_init();

        // set main internal variables
        _version = version();

        _dip = IERC20Metadata(DIP_CONTRACT_ADDRESS);

        _stakeBalance = 0;
        _stakingWallet = address(this);

        _rewardReserves = 0;
        _rewardRate = itof(0);
        _rewardRateMax = itof(MAX_REWARD_RATE_VALUE, MAX_REWARD_RATE_EXP);

        transferOwnership(newOwner);
    }


    function setStakingWallet(address stakingWalletNew)
        external
        virtual override
        onlyOwner
    {
        require(stakingWalletNew != address(0), "ERROR:STK-030:STAKING_WALLET_ZERO");
        require(stakingWalletNew != _stakingWallet, "ERROR:STK-031:STAKING_WALLET_SAME");

        address stakingWalletOld = _stakingWallet;
        _stakingWallet = stakingWalletNew;

        // special case: current wallet is staking contract and dip is set
        if(stakingWalletOld == address(this) && address(_dip) != address(0)) {
            uint256 amount = _dip.balanceOf(stakingWalletOld);

            if(amount > 0) {
                bool success = _dip.transfer(stakingWalletNew, amount);
                require(success, "ERROR:STK-032:DIP_TRANSFER_FAILED");
            }
        }

        emit LogStakingWalletChanged(msg.sender, stakingWalletOld, stakingWalletNew);
    }


    // only for testing purposes!
    // decide if this should be restricted to ganache chain ids
    function setDipContract(address dipToken) 
        external
        virtual
        onlyOwner
    {
        require(block.chainid != MAINNET_ID, "ERROR:STK-040:DIP_ADDRESS_CHANGE_NOT_ALLOWED_ON_MAINNET");
        require(dipToken != address(0), "ERROR:STK-041:DIP_CONTRACT_ADDRESS_ZERO");

        _dip = IERC20Metadata(dipToken);
        require(_dip.decimals() == DIP_DECIMALS, "ERROR:STK-042:DIP_DECIMALS_INVALID");
    }

    // sets the on-chain registry that keeps track of all protocol objects on this chain
    function setRegistry(address registryAddress)
        external
        virtual
        onlyOwner
    {
        require(address(_registry) == address(0), "ERROR:STK-050:REGISTRY_ALREADY_SET");
        require(registryAddress != address(0), "ERROR:STK-051:REGISTRY_ADDRESS_ZERO");
        IChainRegistry registryContract = IChainRegistry(registryAddress);

        require(registryContract.implementsIChainRegistry(), "ERROR:STK-052:NOT_CHAINREGISTRY");
        require(registryContract.version() > zeroVersion(), "ERROR:STK-053:REGISTRY_VERSION_ZERO");

        _registry = registryContract;
        _registryConstant = ChainRegistryV01(registryAddress);

        // setting of staking support per object type
        // _stakingSupported[_registryConstant.PROTOCOL()] = false;
        // _stakingSupported[_registryConstant.INSTANCE()] = false;
        // _stakingSupported[_registryConstant.PRODUCT()] = false;
        // _stakingSupported[_registryConstant.ORACLE()] = false;
        // _stakingSupported[_registryConstant.RISKPOOL()] = false;
        _stakingSupported[_registryConstant.BUNDLE()] = true;
    }


    function refillRewardReserves(uint256 dipAmount)
        external
        virtual override
    {
        require(dipAmount > 0, "ERROR:STK-080:DIP_AMOUNT_ZERO");

        address user = msg.sender;
        _collectRewardDip(user, dipAmount);
    }


    function withdrawRewardReserves(uint256 dipAmount)
        external
        virtual override
        onlyOwner
    {
        require(dipAmount > 0, "ERROR:STK-090:DIP_AMOUNT_ZERO");

        _withdrawRewardDip(owner(), dipAmount);
    }


    function setRewardRate(UFixed newRewardRate)
        external
        virtual override
        onlyOwner
    {
        require(newRewardRate <= _rewardRateMax, "ERROR:STK-100:REWARD_EXCEEDS_MAX_VALUE");
        UFixed oldRewardRate = _rewardRate;

        _rewardRate = newRewardRate;

        emit LogStakingRewardRateSet(owner(), oldRewardRate, _rewardRate);
    }


    function setStakingRate(
        ChainId chain,
        address token,
        UFixed newStakingRate
    )
        external
        virtual override
        onlyOwner
        onlyApprovedToken(chain, token)
    {
        require(gtz(newStakingRate), "ERROR:STK-110:STAKING_RATE_ZERO");

        UFixed oldStakingRate = _stakingRate[chain][token];
        _stakingRate[chain][token] = newStakingRate;

        emit LogStakingStakingRateSet(owner(), chain, token, oldStakingRate, newStakingRate);
    }


    function createStake(NftId target, uint256 dipAmount)
        external
        virtual override
        returns(NftId stakeId)
    {
        // no validation here, validation is done via calling stake() at the end
        address user = msg.sender;
        stakeId = _registry.registerStake(target, user);

        StakeInfo storage info = _info[stakeId];
        info.id = stakeId;
        info.target = target;
        info.stakeBalance = 0;
        info.rewardBalance = 0;
        info.createdAt = blockTimestamp();
        info.version = version();

        stake(stakeId, dipAmount);

        emit LogStakingNewStakeCreated(target, user, stakeId);
    }


    function createStakeWithSignature(address, NftId, uint256, bytes32, bytes calldata) 
        external 
        virtual
        returns(NftId) 
    {
        require(false, "ERROR:STK-120:NOT_SUPPORTED");
    }

    function restake(NftId, NftId)
        external
        virtual override
    {
        require(false, "ERROR:STK-123:NOT_SUPPORTED");
    }

    function restakeWithSignature(address, NftId, NftId, bytes32, bytes calldata)
        external
        virtual
    {
        require(false, "ERROR:STK-121:NOT_SUPPORTED");
    }

    function isUnstakingAvailable(NftId)
        public
        virtual override
        view 
        returns(bool)
    {
        require(false, "ERROR:STK-122:NOT_SUPPORTED");
    }



    function stake(NftId stakeId, uint256 dipAmount)
        public
        virtual override
    {
        // input validation (stake needs to exist)
        StakeInfo storage info = _info[stakeId];
        require(info.createdAt > zeroTimestamp(), "ERROR:STK-150:STAKE_NOT_EXISTING");
        require(dipAmount > 0, "ERROR:STK-151:STAKING_AMOUNT_ZERO");

        // staking needs to be possible (might change over time)
        require(isStakingSupported(info.target), "ERROR:STK-152:STAKING_NOT_SUPPORTED");
        address user = msg.sender;

        // update stake info
        _updateRewards(info);
        _increaseStakes(info, dipAmount);
        _collectDip(user, dipAmount);

        emit LogStakingStaked(info.target, user, stakeId, dipAmount, info.stakeBalance);
    }



    function unstake(NftId stakeId, uint256 amount)
        external
        virtual override
        onlyStakeOwner(stakeId)        
    {
        _unstake(stakeId, msg.sender, amount);
    }


    function unstakeAndClaimRewards(NftId stakeId)
        external
        virtual override
        onlyStakeOwner(stakeId)     
    {
        _unstake(stakeId, msg.sender, type(uint256).max);
    }


    function claimRewards(NftId stakeId)
        external
        virtual override
        onlyStakeOwner(stakeId)        
    {
        address user = msg.sender;
        StakeInfo storage info = _info[stakeId];

        _claimRewards(user, info);
    }

    //--- view and pure functions ------------------//

    function rewardRate()
        external
        virtual override
        view
        returns(UFixed)
    {
        return _rewardRate;
    }


    function getTargetRewardRate(NftId)
        public
        virtual
        view
        returns(UFixed)
    {
        return _rewardRate;
    }


    function rewardBalance()
        external
        virtual override
        view
        returns(uint256 dips)
    {
        return _rewardBalance;
    }


    function rewardReserves()
        external
        virtual override
        view
        returns(uint256 dips)
    {
        return _rewardReserves;
    }


    function stakeBalance()
        external
        virtual override
        view
        returns(uint256 dips)
    {
        return _stakeBalance;
    }


    function stakingRate(ChainId chain, address token)
        external 
        virtual override
        view
        returns(UFixed rate)
    {
        return _stakingRate[chain][token];
    }


    function getStakingWallet() 
        external
        virtual override
        view
        returns(address stakingWallet)
    {
        return _stakingWallet;
    }


    function getDip() 
        external 
        virtual override
        view 
        returns(IERC20Metadata dip)
    {
        return _dip;
    }


    function getInfo(NftId id)
        external override
        view
        returns(StakeInfo memory info)
    {
        require(_info[id].createdAt > zeroTimestamp(), "ERROR:STK-190:STAKE_INFO_NOT_EXISTING");
        return _info[id];
    }


    function isStakingSupportedForType(ObjectType targetType)
        external
        virtual override
        view
        returns(bool isSupported)
    {
        return _stakingSupported[targetType];
    }


    function isStakingSupported(NftId target)
        public
        virtual override
        view 
        returns(bool isSupported)
    {
        ObjectType targetType = _registry.getNftInfo(target).objectType;
        if(!_stakingSupported[targetType]) {
            return false;
        }

        // deal with special cases
        if(targetType == _registryConstant.BUNDLE()) {
            return _isStakingSupportedForBundle(target);
        }

        return true;
    }


    function isUnstakingSupported(NftId target)
        public
        virtual override
        view 
        returns(bool isSupported)
    {
        ObjectType targetType = _registry.getNftInfo(target).objectType;
        if(!_stakingSupported[targetType]) {
            return false;
        }

        // deal with special cases
        if(targetType == _registryConstant.BUNDLE()) {
            return _isUnstakingSupportedForBundle(target);
        }

        return true;
    }


    function calculateRewardsIncrement(StakeInfo memory stakeInfo)
        public 
        virtual override
        view
        returns(uint256 rewardsAmount)
    {
        /* solhint-disable not-rely-on-time */
        require(block.timestamp >= toInt(stakeInfo.updatedAt), "ERROR:STK-200:UPDATED_AT_IN_FUTURE");
        uint256 timeSinceLastUpdate = block.timestamp - toInt(stakeInfo.updatedAt);
        /* solhint-enable not-rely-on-time */

        // TODO potentially reduce time depending on the time when the bundle has been closed

        rewardsAmount = calculateRewards(stakeInfo.stakeBalance, timeSinceLastUpdate);
    }


    function calculateRewards(
        uint256 amount,
        uint256 duration
    ) 
        public 
        virtual override
        view
        returns(uint256 rewardAmount) 
    {
        UFixed yearFraction = itof(duration) / itof(YEAR_DURATION);
        UFixed rewardDuration = _rewardRate * yearFraction;
        rewardAmount = ftoi(itof(amount) * rewardDuration);
    }


    function calculateRequiredStaking(
        ChainId chain,
        address token,
        uint256 tokenAmount
    )
        external
        virtual override
        view 
        returns(uint256 dipAmount)
    {
        require(gtz(_stakingRate[chain][token]), "ERROR:STK-210:TOKEN_STAKING_RATE_NOT_SET");

        UFixed rate = _stakingRate[chain][token];
        int8 decimals = int8(IERC20Metadata(token).decimals());
        UFixed dip = itof(tokenAmount, int8(uint8(DIP_DECIMALS)) - decimals) / rate;

        return ftoi(dip);
    }


    function calculateCapitalSupport(
        ChainId chain,
        address token,
        uint256 dipAmount
    )
        public
        virtual override
        view
        returns(uint256 tokenAmount)
    {
        require(gtz(_stakingRate[chain][token]), "ERROR:STK-211:TOKEN_STAKING_RATE_NOT_SET");

        int8 decimals = int8(IERC20Metadata(token).decimals());
        UFixed support = itof(dipAmount, decimals - int8(uint8(DIP_DECIMALS))) * _stakingRate[chain][token];

        return ftoi(support);
    }


    function stakes(NftId target)
        external
        virtual override
        view
        returns(uint256 dipAmount)
    {
        return _targetStakeBalance[target];
    }


    function capitalSupport(NftId target)
        external
        virtual override
        view 
        returns(uint256 capitalAmount)
    {
        IChainRegistry.NftInfo memory info = _registry.getNftInfo(target);

        // check target type staking support
        require(_stakingSupported[info.objectType], "ERROR:STK-220:TARGET_TYPE_NOT_SUPPORTED");
        require(info.objectType == _registryConstant.BUNDLE(), "ERROR:STK-221:TARGET_TYPE_NOT_BUNDLE");

        (,,, address token, , ) = _registry.decodeBundleData(target);

        return calculateCapitalSupport(
            info.chain, 
            token, 
            _targetStakeBalance[target]);
    }


    function toChain(uint256 chainId)
        external 
        virtual override
        pure
        returns(ChainId)
    {
        return toChainId(chainId);
    }


    function toRate(uint256 value, int8 exp)
        external
        virtual override
        pure
        returns(UFixed)
    {
        return itof(value, exp);
    }


    function rateDecimals()
        external
        virtual override
        pure
        returns(uint256)
    {
        return decimals();
    }


    function getRegistry()
        external 
        virtual override
        view 
        returns(IChainRegistry)
    {
        return _registry;
    }


    function getMessageHelperAddress()
        external
        virtual override 
        view 
        returns(address messageHelperAddress)
    {
        return address(0);
    }


    function maxRewardRate()
        external
        virtual override
        view
        returns(UFixed)
    {
        return _rewardRateMax;
    }


    function getBundleState(NftId target)
        public
        view
        onlySameChain(target)
        returns(
            IChainRegistry.ObjectState objectState,
            IInstanceServiceFacade.BundleState bundleState,
            Timestamp expiryAt
        )
    {
        IChainRegistry.NftInfo memory info = _registry.getNftInfo(target);
        require(info.objectType == _registryConstant.BUNDLE(), "ERROR:STK-230:OBJECT_TYPE_NOT_BUNDLE");

        // fill in object stae from registry info
        objectState = info.state;

        // read bundle data directly from instance/riskpool
        // can be done thanks to onlySameChain modifier
        (
            bytes32 instanceId,
            , // rikspool id not needed
            uint256 bundleId,
            , // token not needed
            , // display name not needed
            uint256 expiryAtUint
        ) = _registry.decodeBundleData(target);

        IInstanceServiceFacade instanceService = _registry.getInstanceServiceFacade(instanceId);
        IInstanceServiceFacade.Bundle memory bundle = instanceService.getBundle(bundleId);
        
        // fill in other properties from bundle info
        bundleState = bundle.state;
        expiryAt = toTimestamp(expiryAtUint);
    }

    //--- view and pure functions (target type specific) ------------------//

    function getBundleInfo(NftId bundleNft)
        external
        virtual override
        view
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName,
            IInstanceServiceFacade.BundleState bundleState,
            Timestamp expiryAt,
            bool stakingSupported,
            bool unstakingSupported,
            uint256 stakeAmount
        )
    {
        (
            instanceId,
            riskpoolId,
            bundleId,
            token,
            displayName,
            // expiry at 
        ) = _registry.decodeBundleData(bundleNft);

        (
            ,
            bundleState,
            expiryAt
        ) = getBundleState(bundleNft);

        stakingSupported = _isStakingSupportedForBundle(bundleNft);
        unstakingSupported = _isUnstakingSupportedForBundle(bundleNft);
        stakeAmount = _targetStakeBalance[bundleNft];
    }

    function implementsIStaking() external pure returns(bool) {
        return true;
    }

    //--- internal functions ------------------//

    function _isStakingSupportedForBundle(NftId target)
        internal
        virtual
        view
        returns(bool isSupported)
    {
        (
            , // not using IChainRegistry.ObjectState objectState
            IInstanceServiceFacade.BundleState bundleState,
            Timestamp expiryAt
        ) = getBundleState(target);

        // only active bundles are available for staking
        if(bundleState != IInstanceServiceFacade.BundleState.Active) {
            return false;
        }

        // only non-expired bundles are available for staking
        if(expiryAt > zeroTimestamp() && expiryAt < blockTimestamp()) {
            return false;
        }

        return true;
    }


    function _isUnstakingSupportedForBundle(NftId target)
        internal
        virtual
        view
        returns(bool isSupported)
    {
        (
            , // not using IChainRegistry.ObjectState objectState
            IInstanceServiceFacade.BundleState bundleState,
            Timestamp expiryAt
        ) = getBundleState(target);

        // only closed or burned bundles are available for staking
        if(bundleState == IInstanceServiceFacade.BundleState.Closed
            || bundleState == IInstanceServiceFacade.BundleState.Burned)
        {
            return true;
        }

        // expired bundles are available for unstaking
        if(expiryAt > zeroTimestamp() && expiryAt < blockTimestamp()) {
            return true;
        }

        return false;
    }


    function _increaseStakes(
        StakeInfo storage info,
        uint256 amount
    )
        internal
        virtual
    {
        _targetStakeBalance[info.target] += amount;
        _stakeBalance += amount;

        info.stakeBalance += amount;
        info.updatedAt = blockTimestamp();
    }


    function _unstake(
        NftId id,
        address user, 
        uint256 amount
    ) 
        internal
        virtual
    {
        StakeInfo storage info = _info[id];
        require(this.isUnstakingSupported(info.target), "ERROR:STK-250:UNSTAKE_NOT_SUPPORTED");
        require(amount > 0, "ERROR:STK-251:UNSTAKE_AMOUNT_ZERO");

        _updateRewards(info);

        bool unstakeAll = (amount == type(uint256).max);
        if(unstakeAll) {
            amount = info.stakeBalance;
        }

        _decreaseStakes(info, amount);
        _withdrawDip(user, amount);

        emit LogStakingUnstaked(
            info.target,
            user,
            info.id,
            amount,
            info.stakeBalance
        );

        if(unstakeAll) {
            _claimRewards(user, info);
        }
    }


    function _claimRewards(
        address user,
        StakeInfo storage info
    )
        internal
        virtual
    {
        uint256 amount = info.rewardBalance;

        // ensure reward payout is within avaliable reward reserves
        if(amount > _rewardReserves) {
            amount = _rewardReserves;
        }

        // book keeping
        _decreaseRewards(info, amount);
        _rewardReserves -= amount;

        // transfer of dip
        _withdrawDip(user, amount);
    }


    function _updateRewards(StakeInfo storage info)
        internal
        virtual
    {
        uint256 amount = calculateRewardsIncrement(info);
        _rewardBalance += amount;

        info.rewardBalance += amount;
        info.updatedAt = blockTimestamp();

        emit LogStakingRewardsUpdated(
            info.id,
            amount,
            info.rewardBalance
        );
    }


    function _decreaseStakes(
        StakeInfo storage info,
        uint256 amount
    )
        internal
        virtual
    {
        require(amount <= info.stakeBalance, "ERROR:STK-270:UNSTAKING_AMOUNT_EXCEEDS_STAKING_BALANCE");

        _targetStakeBalance[info.target] -= amount;
        _stakeBalance -= amount;

        info.stakeBalance -= amount;
        info.updatedAt = blockTimestamp();
    }


    function _decreaseRewards(StakeInfo storage info, uint256 amount)
        internal
        virtual
    {
        info.rewardBalance -= amount;
        info.updatedAt = blockTimestamp();

        _rewardBalance -= amount;

        emit LogStakingRewardsClaimed(
            info.id,
            amount,
            info.rewardBalance
        );
    }


    function _collectRewardDip(address user, uint256 amount)
        internal
        virtual
    {
        _rewardReserves += amount;
        _collectDip(user, amount);

        emit LogStakingRewardReservesIncreased(user, amount, _rewardReserves);
    }


    function _withdrawRewardDip(address user, uint256 amount)
        internal
        virtual
    {
        require(_rewardReserves >= amount, "ERROR:STK-280:DIP_RESERVES_INSUFFICIENT");

        _rewardReserves -= amount;
        _withdrawDip(owner(), amount);

        emit LogStakingRewardReservesDecreased(user, amount, _rewardReserves);
    }


    function _collectDip(address user, uint256 amount)
        internal
        virtual
    {
        require(_dip.balanceOf(user) >= amount, "ERROR:STK-290:DIP_BALANCE_INSUFFICIENT");
        require(_dip.allowance(user, address(this)) >= amount, "ERROR:STK-291:DIP_ALLOWANCE_INSUFFICIENT");

        bool success = _dip.transferFrom(user, _stakingWallet, amount);

        require(success, "ERROR:STK-292:DIP_TRANSFER_FROM_FAILED");
    }


    function _withdrawDip(address user, uint256 amount)
        internal
        virtual
    {
        require(_dip.balanceOf(_stakingWallet) >= amount, "ERROR:STK-300:DIP_BALANCE_INSUFFICIENT");

        bool success;

        if(_stakingWallet != address(this)) {
            require(_dip.allowance(_stakingWallet, address(this)) >= amount, "ERROR:STK-301:DIP_ALLOWANCE_INSUFFICIENT");
            success = _dip.transferFrom(_stakingWallet, user, amount);
        } else {
            success = _dip.transfer(user, amount);
        }

        require(success, "ERROR:STK-302:DIP_TRANSFER_FROM_FAILED");
    }
}
