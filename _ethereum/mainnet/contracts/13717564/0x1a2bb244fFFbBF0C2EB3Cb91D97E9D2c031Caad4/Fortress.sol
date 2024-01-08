// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Gains.sol";
import "./Degens.sol";

contract Fortress is IFortress, Ownable, IERC721Receiver, Pausable {

    // maximum alpha score for a Zombie
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event BBAClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event ZombieClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the Characters NFT contract
    IDegens degens;
    // reference to the $GAINS contract for minting $GAINS earnings
    IGains gains;

    // maps tokenId to stake
    mapping(uint256 => Stake) public fortress;
    // maps alpha to all zombie stakes with that alpha
    mapping(uint256 => Stake[]) public horde;
    // tracks location of each zombie in horde
    mapping(uint256 => uint256) public hordeIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no wolves are staked
    uint256 public unaccountedRewards = 0;
    // amount of $GAINS due for each alpha point staked
    uint256 public gainsPerAlpha = 0;

    // bba earn 10000 $GAINS per day
    uint256 public constant DAILY_GAINS_RATE = 10000 ether;
    // bba must have 2 days worth of $GAINS to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 1 days;
    // wolves take a 20% tax on all $GAINS claimed
    uint256 public constant GAINS_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $GAINS earned through staking
    uint256 public constant MAXIMUM_GLOBAL_GAINS_POSSIBLE = 2400000000 ether;

    // amount of $GAINS earned so far
    uint256 public totalGainsEarned;
    // number of bba staked in the fortress
    uint256 public totalBBAStaked;
    // the last time $GAINS was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $GAINS
    bool public rescueEnabled = false;

    /**
     * @param _degens reference to the GameOfDegens NFT contract
   * @param _gains reference to the $GAINS token
   */
    constructor(address _degens, address _gains) {
        degens = IDegens(_degens);
        gains = IGains(_gains);
    }

    /** STAKING */

    /**
     * adds bba and Wolves to the fortress and horde
     * @param account the address of the staker
   * @param tokenIds the IDs of the bba and Wolves to stake
   */
    function addDegensToFortressAndHorde(address account, uint16[] calldata tokenIds) external override {
        require(account == _msgSender() || _msgSender() == address(degens), "DONT GIVE YOUR TOKENS AWAY");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(degens)) {// dont do this step if its a mint + stake
                require(degens.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
                degens.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue;
                // there may be gaps in the array for stolen tokens
            }

            if (!degens.isZombies(degens.getTokenTraits(tokenIds[i])))
                _addBullBearsAndApesToFortress(account, tokenIds[i]);
            else
                _addZombieToHorde(account, tokenIds[i]);
        }
    }

    /**
     * adds a single bba to the fortress
     * @param account the address of the staker
   * @param tokenId the ID of the bba to add to the fortress
   */
    function _addBullBearsAndApesToFortress(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        fortress[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp)
        });
        totalBBAStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single zombie to the horde
     * @param account the address of the staker
   * @param tokenId the ID of the zombie to add to the horde
   */
    function _addZombieToHorde(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForZombie(tokenId);
        totalAlphaStaked += alpha;
        // Portion of earnings ranges from 8 to 5
        hordeIndices[tokenId] = horde[alpha].length;
        // Store the location of the zombie in the horde
        horde[alpha].push(Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(gainsPerAlpha)
        }));
        // Add the zombie to the horde
        emit TokenStaked(account, tokenId, gainsPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $GAINS earnings and optionally unstake tokens from the fortress / horde
     * to unstake a bba it will require it has 2 days worth of $GAINS unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromFortressAndHorde(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (!degens.isZombies(degens.getTokenTraits(tokenIds[i])))
                owed += _claimBBAFromFortress(tokenIds[i], unstake);
            else
                owed += _claimZombieFromHorde(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        gains.mint(_msgSender(), owed);
    }

    /**
     * realize $GAINS earnings for a single bba and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Wolves
     * if unstaking, there is a 50% chance all $GAINS is stolen
     * @param tokenId the ID of the bba to claim earnings from
   * @param unstake whether or not to unstake the bba
   * @return owed - the amount of $GAINS earned
   */
    function _claimBBAFromFortress(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = fortress[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA WAIT FOR THE GAINS TO ACCUMULATE");
        if (totalGainsEarned < MAXIMUM_GLOBAL_GAINS_POSSIBLE) {
            owed = (block.timestamp - stake.value) * DAILY_GAINS_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $GAINS production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_GAINS_RATE / 1 days;
            // stop earning additional $GAINS if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1 && !degens.isBears(degens.getTokenTraits(tokenId))) {// 50% chance of all $GAINS stolen
                _payZombieTax(owed);
                owed = 0;
            }
            delete fortress[tokenId];
            totalBBAStaked -= 1;
            degens.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            // send back bba
        } else {
            uint256 theTax = GAINS_CLAIM_TAX_PERCENTAGE;

            if (degens.isBull(degens.getTokenTraits(tokenId)))
                theTax = 1;

            _payZombieTax(owed * theTax / 100);
            // percentage tax to staked wolves
            owed = owed * (100 - theTax) / 100;
            // remainder goes to bba owner
            fortress[tokenId] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(block.timestamp)
            });
            // reset stake
        }
        if (degens.isApes(degens.getTokenTraits(tokenId)))
            owed = owed * 3 / 2;

        emit BBAClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $GAINS earnings for a single zombie and optionally unstake it
     * Wolves earn $GAINS proportional to their Alpha rank
     * @param tokenId the ID of the zombie to claim earnings from
   * @param unstake whether or not to unstake the zombie
   * @return owed - the amount of $GAINS earned
   */
    function _claimZombieFromHorde(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(degens.ownerOf(tokenId) == address(this), "AINT A PART OF THE horde");
        uint256 alpha = _alphaForZombie(tokenId);
        Stake memory stake = horde[alpha][hordeIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (gainsPerAlpha - stake.value);
        // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha;
            // Send back zombie
            Stake memory lastStake = horde[alpha][horde[alpha].length - 1];
            horde[alpha][hordeIndices[tokenId]] = lastStake;
            // Shuffle last zombie to current position
            hordeIndices[lastStake.tokenId] = hordeIndices[tokenId];
            horde[alpha].pop();
            // Remove duplicate
            delete hordeIndices[tokenId];
            // Delete old mapping
            // Remove Alpha from total staked
            degens.safeTransferFrom(address(this), _msgSender(), tokenId, "");
        } else {
            horde[alpha][hordeIndices[tokenId]] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(gainsPerAlpha)
            });
            // reset stake
        }
        emit ZombieClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (!degens.isZombies(degens.getTokenTraits(tokenIds[i]))) {
                stake = fortress[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete fortress[tokenId];
                totalBBAStaked -= 1;
                degens.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                // send back bba
                emit BBAClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForZombie(tokenId);
                stake = horde[alpha][hordeIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha;
                // Send back zombie
                lastStake = horde[alpha][horde[alpha].length - 1];
                horde[alpha][hordeIndices[tokenId]] = lastStake;
                // Shuffle last zombie to current position
                hordeIndices[lastStake.tokenId] = hordeIndices[tokenId];
                horde[alpha].pop();
                // Remove duplicate
                delete hordeIndices[tokenId];
                // Remove Alpha from total staked
                degens.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                // Delete old mapping
                emit ZombieClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $GAINS to claimable pot for the horde
     * @param amount $GAINS to add to the pot
   */
    function _payZombieTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {// if there's no staked wolves
            unaccountedRewards += amount;
            // keep track of $GAINS due to wolves
            return;
        }
        // makes sure to include any unaccounted $GAINS
        gainsPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $GAINS earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalGainsEarned < MAXIMUM_GLOBAL_GAINS_POSSIBLE) {
            totalGainsEarned +=
            (block.timestamp - lastClaimTimestamp)
            * totalBBAStaked
            * DAILY_GAINS_RATE / 1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

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

    /** READ ONLY */

    /**
     * gets the alpha score for a zombie
     * @param tokenId the ID of the zombie to get the alpha score for
   * @return the alpha score of the zombie (5-8)
   */
    function _alphaForZombie(uint256 tokenId) internal view returns (uint8) {
        IDegens.Degen memory s = degens.getTokenTraits(tokenId);
        return MAX_ALPHA - s.alphaIndex;
    }

    /**
     * chooses a random Zombie thief when a newly minted token is stolen
     * @param seed a random value to choose a zombie from
   * @return the owner of the randomly selected zombie thief
   */
    function randomZombieOwner(uint256 seed) external override view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;
        // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Wolves with the same alpha score
        for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += horde[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random zombie with that alpha score
            return horde[i][seed % horde[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            )));
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Fortress directly");
        return IERC721Receiver.onERC721Received.selector;
    }


}
