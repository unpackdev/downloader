// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./RewardPoolETH.sol";
import "./ICollectionswap.sol";
import "./ILSSVMPair.sol";
import "./SortitionSumTreeFactory.sol";
import "./ReentrancyGuard.sol";
import "./RNGInterface.sol";

contract RewardPoolETHDraw is ReentrancyGuard, RewardPoolETH {
    using SafeERC20 for IERC20;
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    address public factory;

    /// @notice RNG contract interface
    RNGInterface public rng;

    uint256 public thisEpoch;
    uint32 public myRNGRequestId;
    mapping(uint256 => uint256) public epochToStartTime;
    mapping(uint256 => uint256) public epochToFinishTime;
    mapping(uint256 => uint256) public epochToRandomNumber;
    
    struct SimpleObservation {
        uint256 timestamp;
        uint256 lastAmount;
        uint256 twapCumSum;
        uint256 predictedEndSum; // relies on knowing epoch end in advance
    }

    // list of addresses who have interacted with this contract - necessary to get the list of all interactors
    address[] internal totalVaultInteractorList;
    mapping(address => SimpleObservation) public lastTWAPObservation;

    enum DrawStatus {
        Open,
        Closed,
        Resolved
    }

    DrawStatus public drawStatus;
    
    //////////////////////////////////////////
    // DRAW AMOUNTS
    //////////////////////////////////////////

    bytes32 private TREE_KEY;
    uint256 private constant MAX_TREE_LEAVES = 5;
    uint256 public constant MAX_REWARD_NFTS = 200;
    uint256 public constant MAX_PRIZE_WINNERS_PER_EPOCH = 500;
    address private constant DUMMY_ADDRESS = address(0);
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

    struct NFTData {
        IERC721 nftAddress;
        uint256 nftID;
    }
    struct PrizeSet {
        // ERC20 tokens to reward
        IERC20[] erc20RewardTokens;

        // ERC721 tokens to reward
        IERC721[] erc721RewardTokens;
        uint256 numERC721Prizes;
        uint256 prizePerWinner;
    }
    struct WinnerConfig {
        uint256 numberOfDrawWinners;
        uint256 numberOfPrizesPerWinner;
        uint256 remainder;
    }
    // Mappings of epoch to prize data
    mapping(uint256 => PrizeSet) public epochPrizeSets;
    mapping(uint256 => mapping(IERC20 => uint256)) public epochERC20PrizeAmounts;
    mapping(uint256 => mapping(IERC721 => bool)) public epochERC721Collections;
    mapping(uint256 => mapping(uint256 => NFTData)) public epochERC721PrizeIdsData;
    mapping(uint256 => WinnerConfig) public epochWinnerConfigs;

    mapping(uint256 => mapping(address => uint256)) public epochUserERC20NumWinnerEntries; // denominator is epochWinnerConfigs[epoch].numberOfDrawWinners

    // NFT prizes
    /** 
     * @dev epoch => user => `index_arr`, where `address` is awardable
     * `epochERC721PrizeIdsData[index * numberOfPrizesPerWinner + 1]`
     * to 
     * `epochERC721PrizeIdsData[(index + 1) * numberOfPrizesPerWinner]`
     * for all `index` in `index_arr`
     */
    mapping(uint256 => mapping(address => uint256[])) public epochUserPrizeStartIndices; 

    // Both ERC20 and ERC721 prizes
    mapping(uint256 => mapping(address => bool)) public isPrizeClaimable;

    //////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////

    event DrawOpen(uint256 epoch);
    event DrawClosed(uint256 epoch);
    event ERC721PrizesAdded(
        IERC721[] nftCollections,
        uint256[] nftIds
    );
    event ERC20PrizesAdded(
        IERC20[] rewardTokens,
        uint256[] rewardAmounts
    );
    event DrawResolved(uint256 epoch, address[] winners);
    event Claimed(address user, uint256 epoch);

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /** 
        @dev - this is called by the factory. 
        @param _protocolOwner - the owner of the protocol
        @param _factory - the factory address
        @param _deployer - the vault deployer's address
        @param _lpToken - Collectionswap deployment address

        @param _rng - RNG contract address
        @param _additionalERC20DrawPrize - additional ERC20 prize to add to the draw, list
        @param _additionalERC20DrawPrizeAmounts - additional ERC20 prize amount to add to the draw, list
        @param _nftCollectionsPrize - additional ERC721 prize to add to the draw, list
        @param _nftIdsPrize - additional ERC721 prize ID to add to the draw, list
    **/
    function initialize(
        address _protocolOwner,
        address _factory,
        address _deployer,
        ICollectionswap _lpToken,
        IERC721 _nft,
        address _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        IERC20[] calldata _rewardTokens,
        uint256[] calldata _rewardRates,
        uint256 _rewardStartTime,
        uint256 _rewardPeriodFinish,
        RNGInterface _rng,
        IERC20[] calldata _additionalERC20DrawPrize,
        uint256[] calldata _additionalERC20DrawPrizeAmounts,
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        uint256 _prizesPerWinner,
        uint256 _drawStartTime,
        uint256 _drawPeriodFinish
    )  external {
        __ReentrancyGuard_init();
        LOCK_TIME = 90 days;
        factory = _factory;

        super.initialize({
            _protocolOwner: _protocolOwner,
            _deployer: _deployer,
            _lpToken: _lpToken,
            _nft: _nft,
            _bondingCurve: _bondingCurve,
            _delta: _delta,
            _fee: _fee,
            _rewardTokens: _rewardTokens,
            _rewardRates: _rewardRates,
            _startTime: _rewardStartTime,
            _periodFinish: _rewardPeriodFinish
        });

        rng = _rng;
        TREE_KEY = keccak256(abi.encodePacked(uint256(1)));
        sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);
        
        // Ensure that there is always a non-zero initial stake.
        // This is to prevent the sortition tree from being empty.
        // Can be anyone, have set to DUMMY_ADDRESS, soft guarantee of not zeroing out
        // draw stake midway (stake then unstake)
        bytes32 _ID = addressToBytes32(DUMMY_ADDRESS);
        sortitionSumTrees.set(TREE_KEY, 1, _ID);

        // thisEpoch is incremented in function below
        _addNewPrizeEpoch({
            _nftCollectionsPrize: _nftCollectionsPrize,
            _nftIdsPrize: _nftIdsPrize,
            _prizesPerWinner: _prizesPerWinner,
            _erc20Prize: _additionalERC20DrawPrize,
            _erc20PrizeAmounts: _additionalERC20DrawPrizeAmounts,
            _drawStartTime: _drawStartTime,
            _drawPeriodFinish: _drawPeriodFinish,
            _callerIsDeployer: false,
            _epoch: thisEpoch
        });
    }

    /**
        @dev - add ERC721 prizes and / or ERC20 prizes to the prize set
        any mutation functions to prize sets should not permit epoch parameterization
        @dev - Only callable by deployer
        @dev - Specify zero drawStartTime to add during an epoch, else adding after an epoch
    **/
    function addNewPrizes(
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        IERC20[] calldata _erc20Prize,
        uint256[] calldata _erc20PrizeAmounts,
        uint256 _prizesPerWinner,
        uint256 _drawStartTime,
        uint256 _drawPeriodFinish
    ) external onlyDeployer {
        _addNewPrizeEpoch({
            _nftCollectionsPrize: _nftCollectionsPrize,
            _nftIdsPrize: _nftIdsPrize,
            _erc20Prize: _erc20Prize,
            _erc20PrizeAmounts: _erc20PrizeAmounts,
            _prizesPerWinner: _prizesPerWinner,
            _drawStartTime: _drawStartTime,
            _drawPeriodFinish: _drawPeriodFinish,
            _callerIsDeployer: true,
            _epoch: thisEpoch
        });

        // Add after epoch
        // fast forward sortition tree
        if (_drawStartTime != 0) recalcSortitionTreesEpochStart();
    }

    /**
        @dev - internal method for transferring and adding ERC721 and ERC20 prizes to the prize set.
        @dev - Factory has a special-workflow for not transferring as it is easier to initialize state and then transfer tokens in.
    **/
    function _addNewPrizeEpoch(
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        IERC20[] calldata _erc20Prize,
        uint256[] calldata _erc20PrizeAmounts,
        uint256 _prizesPerWinner,
        uint256 _drawStartTime,
        uint256 _drawPeriodFinish,
        bool _callerIsDeployer,
        uint256 _epoch
    ) internal nonReentrant {
        uint256 numNfts = _nftCollectionsPrize.length;

        /////////////////////////////
        /// UPDATES FOR NEW EPOCH ///
        /////////////////////////////
        if (_drawStartTime != 0) {
            // ensure that current epoch has been resolved
            // excludes base case of _epoch == 0 (uninitialized)
            if (_epoch != 0) require(drawStatus == DrawStatus.Resolved, "Should be resolved");

            // when setting new epoch, 
            // we need numNfts > 0 to ensure the draw is workable
            // because the distribution of the prizes depends on the number of ERC721 tokens
            require(numNfts > 0, "Min 1 NFT"); 
            require(_drawStartTime > block.timestamp, "start < now");
            require(_drawPeriodFinish > _drawStartTime, "end <= start");

            // update thisEpoch storage variable
            // and increment _epoch to new epoch
            thisEpoch = ++_epoch;

            // initialize prize set for new epoch
            _initPrizeSet(_epoch);

            // set new epoch times
            epochToStartTime[_epoch] = _drawStartTime;
            epochToFinishTime[_epoch] = _drawPeriodFinish;

            // update reward sweep time if it will exceed current reward sweep time
            uint256 newRewardSweepTime = _drawPeriodFinish + LOCK_TIME;
            if (rewardSweepTime < newRewardSweepTime) rewardSweepTime = newRewardSweepTime;
            
            drawStatus = DrawStatus.Open;
            emit DrawOpen(_epoch);
        } else {
            if (_epoch != 0) {
                // when adding to an existing epoch, 
                // require that the draw is not resolved
                require(drawStatus != DrawStatus.Resolved, "Should not be resolved"); 
            } else {
                // If epoch is zero (initialization),
                // We assume the project is only using the reward distribution portion initially,
                // and would use the draw functionality in the future
                // Hence, we check that no rewards are being distributed
                require(numNfts == 0 && _erc20Prize.length == 0, "Init with 0 startTime");
            }
        }

        ////////////////////////////
        /// HANDLING NFT PRIZES  ///
        ////////////////////////////
        require(numNfts == _nftIdsPrize.length, "Diff NFT lengths");

        PrizeSet storage prizeSet = epochPrizeSets[_epoch];
        // index for appending to existing number of NFTs
        uint256 prizeIdIndex = prizeSet.numERC721Prizes;
        require(prizeIdIndex + numNfts < MAX_REWARD_NFTS, "Exceed max NFTs");
        // iterate through each nft in prizePool.nftCollections and transfer to this contract if caller is deployer
        for (uint256 i; i < numNfts; ++i) {
            IERC721 myCollAdd = (_nftCollectionsPrize[i]);
            
            if (!epochERC721Collections[_epoch][myCollAdd]) {
                // new collection for this epoch
                require(_nftCollectionsPrize[i].supportsInterface(0x80ac58cd), "NFT Prize not ERC721"); // check if it supports ERC721
                epochERC721Collections[_epoch][myCollAdd] = true;
                prizeSet.erc721RewardTokens.push(myCollAdd);
            }
            // @dev: only need transfer NFTs in if caller is deployer
            if (_callerIsDeployer) {
                _nftCollectionsPrize[i].safeTransferFrom(msg.sender, address(this), _nftIdsPrize[i]);
            }
            epochERC721PrizeIdsData[_epoch][++prizeIdIndex] = NFTData(myCollAdd, _nftIdsPrize[i]);
        }
        // update only if numNfts is non-zero
        if (numNfts != 0) {
            prizeSet.numERC721Prizes = prizeIdIndex;
            _setPrizePerWinner(prizeSet, _prizesPerWinner);
        }

        emit ERC721PrizesAdded(_nftCollectionsPrize, _nftIdsPrize);

        /////////////////////////////
        /// HANDLING ERC20 PRIZES ///
        /////////////////////////////
        require(_erc20Prize.length == _erc20PrizeAmounts.length, "Diff ERC20 lengths");

        // iterate through each ERC20 token and transfer to this contract
        for (uint256 i; i < _erc20Prize.length; ++i) {
            require(_erc20PrizeAmounts[i] != 0, "0 prize amount");
            // @dev: only need transfer tokens in if caller is deployer
            if (_callerIsDeployer) {
                _erc20Prize[i].safeTransferFrom(msg.sender, address(this), _erc20PrizeAmounts[i]);
            }

            IERC20 myCollAdd = _erc20Prize[i];
            uint256 epochAmount = epochERC20PrizeAmounts[_epoch][myCollAdd];
            if (epochAmount == 0) {
                // not encountered before
                prizeSet.erc20RewardTokens.push(myCollAdd);
                // ensure no. of ERC20 tokens don't exceed MAX_REWARD_TOKENS
                require(prizeSet.erc20RewardTokens.length <= MAX_REWARD_TOKENS, "Exceed max tokens");
            }
            epochERC20PrizeAmounts[_epoch][myCollAdd] = epochAmount + _erc20PrizeAmounts[i];
        }

        emit ERC20PrizesAdded(_erc20Prize, _erc20PrizeAmounts);
    }

    function rechargeRewardPool(
        IERC20[] calldata inputRewardTokens,
        uint256[] calldata inputRewardAmounts,
        uint256 _newPeriodFinish
    ) public override {
        uint256 currentRewardSweepTime = rewardSweepTime;
        // sweep time gets updated to _newPeriodFinish + LOCK_TIME
        super.rechargeRewardPool(inputRewardTokens, inputRewardAmounts, _newPeriodFinish);
        // reset to currentRewardSweepTime if new sweep time is shorter
        // ie. rewardSweepTime should always be the maximum of its current and updated value
        if (rewardSweepTime < currentRewardSweepTime) rewardSweepTime = currentRewardSweepTime;
    }

    /**
        @dev - initializes prize set for new epoch. Callable internally only after epoch has been incremented.
    **/
    function _initPrizeSet(uint256 epoch) internal {
        epochPrizeSets[epoch] = PrizeSet({
            erc721RewardTokens: new IERC721[](0),
            numERC721Prizes: 0,
            erc20RewardTokens: new IERC20[](0),
            prizePerWinner: 1
        });
    }

    /**
        @dev - O(1) lookup for previous interaction
    **/
    function firstTimeUser(address user) public view returns (bool) {
        return lastTWAPObservation[user].timestamp == 0;
    }

    /**
     * @notice Fresh state for the sortition tree at the start of a new epoch.
     * prune interactors with 0 `lastAmount` as they are effectively irrelevant
     * @dev - As we are taking a TWAB and using a persistent sortition tree, we
     * need to maintain a list of addresses who have interacted with the vault
     * in the past, and recalc the TWAB for each epoch. This is done by the
     * deployer, and is part of the cost of recharging. The interactor list is
     * pruned upon calling this function.
     */
    function recalcSortitionTreesEpochStart() internal {
        uint256 amountTimeRemainingToVaultEnd = getFunctionalTimeRemainingInVault(block.timestamp);

        // Recalculate sortition trees for everything in vaultInteractorList,
        // for the new periodFinish. Use i - 1 because (0 - 1) underflows to 
        // uintmax which causes a revert
        for (uint256 i = totalVaultInteractorList.length; i > 0; --i) {
            address vaultInteractor = totalVaultInteractorList[i - 1];
            SimpleObservation storage lastObservation = lastTWAPObservation[vaultInteractor];

            uint256 sortitionValue;
            // `lastObservation.lastAmount` remains the same
            if (lastObservation.lastAmount == 0) {
                // Delete the vault interactor from storage if they have 0 balance
                // (this is why we iterate in reverse order).
                totalVaultInteractorList[i - 1] = totalVaultInteractorList[totalVaultInteractorList.length - 1];
                totalVaultInteractorList.pop();

                // Delete vault interactor from `lastTWAPObservation`
                delete lastTWAPObservation[vaultInteractor];
            } else {
                lastObservation.timestamp = block.timestamp;
                lastObservation.twapCumSum = 0;
                lastObservation.predictedEndSum = lastObservation.lastAmount * amountTimeRemainingToVaultEnd;
                sortitionValue = lastObservation.predictedEndSum;
            }
            
            // Update the sortition tree. Sortition tree library deletes 0
            // entries for us
            bytes32 _ID = addressToBytes32(vaultInteractor);
            sortitionSumTrees.set(TREE_KEY, sortitionValue, _ID);
        }
    }

    /**
     * @notice Stake an LP token
     * @param tokenId The tokenId of the LP token to stake
     * @return amount The amount of reward token minted as a result
     * @dev - Maintain the new expected TWAB balance for the user.
     */    
    function stake(uint256 tokenId) public override returns (uint256 amount) {
        if (firstTimeUser(msg.sender)) totalVaultInteractorList.push(msg.sender);
        amount = super.stake(tokenId);
        updateSortitionStake(msg.sender, amount, true, (drawStatus == DrawStatus.Open));
    }

    /**
        @dev - if draw is open, directly calculate the expected TWAB balance for the user.
    **/    
    function burn(uint256 tokenId) internal override returns (uint256 amount) {
        amount = super.burn(tokenId);
        updateSortitionStake(msg.sender, amount, false, (drawStatus == DrawStatus.Open));
    }

    /**
        @dev - get "functional time" = the remaining amount of usable time to extend on the current TWAB cumsum. This is to calculate the expected TWAB at drawFinish so that we don't have to iterate through all addresses to get the right epoch-end weighted stake.
        We check that (A) eventTimestamp is less than drawFinish. And it is always bounded by the drawFinish - start time, even if the vault hasn't started.
    **/ 
    function getFunctionalTimeRemainingInVault(uint256 eventTimestamp) public view returns (uint256) {
        uint256 _epoch = thisEpoch;
        uint256 _drawStart = epochToStartTime[_epoch];
        uint256 _drawFinish = epochToFinishTime[_epoch];
        if (eventTimestamp < _drawStart) {
            // draw program has not commenced
            return _drawFinish - _drawStart;
        }
        return eventTimestamp > _drawFinish ? 0 : _drawFinish - eventTimestamp;
    }

    function getEffectiveTimeElapsedThisEpoch(uint256 eventTimestamp, uint256 lastObservationTimestamp) public view returns (uint256) {
        uint256 _epoch = thisEpoch;
        uint256 _drawStart = epochToStartTime[_epoch];
        uint256 _drawFinish = epochToFinishTime[_epoch];
        // return 0 if draw program has not commenced
        if (eventTimestamp < _drawStart) return 0;

        // min(drawFinish, eventTimestamp) - max(drawStart, lastObservationTimestamp)
        uint256 effectiveEndPoint = eventTimestamp > _drawFinish ? _drawFinish : eventTimestamp;
        uint256 effectiveStartPoint = lastObservationTimestamp < _drawStart ? _drawStart : lastObservationTimestamp;
        return effectiveEndPoint - effectiveStartPoint;
    }

    /**
        @dev - updateSortitionStake (updates Sortition stake and TWAB). This is called either when a user stakes/burns, but sortition tree is modified only when draw is open
    **/ 
    function updateSortitionStake(address _staker, uint256 _amount, bool isIncrement, bool modifySortition) internal {
        uint256 amountTimeRemainingToVaultEnd = getFunctionalTimeRemainingInVault(block.timestamp);

        SimpleObservation storage lastObservation = lastTWAPObservation[_staker];
        uint256 timeElapsed = getEffectiveTimeElapsedThisEpoch(block.timestamp, lastObservation.timestamp);
        
        // update lastObservation parameters
        // increment cumulative sum given effective time elapsed
        lastObservation.twapCumSum += timeElapsed * lastObservation.lastAmount;

        lastObservation.lastAmount = isIncrement ?
            lastObservation.lastAmount + _amount :
            lastObservation.lastAmount - _amount;

        lastObservation.timestamp = block.timestamp;
        lastObservation.predictedEndSum = lastObservation.twapCumSum + (amountTimeRemainingToVaultEnd * lastObservation.lastAmount);

        if (modifySortition) {
            bytes32 _ID = addressToBytes32(_staker);
            sortitionSumTrees.set(TREE_KEY, lastObservation.predictedEndSum, _ID);
        }
    }

    /**
        @dev - get numerator/denominator for chances of winning
    **/ 
    function viewChanceOfDraw(address _staker) external view returns (uint256 chanceNumerator, uint256 chanceDenominator) {
        bytes32 _ID = addressToBytes32(_staker);
        bytes32 _treeKey = TREE_KEY;
        chanceNumerator = sortitionSumTrees.stakeOf(_treeKey, _ID);
        chanceDenominator = sortitionSumTrees.total(_treeKey);
    }

    /**
        @dev - get number of winners and number of prizes per winner
    **/ 
    function getDrawDistribution(uint256 epoch) public view returns (uint256 numberOfDrawWinners, uint256 numberOfPrizesPerWinner, uint256 remainder) {
        numberOfPrizesPerWinner = epochPrizeSets[epoch].prizePerWinner;
        uint256 numPrizes = epochPrizeSets[epoch].numERC721Prizes;
        // numberOfPrizesPerWinner has been checked to be <= numPrizes
        // ensuring at least 1 winner
        numberOfDrawWinners = numPrizes / numberOfPrizesPerWinner;
        if (numberOfDrawWinners > MAX_PRIZE_WINNERS_PER_EPOCH) numberOfDrawWinners = MAX_PRIZE_WINNERS_PER_EPOCH;
        numberOfPrizesPerWinner = numPrizes / numberOfDrawWinners;
        remainder = numPrizes % numberOfDrawWinners;
    }

    function setPrizePerWinner(uint256 _prizePerWinner) external onlyDeployer {
        // not necessary to check drawStatus because winner config will be saved upon draw resolution: resolveDrawResults()
        _setPrizePerWinner(epochPrizeSets[thisEpoch], _prizePerWinner);
    }

    function _setPrizePerWinner(PrizeSet storage prizeSet, uint256 _prizePerWinner) internal {
        require(_prizePerWinner <= prizeSet.numERC721Prizes, "prizePerWinner > NFTs");
        require(_prizePerWinner > 0, "0 prizePerWinner");
        prizeSet.prizePerWinner = _prizePerWinner;
    }

    /**
        @dev - allows draw to be closed once the periodFinish has passed. Can be called by anyone (not just deployer) - in case deployer goes missing
    **/ 
    function closeDraw() external
        returns (uint32 requestId, uint32 lockBlock)
    {
        require(drawStatus == DrawStatus.Open, "Draw not open");
        require(block.timestamp > epochToFinishTime[thisEpoch], "Too early");
        drawStatus = DrawStatus.Closed;
        (requestId, lockBlock) = rng.requestRandomNumber();
        myRNGRequestId = requestId;

        emit DrawClosed(thisEpoch);
    }

    /**
        @dev - pseudorandom number generation from a verifiably random starting point. 
    **/ 
    function getWinner(uint256 randomNumber, uint256 iteration) private view returns (address winner) {
        // uint256 randomNumber = epochToRandomNumber[thisEpoch];
        uint i;
        bytes32 _treeKey = TREE_KEY;
        while (true) {
            uint256 finalRandom = uint256(keccak256(abi.encodePacked(randomNumber, iteration, i)));
            winner = bytes32ToAddress(sortitionSumTrees.draw(_treeKey, finalRandom));
            if (winner != DUMMY_ADDRESS) {
                return winner;
            }
            ++i;
        }
    }

    /**
        @dev - resolvesDrawResults. This can be called by anyone (not just deployer) - in case deployer goes missing. Sets the winners and their start indices, taking reference from NFT address x ID tuples
    **/ 
    function resolveDrawResults() external {
        // cache storage read
        uint32 _myRNGRequestId = myRNGRequestId;
        require(drawStatus == DrawStatus.Closed, "Draw not closed");
        require(rng.isRequestComplete(_myRNGRequestId), "Request incomplete");
        uint256 _epoch = thisEpoch;
        // set drawStatus to resolved
        drawStatus = DrawStatus.Resolved;
        uint256 randomNum = rng.randomNumber(_myRNGRequestId);
        epochToRandomNumber[_epoch] = randomNum;

        // prize Distribution
        (uint256 numberOfDrawWinners, uint256 numberOfPrizesPerWinner, uint256 remainder) = getDrawDistribution(_epoch);
        epochWinnerConfigs[_epoch] = WinnerConfig(numberOfDrawWinners, numberOfPrizesPerWinner, remainder);

        // iterate through the Number of Winners
        uint256 denominator = sortitionSumTrees.total(TREE_KEY);
        bool noDrawParticipants = (denominator == 1);
        // winner list may contain duplicate addresses
        // emitted in the WinnersDrawn event but not stored
        address[] memory winnerList = new address[](numberOfDrawWinners);
        for (uint256 i; i < numberOfDrawWinners; ++i) {
            // get the winner
            address winner = noDrawParticipants ? deployer : getWinner(randomNum, i);

            //////////////////////////////////////
            // NFT amount
            //////////////////////////////////////
            epochUserPrizeStartIndices[_epoch][winner].push(i);

            // set claimable status
            if (!isPrizeClaimable[_epoch][winner]) {
                isPrizeClaimable[_epoch][winner] = true;
            }
            // save in winner list
            winnerList[i] = winner;

            //////////////////////////////////////
            // ERC20 amount
            //////////////////////////////////////
            epochUserERC20NumWinnerEntries[_epoch][winner] += 1;
        } 

        emit DrawResolved(_epoch, winnerList);
    }

    /**
        @dev - Claims your share of the prize per epoch. Takes cue from the number of ERC721 tokens, first-class prizes. ERC20 tokens distribution are determined from ERC-721 tokens
    **/
    function claimMyShare(uint256 epoch) public {
        require(isPrizeClaimable[epoch][msg.sender], "No claimable share");
        // blocks re-entrancy for the same epoch
        isPrizeClaimable[epoch][msg.sender] = false;

        // NFTs
        uint256[] memory startIndices = epochUserPrizeStartIndices[epoch][msg.sender];
        uint256 numberOfPrizesPerWinner = epochWinnerConfigs[epoch].numberOfPrizesPerWinner;

        // Award each winner N := numberOfPrizesPerWinner NFTs
        // winner 1 would be awarded NFTs of prize indices 1 to N
        // winner 2 would be awarded NFTs of prize indices N+1 to 2N
        // etc.
        uint256 prizeIndex;
        for (uint256 i; i < startIndices.length; ++i) {
            prizeIndex = startIndices[i] * numberOfPrizesPerWinner;
            for (uint256 j = 0; j < numberOfPrizesPerWinner; ++j) {
                // starting prize index is 1-indexed, not 0-indexed
                // hence, we use the prefix increment so that value after increment is returned and used
                NFTData storage mytuple = epochERC721PrizeIdsData[epoch][++prizeIndex];
                mytuple.nftAddress.safeTransferFrom(address(this), msg.sender, mytuple.nftID);
            }
        }

        // claimMyShareERC20(epoch);
        // ERC20s
        uint256 numerator = epochUserERC20NumWinnerEntries[epoch][msg.sender];
        /**
         * @dev numberOfDrawWinners is the number of winners with duplicates
         */
        uint256 denominator = epochWinnerConfigs[epoch].numberOfDrawWinners;
        IERC20[] memory erc20RewardTokens = epochPrizeSets[epoch].erc20RewardTokens;
        for (uint256 i; i < erc20RewardTokens.length; i++) {
            IERC20 token = erc20RewardTokens[i];
            uint256 totalReward = epochERC20PrizeAmounts[epoch][token];
            uint256 userReward = (totalReward * numerator) / denominator;
            token.safeTransfer(msg.sender, userReward);
        }
        emit Claimed(msg.sender, epoch);
    }

    /**
        @dev - Claims your share of the prize for all epochs
    **/  
    function claimAllKnownShares() external {
        uint256 epoch = thisEpoch;
        unchecked {
            for (uint256 i = 1; i <= epoch; ++i) {
                if (isPrizeClaimable[i][msg.sender]) {
                    claimMyShare(i);
                }
            }
        }
    }

    /**
        @dev - Sweeps remaining NFTs after draw resolution
    **/  
    function sweepRemainderNfts(uint256 epoch) external onlyDeployer {
        require(epochToRandomNumber[epoch] != 0, "Unresolved draw");
        uint256 numNfts = epochPrizeSets[epoch].numERC721Prizes;
        // undistributed NFTs will be from the last index
        // prizeData is 1-indexed
        uint256 endIndex = numNfts - epochWinnerConfigs[epoch].remainder;
        unchecked {
            for (uint256 i = numNfts; i > endIndex; --i) {
                NFTData storage nftData = epochERC721PrizeIdsData[epoch][i];
                nftData.nftAddress.safeTransferFrom(address(this), msg.sender, nftData.nftID);
            }
        }
    }

    /**
        @dev - Sweeps unclaimed NFTs, but only after rewardSweepTime
    **/
    function sweepUnclaimedNfts(uint256 epoch, uint256[] calldata prizeIndices) external onlyDeployer {
        require(block.timestamp > rewardSweepTime, "Too early");
        unchecked {
            for (uint256 i; i < prizeIndices.length; ++i) {
                NFTData storage nftData = epochERC721PrizeIdsData[epoch][prizeIndices[i]];
                nftData.nftAddress.safeTransferFrom(address(this), msg.sender, nftData.nftID);
            }
        }
    }

    /**
        @dev - Helper functions
    **/      

    function addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}
