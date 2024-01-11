pragma solidity ^0.8.0;

// import "./CoreRef.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./IStkEth.sol";
import "./IOracle.sol";
import "./IStakingPool.sol";
import "./CoreRef.sol";
import "./IIssuer.sol";
import "./KeysManager.sol";
import "./IStakingPool.sol";

contract Oracle is IOracle, CoreRef {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    uint128 internal constant ETH2_DENOMINATION = 1e9;
    uint256 constant BASIS_POINT = 10000;
    uint256 public DEPOSIT_LIMIT = 32e18;

    struct BeaconData {
        uint64 epochsPerTimePeriod;
        uint64 slotsPerEpoch;
        uint64 secondsPerSlot;
        uint64 genesisTime;
    }

    uint256 lastCompletedEpochId;
    uint256 lastValidatorActivation;
    Counters.Counter private nonce;
    uint32 quorom;
    uint32 validatorQuorom;
    uint256 public override activatedValidators;
    uint32 pStakeCommission;
    uint32 valCommission;

    uint256 beaconEthBalance = 0;
    int256 beaconRewardBalance = 0;
    uint64 public activateValidatorDuration = 10 minutes;

    mapping(bytes32 => uint256) public candidates;
    mapping(bytes32 => bool) private submittedVotes;

    BeaconData beaconData;

    EnumerableSet.AddressSet private oracleMembers;
    uint256 public override pricePerShare = 1e18;

    event quoromUpdated(
        uint32 indexed latestQuorom,
        uint256 indexed nonce,
        uint32 indexed quorom
    );
    event oracleMemberAdded(
        address indexed newOracleMember,
        uint256 indexed oracleMemberLength
    );
    event oracleMemberRemoved(
        address indexed newOracleMember,
        uint256 indexed oracleMemberLength
    );
    event dataPushed(
        address indexed oracleAddress,
        uint256 latestEthBalance,
        uint256 indexed latestNonce,
        uint32 numberOfValidators,
        uint256 indexed lastCompletedEpoch
    );
    event validatorActivated(bytes[] _publicKey);
    event commissionsUpdated(uint32 _pStakeCommission, uint32 _valCommission);


    /// @notice constructor to initialize core
    /// @param _epochsPerTimePeriod epochs per time period
    /// @param _slotsPerEpoch slots per Epoch
    /// @param _genesisTime time of genesis
    /// @param _core core reference
    /// @param _pStakeCommission protocol commission
    /// @param _valCommission validator commissiom
    constructor(
        uint64 _epochsPerTimePeriod,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        address _core,
        uint32 _pStakeCommission,
        uint32 _valCommission
    ) CoreRef(_core) {
        beaconData.epochsPerTimePeriod = _epochsPerTimePeriod;
        beaconData.slotsPerEpoch = _slotsPerEpoch;
        beaconData.secondsPerSlot = _secondsPerSlot;
        beaconData.genesisTime = _genesisTime;
        require(
            _pStakeCommission < BASIS_POINT &&
            _valCommission < BASIS_POINT &&
            (_pStakeCommission + _valCommission) < BASIS_POINT,
            "Invalid values"
        );
        pStakeCommission = _pStakeCommission;
        valCommission = _valCommission;
        require(stkEth().approve(core().validatorPool(), type(uint256).max));
    }

    /// @notice fucntion that returns the 
    /// @return frameEpochId epoch id of the frame
    /// @return frameStartTime timestamp of start of time frame
    /// @return frameEndTime
    function getCurrentTimePeriod()
    external
    view
    returns (
        uint256 frameEpochId,
        uint256 frameStartTime,
        uint256 frameEndTime
    )
    {
        uint64 genesisTime = beaconData.genesisTime;
        uint64 secondsPerEpoch = beaconData.secondsPerSlot *
        beaconData.slotsPerEpoch;

        frameEpochId = _getFrameFirstEpochId(
            _getCurrentEpochId(beaconData),
            beaconData
        );
        frameStartTime = frameEpochId * secondsPerEpoch + genesisTime;
        frameEndTime =
        (frameEpochId + beaconData.epochsPerTimePeriod) *
        secondsPerEpoch +
        genesisTime -
        1;
    }

    /// @notice function to return the current nonce
    /// @return current nonce
    function currentNonce() external view returns (uint256) {
        return nonce.current();
    }


    /// @notice function to return oracle member length
    /// @return number of oracle members
    function oracleMemberLength() public view returns (uint256) {
        return oracleMembers.length();
    }


    /// @notice ...
    /// @return ...
    function Quorom() external view returns (uint32) {
        return quorom;
    }


    /// @notice function to return the current nonce
    /// @return current nonce
    function ValidatorQuorom() external view returns (uint32) {
        return validatorQuorom;
    }


    /// @notice function to return the current nonce
    /// @return epochsPerTimePeriod
    /// @return slotsPerEpoch
    /// @return secondsPerSlot
    /// @return genesisTime
    function getBeaconData()
    external
    view
    returns (
        uint64 epochsPerTimePeriod,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    )
    {
        return (
        beaconData.epochsPerTimePeriod,
        beaconData.slotsPerEpoch,
        beaconData.secondsPerSlot,
        beaconData.genesisTime
        );
    }


    /// @notice function to return the frame id of first epoch
    /// @return ...
    function _getFrameFirstEpochId(
        uint256 _epochId,
        BeaconData memory _beaconSpec
    ) internal view returns (uint256) {
        return
        (_epochId / _beaconSpec.epochsPerTimePeriod) *
        _beaconSpec.epochsPerTimePeriod;
    }

    /// @notice function to return the current epoch id
    /// @return ...
    function _getCurrentEpochId(BeaconData memory _beaconSpec)
    internal
    view
    returns (uint256)
    {
        return
        (block.timestamp - beaconData.genesisTime) /
        (beaconData.slotsPerEpoch * beaconData.secondsPerSlot);
    }

    /// @notice function to return the last completed epoch id
    /// @return lastCompletedEpochId
    function getLastCompletedEpochId() external view returns (uint256) {
        return lastCompletedEpochId;
    }


    /// @notice function to return the total ether balance
    /// @return beaconEthBalance 
    function getTotalEther() external view returns (uint256) {
        return beaconEthBalance;
    }

    function getTotalRewards() external view returns (int256) {
        return beaconRewardBalance;
    }


    /// @notice function to update latestQuorom
    /// @param latestQuorom ...
    function updateQuorom(uint32 latestQuorom) external onlyGovernor {
        require(latestQuorom >= 0, "Quorom less that 0");
        quorom = latestQuorom;
        emit quoromUpdated(latestQuorom, nonce.current(), quorom);
    }

    function updateValidatorQuorom(uint32 latestQuorom) external onlyGovernor {
        require(latestQuorom >= 0, "Quorom less that 0");
        validatorQuorom = latestQuorom;
    }

    function updateCommissions(uint32 _pStakeCommission, uint32 _valCommission)
    external
    onlyGovernor
    {
        require(
            _pStakeCommission < BASIS_POINT &&
            _valCommission < BASIS_POINT &&
            (_pStakeCommission + _valCommission) < BASIS_POINT,
            "Invalid values"
        );
        pStakeCommission = _pStakeCommission;
        valCommission = _valCommission;
        emit commissionsUpdated(_pStakeCommission, _valCommission);
    }

    function addOracleMember(address newOracleMember)
    external
    override
    onlyGovernor
    {
        require(oracleMembers.add(newOracleMember), "Oracle member already present");
        emit oracleMemberAdded(newOracleMember, oracleMemberLength());
    }

    function removeOracleMember(address oracleMemberToDelete)
    external
    override
    onlyGovernor
    {
        require(oracleMembers.remove(oracleMemberToDelete), "Oracle member not present");
        emit oracleMemberRemoved(oracleMemberToDelete, oracleMemberLength());
    }


    /// @notice function to check if adress is oracle member
    /// @return oracleMember  
    function isOracle(address member) public view returns (bool) {
        return oracleMembers.contains(member);
    }


    /// @notice function for minting of StkEth for Eth
    /// @param amount ...
    /// @param user ...
    /// @param newPricePerShare new price per share
    function mintStkEthForEth(
        uint256 amount,
        address user,
        uint256 newPricePerShare
    ) internal returns (uint256 stkEthToMint){
        stkEthToMint = (amount * 1e18) / newPricePerShare;
        stkEth().mint(user, stkEthToMint);
    }


    /// @notice function for slashing balance of a pool 
    /// @param deltaEth difference in eth balance since last distribution
    /// @param beaconRewardEarned ...
    function slash(uint256 deltaEth,int256 beaconRewardEarned) internal {
        //
        //        uint256 stkEthToSlash = (deltaEth * 1e18) / pricePerShare;
        uint256 price = pricePerShare;
        if (beaconRewardEarned>0) {
            price = (IIssuer(core().issuer()).ethStakedIssuer() + uint256(beaconRewardEarned)) * 1e18 / (IStkEth(core().stkEth()).totalSupply());
        }
        else {
            price = (IIssuer(core().issuer()).ethStakedIssuer() - uint256(beaconRewardEarned*int256(-1))) * 1e18 / (IStkEth(core().stkEth()).totalSupply());
        }
        //  todo: in future for insurance mechanism
        //        deltaEth = deltaEth - ((stkEthBurned * pricePerShare) / 1e18);
        //        uint256 percentChange = deltaEth * 1e18 / rewardBase;
        //        pricePerShare = (pricePerShare * (1e18 - percentChange)) / 1e18;
        //
        //        uint256 preTotal = stkEth().totalSupply();
        //
        ////        IStakingPool(core().validatorPool()).slash(stkEthToSlash);
        //
        //        uint256 stkEthBurned = preTotal - stkEth().totalSupply();
        //        // If staking pool not able to burn enough stkEth, then adjust pricePerShare for remainingSupply
        //        if (stkEthBurned < stkEthToSlash) {
        //            deltaEth = deltaEth - ((stkEthBurned * pricePerShare) / 1e18);
        //            uint256 percentChange = deltaEth * 1e18 / rewardBase;
        //            pricePerShare = (pricePerShare * (1e18 - percentChange)) / 1e18;
        //        }
        pricePerShare = price;
        emit Slash(deltaEth,pricePerShare,block.timestamp);
    }

    /// @notice function to distribute rewards by setting price per share
    /// @param deltaEth difference in eth balance since last distribution
    /// @param beaconRewardEarned ...
    function distributeRewards(uint256 deltaEth, int256 beaconRewardEarned) internal {
        // calculate fees need to be deducted in terms of stkEth which will be minted for treasury & validators

        uint256 valEthShare = (valCommission * deltaEth) / BASIS_POINT;
        uint256 protocolEthShare = (pStakeCommission * deltaEth) / BASIS_POINT;
        uint256 price = pricePerShare;
        if (beaconRewardEarned > 0) {
            price = (IIssuer(core().issuer()).ethStakedIssuer() + uint256(beaconRewardEarned) - (valEthShare + protocolEthShare)) * 1e18 / IStkEth(core().stkEth()).totalSupply();
        }
        else{
            price = (IIssuer(core().issuer()).ethStakedIssuer() - uint256(beaconRewardEarned*int256(-1)) - (valEthShare + protocolEthShare)) * 1e18 / IStkEth(core().stkEth()).totalSupply();
        }
        uint256 stkEthMinted = mintStkEthForEth(valEthShare, address(this), price);
        IStakingPool(core().validatorPool()).updateRewardPerValidator(stkEthMinted);
        mintStkEthForEth(protocolEthShare, core().pstakeTreasury(), price);
        pricePerShare = price;
        emit Distribute(deltaEth,pricePerShare,block.timestamp);
    }


    function updateValidatorActivationDuration(uint64 activationDuration) external onlyGovernor {
        activateValidatorDuration = activationDuration;
    }

    /// @notice function to activate an array of validators
    /// @param _publicKeys public key array of validators
    function activateValidator(bytes[] memory _publicKeys) external override {
        require(isOracle(msg.sender), "Not oracle Member");
        require(
            block.timestamp >= lastValidatorActivation + activateValidatorDuration,
            "voted before minimum duration"
        );
        bytes32 candidateId = keccak256(abi.encode(_publicKeys));
        bytes32 voteId = keccak256(abi.encode(msg.sender, candidateId));
        require(!submittedVotes[voteId], "Oracles: already voted");

        // mark vote as submitted, update candidate votes number
        submittedVotes[voteId] = true;
        uint256 candidateNewVotes = candidates[candidateId] + 1;
        candidates[candidateId] = candidateNewVotes;
        uint256 oracleMemberSize = oracleMemberLength();

        if (candidateNewVotes >= validatorQuorom) {
            delete submittedVotes[voteId];

            for (uint256 i = 0; i < oracleMemberSize; i++) {
                delete submittedVotes[
                keccak256(
                    abi.encode(
                        oracleMembers.at(i),
                        candidateId
                    )
                )
                ];
            }

            // clean up candidate
            delete candidates[candidateId];
            IKeysManager(core().keysManager()).activateValidator(_publicKeys);
            lastValidatorActivation = block.timestamp;
            emit validatorActivated(_publicKeys);
        }
    }


    /// @notice function to push data to oracle
    /// @param latestEthBalance latest balance of eth 
    /// @param latestNonce latest nonce number
    /// @param numberOfValidators count of validators
    function pushData(
        uint256 latestEthBalance,
        uint256 latestNonce,
        uint32 numberOfValidators
    ) external override {
        require(isOracle(msg.sender), "Not oracle Member");
        uint256 currentFrameEpochId = _getCurrentEpochId(beaconData);

        require(
            currentFrameEpochId > lastCompletedEpochId,
            "Cannot push to Epoch less that already commited"
        );
        require(
            currentFrameEpochId >=
            _getFrameFirstEpochId(currentFrameEpochId, beaconData)
        );
        require(
            currentFrameEpochId <
            _getFrameFirstEpochId(currentFrameEpochId, beaconData) +
            beaconData.epochsPerTimePeriod
        );

        require(latestNonce == nonce.current(), "incorrect Nonce");
        require(
            activatedValidators <= numberOfValidators,
            "Invalid numberOfValidators"
        );
        latestEthBalance = latestEthBalance * ETH2_DENOMINATION;
        bytes32 candidateId = keccak256(
            abi.encode(nonce, latestEthBalance, numberOfValidators)
        );
        bytes32 voteId = keccak256(abi.encode(msg.sender, candidateId));
        require(!submittedVotes[voteId], "Oracles: already voted");

        // mark vote as submitted, update candidate votes number
        submittedVotes[voteId] = true;
        uint256 candidateNewVotes = candidates[candidateId] + 1;
        candidates[candidateId] = candidateNewVotes;
        uint256 oracleMemberSize = oracleMemberLength();
        emit dataPushed(msg.sender, latestEthBalance, latestNonce, numberOfValidators, lastCompletedEpochId);
        if (candidateNewVotes >= quorom) {
            // clean up votes
            delete submittedVotes[voteId];

            for (uint256 i = 0; i < oracleMemberSize; i++) {
                delete submittedVotes[
                keccak256(
                    abi.encode(
                        oracleMembers.at(i),
                        candidateId
                    )
                )
                ];
            }

            // clean up candidate
            nonce.increment();
            delete candidates[candidateId];

            uint256 rewardBase = beaconEthBalance +
            (DEPOSIT_LIMIT * (numberOfValidators - activatedValidators));
            if (activatedValidators < numberOfValidators) {
                IIssuer(core().issuer()).updatePendingValidator(
                    numberOfValidators - activatedValidators
                );
            }

            activatedValidators = numberOfValidators;

            if (latestEthBalance > rewardBase) {
                beaconRewardBalance = beaconRewardBalance + int(latestEthBalance - rewardBase);
                distributeRewards(latestEthBalance - rewardBase, beaconRewardBalance);
                //                beaconRewardBalance = beaconRewardBalance + (latestEthBalance - rewardBase);
            } else if (latestEthBalance < rewardBase) {
                beaconRewardBalance = beaconRewardBalance - int(rewardBase - latestEthBalance);
                slash(rewardBase - latestEthBalance, beaconRewardBalance);
            }

            beaconEthBalance = latestEthBalance;
            lastCompletedEpochId = currentFrameEpochId;

        }
        uint256 timeElapsed = (currentFrameEpochId - lastCompletedEpochId) *
        beaconData.slotsPerEpoch *
        beaconData.secondsPerSlot;
    }


    /// @notice update the specification parameters for beacon chain data
    /// @param epochsPerTimePeriod ...
    /// @param slotsPerEpoch ...
    /// @param secondsPerSlot ...
    /// @param genesisTime ...
    function updateBeaconChainData(
        uint64 epochsPerTimePeriod,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    ) external onlyGovernor {
        _setBeaconSpec(
            epochsPerTimePeriod,
            slotsPerEpoch,
            secondsPerSlot,
            genesisTime
        );
    }



    /// @notice sets the specification parameters for beacon chain data
    /// @param _epochsPerTimePeriod ...
    /// @param _slotsPerEpoch ...
    /// @param _secondsPerSlot ...
    /// @param _genesisTime ...
    function _setBeaconSpec(
        uint64 _epochsPerTimePeriod,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    ) internal {
        require(_epochsPerTimePeriod > 0);
        require(_slotsPerEpoch > 0);
        require(_secondsPerSlot > 0);
        require(_genesisTime > 0);

        beaconData.epochsPerTimePeriod = _epochsPerTimePeriod;
        beaconData.slotsPerEpoch = _slotsPerEpoch;
        beaconData.secondsPerSlot = _secondsPerSlot;
        beaconData.genesisTime = _genesisTime;
    }
}
