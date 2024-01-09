// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";


import "./IPnG.sol";
import "./ICACAO.sol";
import "./IFleet.sol";
import "./IRandomizer.sol";

import "./Accessable.sol";


contract Fleet is IFleet, Accessable, ReentrancyGuard, IERC721Receiver, Pausable {
    uint8[4] private _ranks = [5,6,7,8];
    
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    uint256 private totalRankStaked;
    uint256 private numGalleonsStaked;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isGalleon, uint256 value);
    event GalleonClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event PirateClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

    IPnG public nftContract;
    // reference to the WnD NFT contract
    address public pirateGame;
    // reference to the $CACAO contract for minting $CACAO earnings
    ICACAO public cacao;
    // reference to Randomer 
    IRandomizer public randomizer;

    // maps tokenId to stake
    mapping(uint256 => Stake) private fleet; 
    // maps rank to all Pirate staked with that rank
    mapping(uint256 => Stake[]) private sea; 
    // tracks location of each Pirate in Sea
    mapping(uint256 => uint256) private seaIndices; 
    // any rewards distributed when no pirates are staked
    uint256 private unaccountedRewards = 0; 
    // amount of $CACAO due for each rank point staked
    uint256 private cacaoPerRank = 0; 


    // galleons earn 10000 $CACAO per day
    uint256 public constant DAILY_CACAO_RATE = 10000 ether;
    // pirates take a 20% tax on all $CACAO claimed
    uint256 public constant CACAO_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $CACAO earned through staking
    uint256 public constant MAXIMUM_GLOBAL_CACAO = 2400000000 ether;

    // // galleons must have 2 days worth of $CACAO to unstake or else they're still in the sea
    uint256 public minimumToExit = 2 days;
    uint256 public minimumToClaim = 2 days;


    

    // amount of $CACAO earned so far
    uint256 public totalCacaoEarned;
    // the last time $CACAO was claimed
    uint256 private lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $CACAO
    bool public rescueEnabled = false;

    /**
     */
    constructor() {
        _pause();
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
            require(address(nftContract) != address(0) && address(cacao) != address(0) 
                && address(pirateGame) != address(0) && address(randomizer) != address(0), "Contracts not set");
            _;
    }

    function setContracts(address _cacao, address _nft, address _pirateGame, address _rand) external onlyAdmin {
        nftContract = IPnG(_nft);
        cacao = ICACAO(_cacao);
        pirateGame = _pirateGame;
        randomizer = IRandomizer(_rand);
    }


    /** STAKING */

    /**
     * adds Galleons and Pirates to the Fleet and Sea
     * @param account the address of the staker
     * @param tokenIds the IDs of the Galleons and Pirates to stake
     */
    function addManyToFleet(address account, uint16[] calldata tokenIds) external override 
        nonReentrant 
        onlyEOA
    {
        require(account == tx.origin, "account to sender mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(pirateGame)) { // dont do this step if its a mint + stake
                require(nftContract.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
                nftContract.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (nftContract.isGalleon(tokenIds[i])) 
                _addGalleonToFleet(account, tokenIds[i]);
            else 
                _addPirateToSea(account, tokenIds[i]);
        } 
    }

    /**
     * adds a single Galleon to the Fleet
     * @param account the address of the staker
     * @param tokenId the ID of the Galleon to add to the Fleet
     */
    function _addGalleonToFleet(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        fleet[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        numGalleonsStaked += 1;
        emit TokenStaked(account, tokenId, true, block.timestamp);
    }

    /**
     * adds a single Pirate to the Sea
     * @param account the address of the staker
     * @param tokenId the ID of the Pirate to add to the Sea
     */
    function _addPirateToSea(address account, uint256 tokenId) internal {
        uint8 rank = _rankForPirate(tokenId);
        totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
        seaIndices[tokenId] = sea[rank].length; // Store the location of the pirate in the Sea
        sea[rank].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(cacaoPerRank)
        })); // Add the pirate to the Sea
        emit TokenStaked(account, tokenId, false, cacaoPerRank);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $CACAO earnings and optionally unstake tokens from the Fleet / Sea
     * to unstake a Galleon it will require it has 2 days worth of $CACAO unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromFleetAndSea(uint16[] calldata tokenIds, bool unstake) external 
        whenNotPaused 
        _updateEarnings 
        nonReentrant 
        onlyEOA
    {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (nftContract.isGalleon(tokenIds[i])) {
                owed += _claimGalleonFromFleet(tokenIds[i], unstake);
            }
            else {
                owed += _claimPirateFromSea(tokenIds[i], unstake);
            }
        }
        cacao.updateInblockGuard();
        if (owed == 0) {
            return;
        }
        cacao.mint(_msgSender(), owed);
    }

    function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
        uint64 lastTokenWrite = nftContract.getTokenWriteBlock(tokenId);
        // Must check this, as getTokenTraits will be allowed since this contract is an admin
        require(lastTokenWrite < block.number, "hmmmm what doing?");

        Stake memory stake = fleet[tokenId];
        if (stake.owner == address(0) && stake.value == 0) {
            return 0;
        }

        if(nftContract.isGalleon(tokenId)) {
            if (totalCacaoEarned < MAXIMUM_GLOBAL_CACAO) {
                owed = (block.timestamp - stake.value) * DAILY_CACAO_RATE / 1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0; // $CACAO production stopped already
            } else {
                owed = (lastClaimTimestamp - stake.value) * DAILY_CACAO_RATE / 1 days; // stop earning additional $CACAO if it's all been earned
            }
        }
        else {
            uint8 rank = _rankForPirate(tokenId);
            owed = (rank) * (cacaoPerRank - stake.value); // Calculate portion of tokens based on Rank
        }
    }

    function calculatePirateReward(uint256 tokenId) external view returns (uint256 owed) {
        require(!nftContract.isGalleon(tokenId), "Not Pirate");
        uint8 rank = _rankForPirate(tokenId);
        Stake memory stake = sea[rank][seaIndices[tokenId]];
        if (stake.owner == address(0) && stake.value == 0) {
            return 0;
        }
        owed = (rank) * (cacaoPerRank - stake.value);            // Calculate portion of tokens based on Rank
    }

    /**
     * realize $CACAO earnings for a single Galleon and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Pirates
     * if unstaking, there is a 50% chance all $CACAO is stolen
     * @param tokenId the ID of the Galleons to claim earnings from
     * @param unstake whether or not to unstake the Galleons
     * @return owed - the amount of $CACAO earned
     */
    function _claimGalleonFromFleet(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = fleet[tokenId];
        require(stake.owner == _msgSender(), "Don't own the given token");
        require(block.timestamp - stake.value > minimumToClaim, "Claiming: Still in the sea");
        require(!(unstake && block.timestamp - stake.value < minimumToExit), "Witdraw: Still in the sea");

        if (unstake) {
            require(randomizer.canOperate(_msgSender(), tokenId), "Randomizer: cannot operate");
        }

        if (totalCacaoEarned < MAXIMUM_GLOBAL_CACAO) {
            owed = (block.timestamp - stake.value) * DAILY_CACAO_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $CACAO production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_CACAO_RATE / 1 days; // stop earning additional $CACAO if it's all been earned
        }
        if (unstake) {
            if (randomizer.random(tokenId) & 1 == 1) { // 50% chance of all $CACAO stolen
                _payPirateTax(owed);
                owed = 0;
            }
            delete fleet[tokenId];
            numGalleonsStaked -= 1;
            // Always transfer last to guard against reentrance
            nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Galleon
        } else {
            _payPirateTax(owed * CACAO_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked pirates
            owed = owed * (100 - CACAO_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Galleon owner
            fleet[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit GalleonClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $CACAO earnings for a single Pirate and optionally unstake it
     * Pirates earn $CACAO proportional to their rank
     * @param tokenId the ID of the Pirate to claim earnings from
     * @param unstake whether or not to unstake the Pirate
     * @return owed - the amount of $CACAO earned
     */
    function _claimPirateFromSea(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(nftContract.ownerOf(tokenId) == address(this), "Doesn't own token");
        uint8 rank = _rankForPirate(tokenId);
        Stake memory stake = sea[rank][seaIndices[tokenId]];
        require(stake.owner == _msgSender(), "Doesn't own token");
        owed = (rank) * (cacaoPerRank - stake.value); // Calculate portion of tokens based on Rank
        if (unstake) {
            totalRankStaked -= rank; // Remove rank from total staked
            Stake memory lastStake = sea[rank][sea[rank].length - 1];
            sea[rank][seaIndices[tokenId]] = lastStake; // Shuffle last Pirate to current position
            seaIndices[lastStake.tokenId] = seaIndices[tokenId];
            sea[rank].pop(); // Remove duplicate
            delete seaIndices[tokenId]; // Delete old mapping
            // Always remove last to guard against reentrance
            nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Pirate
        } else {
            sea[rank][seaIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(cacaoPerRank)
            }); // reset stake
        }
        emit PirateClaimed(tokenId, unstake, owed);
    }
    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint8 rank;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (nftContract.isGalleon(tokenId)) {
                stake = fleet[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete fleet[tokenId];
                numGalleonsStaked -= 1;
                nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Galleons
                emit GalleonClaimed(tokenId, true, 0);
            } else {
                rank = _rankForPirate(tokenId);
                stake = sea[rank][seaIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalRankStaked -= rank; // Remove Rank from total staked
                lastStake = sea[rank][sea[rank].length - 1];
                sea[rank][seaIndices[tokenId]] = lastStake; // Shuffle last Pirate to current position
                seaIndices[lastStake.tokenId] = seaIndices[tokenId];
                sea[rank].pop(); // Remove duplicate
                delete seaIndices[tokenId]; // Delete old mapping
                nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Pirate
                emit PirateClaimed(tokenId, true, 0);
            }
        }
    }

    /** ACCOUNTING */

    /** 
     * add $CACAO to claimable pot for the Sea
     * @param amount $CACAO to add to the pot
     */
    function _payPirateTax(uint256 amount) internal {
        if (totalRankStaked == 0) { // if there's no staked pirates
            unaccountedRewards += amount; // keep track of $CACAO due to pirates
            return;
        }
        // makes sure to include any unaccounted $CACAO 
        cacaoPerRank += (amount + unaccountedRewards) / totalRankStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $CACAO earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalCacaoEarned < MAXIMUM_GLOBAL_CACAO) {
            totalCacaoEarned += 
                (block.timestamp - lastClaimTimestamp)
                * numGalleonsStaked
                * DAILY_CACAO_RATE / 1 days; 
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function _setRescueEnabled(bool _enabled) external onlyAdmin {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    function _setRanks(uint8[4] memory ranks) external onlyAdmin {
        _ranks = ranks;
    }

    function _setTimeRestrictions(uint256 _toClaim, uint256 _toExit) external onlyAdmin {
        minimumToClaim = _toClaim;
        minimumToExit = _toExit;
    }



    /** READ ONLY */

    /**
     * gets the rank score for a Pirate
     * @param tokenId the ID of the Pirate to get the rank score for
     * @return the rank score of the Pirate (5-8)
     */
    function _rankForPirate(uint256 tokenId) internal view returns (uint8) {
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);
        return _ranks[s.alphaIndex]; // rank index is 0-3
    }

    /**
     * chooses a random Pirate thief when a newly minted token is stolen
     * @param seed a random value to choose a Pirate from
     * @return the owner of the randomly selected Pirate thief
     */
    function randomPirateOwner(uint256 seed) external view override returns (address) {
        if (totalRankStaked == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
        uint256 cumulative;
        seed >>= 32;
        uint8 rank;
        // loop through each bucket of Pirates with the same rank score
        for (uint8 j = 0; j < _ranks.length; j++) {
            rank = _ranks[j];
            cumulative += sea[rank].length * rank;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Pirate with that rank score
            return sea[rank][seed % sea[rank].length].owner;
        }
        return address(0x0);
    }

    function onERC721Received(address,address from,uint256,bytes calldata) 
        external pure override 
        returns (bytes4) 
    {
        require(from == address(0x0), "Cannot send to Fleet directly");
        return IERC721Receiver.onERC721Received.selector;
    }


    /**
     * allows owner to withdraw funds
     */
    function _withdraw() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }


    modifier onlyEOA {
        require(tx.origin == _msgSender() || _msgSender() == address(pirateGame), "Only EOA");
        _;
    }
}