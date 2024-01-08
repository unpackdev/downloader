// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IStaking.sol";

contract YieldFarm {
    // lib
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeERC20 for IERC20;

    // constants
    uint256 public TOTAL_DISTRIBUTED_AMOUNT;
    uint256 public NR_OF_EPOCHS;

    // state variables

    // addreses
    address private _poolTokenAddress;
    address private _communityVault;
    // contracts
    IERC20 private _bond;
    IStaking private _staking;

    uint256[] private epochs;
    uint256 private _totalAmountPerEpoch;
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint256 public epochDuration; // init from staking contract
    uint256 public epochStart; // init from staking contract
    uint256 public _genesisEpochAmount;
    uint256 private _deprecationPerEpoch;

    // events
    event MassHarvest(
        address indexed user,
        uint256 epochsHarvested,
        uint256 totalValue
    );
    event Harvest(
        address indexed user,
        uint128 indexed epochId,
        uint256 amount
    );

    // constructor
    constructor(
        address bondTokenAddress,
        address poolTokenAddress,
        address stakeContract,
        address communityVault,
        uint256 genesisEpochAmount,
        uint256 deprecationPerEpoch,
        uint256 nrOfEpochs
    ) public {
        _bond = IERC20(bondTokenAddress);
        _poolTokenAddress = poolTokenAddress;
        _staking = IStaking(stakeContract);
        _communityVault = communityVault;
        epochDuration = _staking.epochDuration();
        epochStart = _staking.epoch1Start() + epochDuration;
        uint256 n = nrOfEpochs;
        uint256 difference = (n.mul(n.sub(1))).div(2); //Changed formula, we count first n-1 numbers not n since substraction happens after first epoch uint difference = (n.mul(n.add(1))).div(2);
        TOTAL_DISTRIBUTED_AMOUNT = (genesisEpochAmount.mul(n)).sub(
            difference.mul(deprecationPerEpoch)
        ); //Changed, formula was not multplying correctly, doesn't hamper contract since used in frontend
        NR_OF_EPOCHS = nrOfEpochs;
        epochs = new uint256[](nrOfEpochs + 1);
        _genesisEpochAmount = genesisEpochAmount;
        _deprecationPerEpoch = deprecationPerEpoch;
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint256) {
        uint256 totalDistributedValue;
        uint256 epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > NR_OF_EPOCHS) {
            epochId = NR_OF_EPOCHS;
        }

        for (
            uint128 i = lastEpochIdHarvested[msg.sender] + 1;
            i <= epochId;
            i++
        ) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue = totalDistributedValue.add(_harvest(i));
        }

        emit MassHarvest(
            msg.sender,
            epochId - lastEpochIdHarvested[msg.sender],
            totalDistributedValue
        );

        if (totalDistributedValue > 0) {
            _bond.safeTransferFrom(
                _communityVault,
                msg.sender,
                totalDistributedValue
            );
        }

        return totalDistributedValue;
    }

    function harvestAndStake() external returns (uint256) {
        uint256 totalDistributedValue;
        uint256 epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > NR_OF_EPOCHS) {
            epochId = NR_OF_EPOCHS;
        }

        for (
            uint128 i = lastEpochIdHarvested[msg.sender] + 1;
            i <= epochId;
            i++
        ) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue = totalDistributedValue.add(_harvest(i));
        }

        emit MassHarvest(
            msg.sender,
            epochId - lastEpochIdHarvested[msg.sender],
            totalDistributedValue
        );

        if (totalDistributedValue > 0) {
            _staking.depositFor(
                address(_bond),
                msg.sender,
                totalDistributedValue
            );
        }

        return totalDistributedValue;
    }

    function harvest(uint128 epochId) external returns (uint256) {
        // checks for requested epoch
        require(_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= NR_OF_EPOCHS, "Maximum number of epochs is 100");
        require(
            lastEpochIdHarvested[msg.sender].add(1) == epochId,
            "Harvest in order"
        );
        uint256 userReward = _harvest(epochId);
        if (userReward > 0) {
            _bond.safeTransferFrom(_communityVault, msg.sender, userReward);
        }
        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }

    // views
    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint256) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId)
        external
        view
        returns (uint256)
    {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function userLastEpochIdHarvested() external view returns (uint256) {
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods

    function _initEpoch(uint128 epochId) internal {
        require(
            lastInitializedEpoch.add(1) == epochId,
            "Epoch can be init only in order"
        );
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest(uint128 epochId) internal returns (uint256) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[msg.sender] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        return
            _calcTotalAmountPerEpoch(epochId)
                .mul(_getUserBalancePerEpoch(msg.sender, epochId))
                .div(epochs[epochId]);
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint256) {
        // retrieve unilp token balance
        return
            _staking.getEpochPoolSize(
                _poolTokenAddress,
                _stakingEpochId(epochId)
            );
    }

    function _calcTotalAmountPerEpoch(uint256 epochId)
        internal
        view
        returns (uint256)
    {
        return _genesisEpochAmount.sub(epochId.mul(_deprecationPerEpoch));
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId)
        internal
        view
        returns (uint256)
    {
        // retrieve unilp token balance per user per epoch
        return
            _staking.getEpochUserBalance(
                userAddress,
                _poolTokenAddress,
                _stakingEpochId(epochId)
            );
    }

    // compute epoch id from blocktimestamp and epochstart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(
            block.timestamp.sub(epochStart).div(epochDuration).add(1)
        );
    }

    // get the staking epoch which is 1 epoch more
    function _stakingEpochId(uint128 epochId) internal pure returns (uint128) {
        return epochId + 1;
    }
}
