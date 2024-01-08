// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableUpgradeable.sol";
import "./Proxied.sol";

import "./IERC20.sol";

import "./FarmLookupLibrary.sol";
import "./VRFLibrary.sol";

import "./IChickenNoodle.sol";
import "./IEgg.sol";
import "./IFarm.sol";
import "./IRandomnessConsumer.sol";
import "./IRandomnessProvider.sol";

contract Farm is IRandomnessConsumer, Proxied, PausableUpgradeable {
    using VRFLibrary for VRFLibrary.VRFData;

    // maximum tier score for a Noodle
    uint8 public constant MAX_TIER_SCORE = 8;

    struct ClaimRequest {
        address owner;
        uint256 owed;
        bytes32 hash;
    }

    event ClaimProcessed(address owner, uint256 owed, bool stolen);
    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event ChickenClaimed(
        uint256 tokenId,
        uint256 earned,
        uint256 stolen,
        bool unstaked
    );
    event NoodleClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the ChickenNoodle NFT contract
    IChickenNoodle public chickenNoodle;
    // reference to the $EGG contract for minting $EGG earnings
    IEgg egg;

    // maps tokenId to stake
    mapping(uint16 => IFarm.Stake) public henHouse;
    // maps tier score to all Noodle stakes with their tier
    mapping(uint8 => IFarm.Stake[]) public den;
    // tracks location of each Noodle in Den
    mapping(uint16 => uint16) public denIndices;
    // total tier score scores staked
    uint256 public totalTierScoreStaked;
    // any rewards distributed when no noodles are staked
    uint256 public unaccountedRewards;
    // amount of $EGG due for each tier score point staked
    uint256 public eggPerTierScore;

    // Gen 0 Chickens earn 10000 $EGG per day
    uint256 public constant DAILY_GEN0_EGG_RATE = 10000 ether;
    // Gen 1 Chickens earn 6000 $EGG per day
    uint256 public constant DAILY_GEN1_EGG_RATE = 6000 ether;
    // Chicken must have 2 days worth of $EGG to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // noodles take a 20% tax on all $EGG claimed
    uint256 public constant EGG_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $EGG earned through staking
    uint256 public constant MAXIMUM_GLOBAL_EGG = 2400000000 ether;

    // amount of $EGG earned so far
    uint256 public totalEggEarned;
    // the last time $EGG was claimed
    uint256 public lastClaimTimestamp;
    // number of Chicken staked in the HenHouse
    uint16 public totalChickenStaked;
    // number of Gen 0 Chicken staked in the HenHouse
    uint16 public gen0ChickensStaked;

    // emergency rescue to allow unstaking without any checks but without $EGG
    bool public rescueEnabled;

    // number of claims have been processed so far
    uint16 public claimsProcessed;
    // number of claims have been requested so far
    uint16 public claimsRequested;

    VRFLibrary.VRFData private vrf;

    mapping(uint256 => ClaimRequest) internal claims;

    uint256 randomnessInterval;
    uint256 randomnessClaimsNeeded;
    uint256 randomnessClaimsMinimum;

    // /**
    //  * @param _chickenNoodle reference to the ChickenNoodleSoup NFT contract
    //  * @param _egg reference to the $EGG token
    //  */
    // constructor(address _egg, address _chickenNoodle) {
    //     initialize(_egg, _chickenNoodle);
    // }

    /**
     * @param _chickenNoodle reference to the ChickenNoodleSoup NFT contract
     * @param _egg reference to the $EGG token
     */
    function initialize(address _egg, address _chickenNoodle) public proxied {
        __Pausable_init();

        egg = IEgg(_egg);
        chickenNoodle = IChickenNoodle(_chickenNoodle);

        randomnessInterval = 12 hours;
        randomnessClaimsNeeded = 50;
        randomnessClaimsMinimum = 0;
    }

    function processingStats()
        public
        view
        returns (
            bool requestPending,
            uint256 maxIdAvailableToProcess,
            uint256 readyForProcessing,
            uint256 waitingToBeProcessed,
            uint256 timeTellNextRandomnessRequest
        )
    {
        return vrf.processingStats(claimsRequested, claimsProcessed, randomnessInterval);
    }

    function getTotalStaked()
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        return FarmLookupLibrary.getTotalStaked(address(this), den);
    }

    function getStakedBalanceOf(address tokenOwner)
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        return
            FarmLookupLibrary.getStakedBalanceOf(
                address(this),
                tokenOwner,
                henHouse,
                den,
                denIndices
            );
    }

    function getStakedChickensForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint256[] memory timeTellUnlock,
            uint256[] memory earnedEgg
        )
    {
        return
            FarmLookupLibrary.getStakedChickensForOwner(
                address(this),
                IFarm.PagingData(tokenOwner, limit, page),
                henHouse,
                den,
                denIndices
            );
    }

    function getStakedNoodlesForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint8[] memory tier,
            uint256[] memory taxedEgg
        )
    {
        return
            FarmLookupLibrary.getStakedNoodlesForOwner(
                address(this),
                IFarm.PagingData(tokenOwner, limit, page),
                henHouse,
                den,
                denIndices
            );
    }

    /** STAKING */

    /**
     * adds Chicken and Noodles to the HenHouse and Den
     * @param tokenIds the IDs of the Chicken and Noodles to stake
     */
    function addManyToHenHouseAndDen(uint16[] calldata tokenIds) external {
        require(tx.origin == _msgSender(), 'Only EOA');

        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(
                chickenNoodle.ownerOf(tokenIds[i]) == _msgSender(),
                'Can only stake your own tokens'
            );

            chickenNoodle.transferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

            if (isChicken(tokenIds[i])) {
                _addChickenToHenHouse(tokenIds[i]);
            } else {
                _addNoodleToDen(tokenIds[i]);
            }
        }
    }

    /**
     * adds a single Chicken to the HenHouse
     * @param tokenId the ID of the Chicken to add to the HenHouse
     */
    function _addChickenToHenHouse(uint16 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        henHouse[tokenId] = IFarm.Stake({
            owner: _msgSender(),
            tokenId: tokenId,
            value: uint80(block.timestamp)
        });
        if (tokenId <= chickenNoodle.PAID_TOKENS()) {
            gen0ChickensStaked++;
        }
        totalChickenStaked++;
        emit TokenStaked(_msgSender(), tokenId, block.timestamp);
    }

    /**
     * adds a single Noodle to the Den
     * @param tokenId the ID of the Noodle to add to the Den
     */
    function _addNoodleToDen(uint16 tokenId) internal {
        uint8 tierScore = tierScoreForNoodle(tokenId);
        totalTierScoreStaked += tierScore; // Portion of earnings ranges from 8 to 4
        denIndices[tokenId] = uint16(den[tierScore].length); // Store the location of the noodle in the Den
        den[tierScore].push(
            IFarm.Stake({
                owner: _msgSender(),
                tokenId: tokenId,
                value: uint80(eggPerTierScore)
            })
        ); // Add the noodle to the Den
        emit TokenStaked(_msgSender(), tokenId, eggPerTierScore);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $EGG earnings and optionally unstake tokens from the HenHouse / Den
     * to unstake a Chicken it will require it has 2 days worth of $EGG unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromHenHouseAndDen(
        uint16[] calldata tokenIds,
        bool unstake
    ) external whenNotPaused _updateEarnings {
        require(tx.origin == _msgSender(), 'Only EOA');

        uint256 owed = 0;
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(
                chickenNoodle.ownerOf(tokenIds[i]) == address(this),
                'Can only claim tokens that are staked'
            );

            if (isChicken(tokenIds[i])) {
                owed += _claimChickenFromHenHouse(tokenIds[i], unstake);
            } else {
                owed += _claimNoodleFromDen(tokenIds[i], unstake);
            }
        }
        if (owed == 0) return;
        egg.mint(_msgSender(), owed);
    }

    /**
     * realize $EGG earnings for a single Chicken and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Noodles
     * if unstaking, there is a 50% chance all $EGG is stolen
     * @param tokenId the ID of the Chicken to claim earnings from
     * @param unstake whether or not to unstake the Chicken
     * @return owed - the amount of $EGG earned
     */
    function _claimChickenFromHenHouse(uint16 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        IFarm.Stake memory stake = henHouse[tokenId];
        require(
            stake.owner == _msgSender(),
            'Can only claim tokens you staked'
        );
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            'Can only unstake if you have waited the minimum exit time'
        );
        if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
            owed =
                ((block.timestamp - stake.value) *
                    (
                        tokenId <= chickenNoodle.PAID_TOKENS()
                            ? DAILY_GEN0_EGG_RATE
                            : DAILY_GEN1_EGG_RATE
                    )) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $EGG production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) *
                    (
                        tokenId <= chickenNoodle.PAID_TOKENS()
                            ? DAILY_GEN0_EGG_RATE
                            : DAILY_GEN1_EGG_RATE
                    )) /
                1 days; // stop earning additional $EGG if it's all been earned
        }

        uint256 stolen;

        if (unstake) {
            claimsRequested++;
            claims[claimsRequested] = ClaimRequest({
                owner: _msgSender(),
                owed: owed,
                hash: blockhash(block.number - 1)
            });

            owed = 0;
            delete henHouse[tokenId];
            if (tokenId <= chickenNoodle.PAID_TOKENS()) {
                gen0ChickensStaked--;
            }
            totalChickenStaked--;

            chickenNoodle.transferFrom(address(this), _msgSender(), tokenId); // send back Chicken
        } else {
            stolen = (owed * EGG_CLAIM_TAX_PERCENTAGE) / 100;
            _payNoodleTax(stolen); // percentage tax to staked noodles
            owed = owed - stolen; // remainder goes to Chicken owner
            henHouse[tokenId] = IFarm.Stake({
                owner: _msgSender(),
                tokenId: tokenId,
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit ChickenClaimed(tokenId, owed, stolen, unstake);

        checkRandomness(false);
    }

    function checkRandomness(bool force) public {
        force = force && _msgSender() == _proxyAdmin();

        if (force) {
            vrf.newRequest();
        } else {
            vrf.checkRandomness(
                claimsRequested, 
                claimsProcessed,
                randomnessInterval,
                randomnessClaimsNeeded,
                randomnessClaimsMinimum);
        }

        _processNext();
    }

    function process(uint256 amount) external override {
        for (uint256 i = 0; i < amount; i++) {
            if (!_processNext()) break;
        }
    }

    function setRandomnessResult(bytes32 requestId, uint256 randomness)
        external
        override
    {
        vrf.setRequestResults(requestId, randomness, claimsRequested);
    }

    function processNext() external override returns (bool) {
        return _processNext();
    }

    function _processNext() internal returns (bool) {
        uint256 claimId = claimsProcessed + 1;

        (bool available, uint256 randomness) = vrf.randomnessForId(claimId);

        if (available) {
            uint256 seed = random(claimId, randomness);

            if (seed & 1 == 1) {
                // 50% chance of all $EGG stolen
                _payNoodleTax(claims[claimId].owed);
                emit ClaimProcessed(
                    claims[claimId].owner,
                    claims[claimId].owed,
                    true
                );
            } else {
                egg.mint(claims[claimId].owner, claims[claimId].owed);
                emit ClaimProcessed(
                    claims[claimId].owner,
                    claims[claimId].owed,
                    false
                );
            }

            delete claims[claimId];
            claimsProcessed++;
            return true;
        }

        return false;
    }

    /**
     * realize $EGG earnings for a single Noodle and optionally unstake it
     * Noodles earn $EGG proportional to their Tier score
     * @param tokenId the ID of the Noodle to claim earnings from
     * @param unstake whether or not to unstake the Noodle
     * @return owed - the amount of $EGG earned
     */
    function _claimNoodleFromDen(uint16 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        uint8 tierScore = tierScoreForNoodle(tokenId);
        IFarm.Stake memory stake = den[tierScore][denIndices[tokenId]];

        require(
            stake.owner == _msgSender(),
            'Can only claim tokens you staked'
        );

        owed = (tierScore) * (eggPerTierScore - stake.value); // Calculate portion of tokens based on Tier score
        if (unstake) {
            totalTierScoreStaked -= tierScore; // Remove Tier score from total staked
            IFarm.Stake memory lastStake = den[tierScore][
                den[tierScore].length - 1
            ];
            den[tierScore][denIndices[tokenId]] = lastStake; // Shuffle last Noodle to current position
            denIndices[lastStake.tokenId] = denIndices[tokenId];
            den[tierScore].pop(); // Remove duplicate
            delete denIndices[tokenId]; // Delete old mapping

            chickenNoodle.transferFrom(address(this), _msgSender(), tokenId); // Send back Noodle
        } else {
            den[tierScore][denIndices[tokenId]] = IFarm.Stake({
                owner: _msgSender(),
                tokenId: tokenId,
                value: uint80(eggPerTierScore)
            }); // reset stake
        }
        emit NoodleClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint16[] calldata tokenIds) external {
        require(rescueEnabled, 'Rescue is currently disabled');

        uint16 tokenId;
        IFarm.Stake memory stake;
        IFarm.Stake memory lastStake;
        uint8 tierScore;

        for (uint16 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isChicken(tokenId)) {
                stake = henHouse[tokenId];

                require(
                    stake.owner == _msgSender(),
                    'Can only claim tokens you staked'
                );

                delete henHouse[tokenId];
                if (tokenId <= chickenNoodle.PAID_TOKENS()) {
                    gen0ChickensStaked--;
                }
                totalChickenStaked--;

                chickenNoodle.transferFrom(
                    address(this),
                    _msgSender(),
                    tokenId
                ); // send back Chicken

                emit ChickenClaimed(tokenId, 0, 0, true);
            } else {
                tierScore = tierScoreForNoodle(tokenId);
                stake = den[tierScore][denIndices[tokenId]];

                require(
                    stake.owner == _msgSender(),
                    'Can only claim tokens you staked'
                );

                totalTierScoreStaked -= tierScore; // Remove Tier score from total staked
                lastStake = den[tierScore][den[tierScore].length - 1];
                den[tierScore][denIndices[tokenId]] = lastStake; // Shuffle last Noodle to current position
                denIndices[lastStake.tokenId] = denIndices[tokenId];
                den[tierScore].pop(); // Remove duplicate
                delete denIndices[tokenId]; // Delete old mapping

                chickenNoodle.transferFrom(
                    address(this),
                    _msgSender(),
                    tokenId
                ); // Send back Noodle

                emit NoodleClaimed(tokenId, 0, true);
            }
        }
    }

    /**
     * allows owner to rescue tokens
     */
    function rescueTokens(IERC20 token, uint256 amount)
        external
        onlyProxyAdmin
    {
        token.transfer(_proxyAdmin(), amount);
    }

    /** ACCOUNTING */

    /**
     * add $EGG to claimable pot for the den
     * @param amount $EGG to add to the pot
     */
    function _payNoodleTax(uint256 amount) internal {
        if (totalTierScoreStaked == 0) {
            // if there's no staked noodles
            unaccountedRewards += amount; // keep track of $EGG due to noodles
            return;
        }
        // makes sure to include any unaccounted $EGG
        eggPerTierScore += (amount + unaccountedRewards) / totalTierScoreStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $EGG earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
            totalEggEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    gen0ChickensStaked *
                    DAILY_GEN0_EGG_RATE) /
                1 days;
            totalEggEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    (gen0ChickensStaked - gen0ChickensStaked) *
                    DAILY_GEN1_EGG_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random values
     * @param _randomnessProvider the address of the new RandomnessProvider
     */
    function setRandomnessProvider(address _randomnessProvider)
        external
        override
        onlyProxyAdmin
    {
        vrf.setRandomnessProvider(_randomnessProvider);
    }

    /**
     * called to upoate fee to get randomness
     * @param _fee the fee required for getting randomness
     */
    function updateRandomnessFee(uint256 _fee)
        external
        override
        onlyProxyAdmin
    {
        vrf.updateFee(_fee);
    }

    /**
     * allows owner to rescue LINK tokens
     */
    function rescueLINK(uint256 amount) external override onlyProxyAdmin {
        vrf.rescueLINK(_proxyAdmin(), amount);
    }

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyProxyAdmin {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyProxyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    /**
     * checks if a token is a Chicken
     * @param tokenId the ID of the token to check
     * @return chicken - whether or not a token is a Chicken
     */
    function isChicken(uint16 tokenId) public view returns (bool) {
        return chickenNoodle.tokenTraits(tokenId).isChicken;
    }

    /**
     * gets the tier score for a Noodle
     * @param tokenId the ID of the Noodle to get the tier score for
     * @return the tier score of the Noodle (5-8)
     */
    function tierScoreForNoodle(uint16 tokenId) public view returns (uint8) {
        return chickenNoodle.tokenTraits(tokenId).tier + 3; // tier is 5-1
    }

    /**
     * chooses a random Noodle thief when a newly minted token is stolen
     * @param seed a random value to choose a Noodle from
     * @return the owner of the randomly selected Noodle thief
     */
    function randomNoodleOwner(uint256 seed) external view returns (address) {
        if (totalTierScoreStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalTierScoreStaked; // choose a value from 0 to total tier score staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Noodles with the same tier score
        for (uint8 i = MAX_TIER_SCORE - 4; i <= MAX_TIER_SCORE; i++) {
            cumulative += den[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Noodle with that tier score
            return den[i][seed % den[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param claimId a value ensure different outcomes for different sources in the same block
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 claimId, uint256 seed)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(claimId, claims[claimId].hash, seed))
            );
    }
}
