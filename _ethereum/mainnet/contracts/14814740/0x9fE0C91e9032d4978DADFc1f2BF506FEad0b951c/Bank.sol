// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.1;

import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./LAND.sol";
import "./WildAbduction.sol";
import "./IBank.sol";
import "./ILAND.sol";
import "./IWildAbduction.sol";
import "./IRandomizer.sol";
import "./WAGGame.sol";

contract Bank is Ownable, IERC721Receiver, Pausable {

    // maximum alpha score for a Alien
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event CowboyStaked(address owner, uint256 tokenId, uint256 value);
    event MutantStaked(address owner, uint256 tokenId, uint256 value);
    event AlienStaked(address owner, uint256 tokenId, uint256 value);
    event CowboyClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event MutantClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event AlienClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

    // reference to the WAG NFT contract
    WildAbduction public game;
    // reference to WAG game contract
    WAGGame public wag;
    // reference to the $LAND contract for minting $LAND earnings
    ILAND public land;

    // maps tokenId to stake
    mapping(uint256 => Stake) public bank;
    // maps alpha to all Alien stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Alien in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no ... are staked
    uint256 public unaccountedRewards = 0;
    // amount of $LAND due for each alpha point staked
    uint256 public LANDPerAlpha = 0;

    // Cowboy earn 9000 $LAND per day
    uint256 public DAILY_LAND_RATE = 9000 ether;

    // Mutant earn 27000 $LAND per day
    uint256 public MUTANT_DAILY_LAND_RATE = 27000 ether;

    // Cowboy must have 2 days worth of $LAND to unstake or else it's too cold
    uint256 public MINIMUM_TO_EXIT = 2 days;
    // aliens take a 20% tax on all $LAND claimed
    uint256 public constant LAND_CLAIM_TAX_PERCENTAGE = 20;
    // master tax which is progessively decreasing;
    uint256 public MASTER_TAX = 30;
    // there will only ever be (roughly) 2.4 billion $LAND earned through staking
    uint256 public constant MAXIMUM_GLOBAL_LAND = 2400000000 ether;

    // amount of $LAND earned so far
    uint256 public totalLANDEarned;
    // number of Cowboy staked in the Bank
    uint256 public totalCowboyStaked;
    // number of Mutant staked in the Bank
    uint256 public totalMutantStaked;
    // the last time $LAND was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $LAND
    bool public rescueEnabled = false;

    bool private _reentrant = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    constructor() {}

    function setContracts(address _game, address _land, address _wag) external onlyOwner {
        game = WildAbduction(_game);
        land = ILAND(_land);
        wag = WAGGame(_wag);
    }

    /***STAKING */

    /**
     * adds Cowboy and Alien to the Bank and Pack
     * @param account the address of the staker
   * @param tokenIds the IDs of the Cowboy and Aliens to stake
   */
    function addManyToBankAndPack(address account, uint16[] calldata tokenIds) external nonReentrant {
        require( _msgSender() == tx.origin || _msgSender() == address(wag), "DONT GIVE YOUR TOKENS AWAY");
        require(account == tx.origin, "account to token mismatch");

        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }

            if (_msgSender() != address(wag)) {// dont do this step if its a mint + stake
                require(game.ownerOf(tokenIds[i]) == _msgSender(), "NOT YOUR TOKEN");
                game.transferFrom(_msgSender(), address(this), tokenIds[i]);
            }
            if (isMutant(tokenIds[i]))
                _addCowboyToBank(account, tokenIds[i], true);
            else if (isCowboy(tokenIds[i]))
                _addCowboyToBank(account, tokenIds[i], false);
            else
                _addAlienToBank(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Cowboy to the Bank
     * @param account the address of the staker
   * @param tokenId the ID of the Cowboy to add to the Bank
   */
    function _addCowboyToBank(address account, uint256 tokenId, bool _mutant) internal whenNotPaused _updateEarnings {
        bank[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp)
        });
        
        if (_mutant) {
            totalMutantStaked += 1;
            emit MutantStaked(account, tokenId, block.timestamp);
        } else {
            totalCowboyStaked += 1;
            emit CowboyStaked(account, tokenId, block.timestamp);
        }
    }

    /**
     * adds a single Alien to the Pack
     * @param account the address of the staker
   * @param tokenId the ID of the Alien to add to the Pack
   */
    function _addAlienToBank(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForAlien(tokenId);
        totalAlphaStaked += alpha;
        // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length;
        // Store the location of the Alien in the Pack
        pack[alpha].push(Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(LANDPerAlpha)
        }));
        // Add the Alien to the Pack
        emit AlienStaked(account, tokenId, LANDPerAlpha);
    }

    /***CLAIMING / UNSTAKING */

    /**
     * realize $LAND earnings and optionally unstake tokens from the Bank / Pack
     * to unstake a Cowboy it will require it has 2 days worth of $LAND unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake) external nonReentrant whenNotPaused _updateEarnings {
        require(_msgSender() == tx.origin || _msgSender() == address(wag) , "Only EOA");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isMutant(tokenIds[i]))
                owed += _claimCowboyFromBank(tokenIds[i], unstake, false);
            else if (isCowboy(tokenIds[i]))
                owed += _claimCowboyFromBank(tokenIds[i], unstake, true);
            else
                owed += _claimAlienFromPack(tokenIds[i], unstake);
        }

        // pay master tax when claiming, will be progressively decreased;
        owed *= (100 - MASTER_TAX) / 100;

        if (owed == 0) return;
        land.mint(_msgSender(), owed);
    }

    /**
     * realize $LAND earnings for a single Cowboy/Mutant and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Aliens
     * if unstaking, there is a 50% chance all $LAND is stolen
     * @param tokenId the ID of the Cowboy to claim earnings from
   * @param unstake whether or not to unstake the Cowboy
   * @return owed - the amount of $LAND earned
   */
    function _claimCowboyFromBank(uint256 tokenId, bool unstake, bool cowboy) internal returns (uint256 owed) {
        Stake memory stake = bank[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S LAND");

        // get rate for cowboys
        uint256 unstaking_rate = DAILY_LAND_RATE;
        // set rate if its a mutant
        if (!cowboy) {
            unstaking_rate = MUTANT_DAILY_LAND_RATE;
        }

        if (totalLANDEarned < MAXIMUM_GLOBAL_LAND) {
            owed = (block.timestamp - stake.value) * unstaking_rate / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $LAND production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * unstaking_rate / 1 days;
            // stop earning additional $LAND if it's all been earned
        }

        if (unstake) {
            if (cowboy) {
                if (random(block.timestamp) & 1 == 1) {// 50% chance of all $LAND stolen
                _payAlienTax(owed);
                owed = 0;
                totalCowboyStaked -= 1;
                }
            } else {
                totalMutantStaked -= 1;
            }
            
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back Cowboy
            delete bank[tokenId];
            

        } else {
            if (cowboy) {
                _payAlienTax(owed * LAND_CLAIM_TAX_PERCENTAGE / 100);
                // percentage tax to staked aliens
                owed = owed * (100 - LAND_CLAIM_TAX_PERCENTAGE) / 100;
                // remainder goes to Cowboy owner
            }
            bank[tokenId] = Stake({
                owner : _msgSender(),
                tokenId : uint16(tokenId),
                value : uint80(block.timestamp)
                });
            // reset stake
        }
        if (cowboy) {
            emit CowboyClaimed(tokenId, unstake, owed);
        } else {
            emit MutantClaimed(tokenId, unstake, owed);
        }
    }

    /**
     * realize $LAND earnings for a single Alien and optionally unstake it
     * Aliens earn $LAND proportional to their Alpha rank
     * @param tokenId the ID of the Alien to claim earnings from
   * @param unstake whether or not to unstake the Alien
   * @return owed - the amount of $LAND earned
   */
    function _claimAlienFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(game.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        uint256 alpha = _alphaForAlien(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (LANDPerAlpha - stake.value);
        // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha;
            // Remove Alpha from total staked
            game.transferFrom(address(this), _msgSender(), tokenId);
            // Send back Alien
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake;
            // Shuffle last Alien to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop();
            // Remove duplicate
            delete packIndices[tokenId];
            // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(LANDPerAlpha)
            });
            // reset stake
        }
        emit AlienClaimed(tokenId, unstake, owed);
    }

    /***ACCOUNTING */

    /**
     * add $LAND to claimable pot for the Pack
     * @param amount $LAND to add to the pot
   */
    function _payAlienTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {// if there's no staked aliens
            unaccountedRewards += amount;
            // keep track of $LAND due to aliens
            return;
        }
        // makes sure to include any unaccounted $LAND
        LANDPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $LAND earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalLANDEarned < MAXIMUM_GLOBAL_LAND) {
            totalLANDEarned +=
            (block.timestamp - lastClaimTimestamp)
            * totalCowboyStaked
            * DAILY_LAND_RATE / 1 days;

            totalLANDEarned +=
            (block.timestamp - lastClaimTimestamp)
            * totalMutantStaked
            * MUTANT_DAILY_LAND_RATE / 1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /***ADMIN */

    function setSettings(uint256 rate, uint256 mutant_rate, uint256 exit) external onlyOwner {
        MINIMUM_TO_EXIT = exit;
        DAILY_LAND_RATE = rate;
        MUTANT_DAILY_LAND_RATE = mutant_rate;
    }

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * reduces master tax
     */
    function reduceMasterTax(uint256 tax) external onlyOwner {
        MASTER_TAX = tax;
    }

    /***READ ONLY */

    /**
     * checks if a token is a Cowboy
     * @param tokenId the ID of the token to check
   * @return Cowboy - whether or not a token is a Cowboy
   */
    function isCowboy(uint256 tokenId) public view returns (bool Cowboy) {
        (Cowboy, , , , , , ,) = game.tokenTraits(tokenId);
    }

    /**
     * checks if a token is a Cowboy
     * @param tokenId the ID of the token to check
   * @return Mutant - whether or not a token is a Cowboy
   */
    function isMutant(uint256 tokenId) public view returns (bool Mutant) {
        (,Mutant, , , , , ,) = game.tokenTraits(tokenId);
    }


    /**
     * gets the alpha score for a Alien
     * @param tokenId the ID of the Alien to get the alpha score for
   * @return the alpha score of the Alien (5-8)
   */
    function _alphaForAlien(uint256 tokenId) internal view returns (uint8) {
        (, , , , , , , uint8 alphaIndex) = game.tokenTraits(tokenId);
        return MAX_ALPHA - alphaIndex;
    }

    /**
     * chooses a random Alien Cowboy when a newly minted token is stolen
     * @param seed a random value to choose a Alien from
   * @return the owner of the randomly selected Alien Cowboy
   */
    function randomAlienOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;
        // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Aliens with the same alpha score
        for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Alien with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}