// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.10;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./PunkedPup.sol";
import "./BONE.sol";
import "./Ownable.sol";
import "./IShelter.sol";
import "./ReentrancyGuard.sol";

contract Shelter is
    IShelter,
    Ownable,
    ReentrancyGuard,
    IERC721Receiver,
    Pausable
{
    // maximum alpha score for a Cat
    uint8 public constant MAX_ALPHA = 9;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event PupClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event CatClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event TokenUnstaked(uint256 tokenId);

    // reference to the PunkedPup NFT contract
    PunkedPup private punkedPup;
    // reference to the $BONE contract for minting $BONE earnings
    BONE private bone;

    // maps tokenId to stake
    mapping(uint256 => Stake) public shelter;
    // maps alpha to all Cats stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // array of staked tokens
    uint256[] public dogHouse;
    // maps dog catcher tokenId to address
    mapping(uint256 => address) public stakedDogCatcher;
    // tracks location of each Cat in Pack
    mapping(uint256 => uint256) public packIndices;
    // tracks location of each Dog in dogHouse
    mapping(uint256 => uint256) public dogHouseIndices;
    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => PupCat) private tokenTraits;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no cats are staked
    uint256 public unaccountedRewards = 0;
    // amount of $BONE due for each alpha point staked
    uint256 public bonePerAlpha = 0;
    // pup earn 100 $BONE per day
    uint256 public constant DAILY_BONE_RATE = 100 ether;
    // pup must have 2 days worth of $BONE to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // cats take a 20% tax on all $BONE claimed
    uint256 public constant BONE_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 10 billion $BONE earned through staking
    uint256 public constant MAXIMUM_GLOBAL_BONE = 10000000000 ether;

    // amount of $BONE earned so far
    uint256 public totalBoneEarned;
    // number of Pup staked in the Shelter
    uint256 public totalPupStaked;
    // the last time $BONE was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $BONE
    bool public rescueEnabled = false;

    /**
     * @param _punkedPup reference to the PunkedPup NFT contract
     * @param _bone reference to the $BONE token
     */
    constructor(address _punkedPup, address _bone) {
        punkedPup = PunkedPup(_punkedPup);
        bone = BONE(_bone);
        _pause();
    }

    /** STAKING */

    /**
     * adds Pup and Cats to the Shelter and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Pup and Cats to stake
     */
    function addManyToShelterAndPack(
        address account,
        uint16[] calldata tokenIds
    ) external nonReentrant {
        require(
            tx.origin == _msgSender() || _msgSender() == address(punkedPup),
            "Only EOA"
        );
        require(account == tx.origin, "account to sender mismatch");
        uint256 seed;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            seed = random(tokenIds[i]);
            uint8 alphaIndex = uint8(randomWithRange(seed, 5)) + 1;

            if (tokenTraits[tokenIds[i]].alphaIndex == 0) {
                tokenTraits[tokenIds[i]] = PupCat(true, alphaIndex, false);
            }
            if (_msgSender() != address(punkedPup)) {
                // dont do this step if its a mint + stake
                require(
                    punkedPup.ownerOf(tokenIds[i]) == _msgSender(),
                    "You don't own this token"
                );
                punkedPup.transferFrom(
                    _msgSender(),
                    address(this),
                    tokenIds[i]
                );
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }
            if (isPup(tokenIds[i])) _addPupToShelter(account, tokenIds[i]);
            else _addCatToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Pup to the Shelter
     * @param account the address of the staker
     * @param tokenId the ID of the Pup to add to the Shelter
     */
    function _addPupToShelter(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        shelter[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        totalPupStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Cat to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Cat to add to the Pack
     */
    function _addCatToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForCat(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length; // Store the location of the cat in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(bonePerAlpha)
            })
        ); // Add the cat to the Pack

        if (isDogCatcher(tokenId)) {
            dogHouse.push(tokenId);
            stakedDogCatcher[tokenId] = account;
            dogHouseIndices[tokenId] = dogHouse.length; // Store the location of the dogCatcher in the dogHouse
        }
        emit TokenStaked(account, tokenId, bonePerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $BONE earnings and optionally unstake tokens from the Shelter / Pack
     * to unstake a Pup it will require it has 2 days worth of $BONE unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromShelterAndPack(
        uint16[] calldata tokenIds,
        bool unstake
    ) external whenNotPaused _updateEarnings nonReentrant {
        require(
            tx.origin == _msgSender() || _msgSender() == address(punkedPup),
            "Only EOA"
        );
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isPup(tokenIds[i]))
                owed += _claimPupFromShelter(tokenIds[i], unstake);
            else owed += _claimCatFromPack(tokenIds[i], unstake);
        }
        bone.updateOriginAccess();
        if (owed == 0) return;
        bone.mint(_msgSender(), owed);
    }

    /**
     * realize $BONE earnings for a single Pup and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Cats
     * if unstaking, there is a 50% chance all $BONE is stolen
     * @param tokenId the ID of the Pup to claim earnings from
     * @param unstake whether or not to unstake the Pup
     * @return owed - the amount of $BONE earned
     */
    function _claimPupFromShelter(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = shelter[tokenId];
        uint8 alpha = tokenTraits[tokenId].alphaIndex;
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "GONNA BE COLD WITHOUT TWO DAY'S BONE"
        );
        if (totalBoneEarned < MAXIMUM_GLOBAL_BONE) {
            owed =
                ((block.timestamp - stake.value) * DAILY_BONE_RATE * alpha) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $BONE production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_BONE_RATE * alpha) /
                1 days; // stop earning additional $BONE if it's all been earned
        }
        if (unstake) {
            address recipient = _msgSender();
            if (random(tokenId) & 1 == 1) {
                // 50% chance of pup stolen
                recipient = getRandomDogCatcher(random(tokenId));
                if (recipient == address(0x0)) {
                    recipient = _msgSender();
                    // 50% chance of all $BONE stolen
                    _payCatTax(owed);
                    owed = 0;
                }
            }
            delete shelter[tokenId];
            totalPupStaked -= 1;
            // Always remove last to guard against reentrance
            punkedPup.safeTransferFrom(address(this), recipient, tokenId, ""); // send back Pup
            emit TokenUnstaked(tokenId);
        } else {
            _payCatTax((owed * BONE_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked cats
            owed = (owed * (100 - BONE_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Pup owner
            shelter[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit PupClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $BONE earnings for a single Cat and optionally unstake it
     * Cats earn $BONE proportional to their Alpha rank
     * @param tokenId the ID of the Cat to claim earnings from
     * @param unstake whether or not to unstake the Cat
     * @return owed - the amount of $BONE earned
     */
    function _claimCatFromPack(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            punkedPup.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PACK"
        );
        uint8 alpha = _alphaForCat(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (bonePerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Cat to current position
            dogHouse[dogHouseIndices[tokenId]] = dogHouse[dogHouse.length - 1]; // Shuffle last DogCatcher to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            dogHouseIndices[dogHouse[dogHouse.length - 1]] = dogHouseIndices[
                tokenId
            ];
            pack[alpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
            dogHouse.pop(); // Remove duplicate
            delete dogHouseIndices[tokenId]; // Delete old mapping
            // Always remove last to guard against reentrance
            address recipient = _msgSender();
            if (random(tokenId) & 1 == 1) {
                // 50% chance of cat stolen
                recipient = getRandomDogCatcher(random(tokenId));
                if (recipient == address(0x0)) {
                    recipient = _msgSender();
                }
            }
            punkedPup.safeTransferFrom(address(this), recipient, tokenId, ""); // Send back Cat
            emit TokenUnstaked(tokenId);
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(bonePerAlpha)
            }); // reset stake
        }
        emit CatClaimed(tokenId, owed, unstake);
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
        uint256 alpha;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isPup(tokenId)) {
                stake = shelter[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete shelter[tokenId];
                totalPupStaked -= 1;
                punkedPup.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // send back Pup
                emit PupClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForCat(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Cat to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping
                punkedPup.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // Send back Cat
                emit CatClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $BONE to claimable pot for the Pack
     * @param amount $BONE to add to the pot
     */
    function _payCatTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked cats
            unaccountedRewards += amount; // keep track of $BONE due to cats
            return;
        }
        // makes sure to include any unaccounted $BONE
        bonePerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $BONE earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalBoneEarned < MAXIMUM_GLOBAL_BONE) {
            totalBoneEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalPupStaked *
                    DAILY_BONE_RATE) /
                1 days;
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
     * checks if a token is a Pup
     * @param tokenId the ID of the token to check
     * @return pup - whether or not a token is a Pup
     */
    function isPup(uint256 tokenId) public view returns (bool pup) {
        return tokenTraits[tokenId].isPup;
    }

    /**
     * checks if a token is a dog catcher
     * @param tokenId the ID of the token to check
     * @return dogCatcher - whether or not a token is a dog catcher
     */
    function isDogCatcher(uint256 tokenId)
        public
        view
        returns (bool dogCatcher)
    {
        return tokenTraits[tokenId].isDogCatcher;
    }

    /**
     * gets the alpha score for a Cat
     * @param tokenId the ID of the Cat to get the alpha score for
     * @return the alpha score of the Cat (5-8)
     */
    function _alphaForCat(uint256 tokenId) internal view returns (uint8) {
        uint8 alphaIndex = tokenTraits[tokenId].alphaIndex;
        return MAX_ALPHA - alphaIndex; // alpha index is 1-4
    }

    /**
     * set tokenTraits
     * @param tokenIds array of tokenId to set pupcats
     * @param pupcats array of pupcats to set
     */
    function setTokenTraits(
        uint256[] calldata tokenIds,
        PupCat[] calldata pupcats
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenTraits[tokenIds[i]] = pupcats[i];
        }
    }

    /**
     * get tokenTrait
     * @param tokenId tokenId to get pupcats
     */
    function getTokenTraits(uint256 tokenId)
        external
        view
        onlyOwner
        returns (PupCat memory)
    {
        return tokenTraits[tokenId];
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
                        _msgSender(),
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    /**
     * generates a pseudorandom number with range
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function randomWithRange(uint256 seed, uint256 mod)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _msgSender(),
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            ) % mod;
    }

    function getRandomDogCatcher(uint256 seed)
        internal
        view
        returns (address dogCatcher)
    {
        // 50% chance of being stolen
        if (seed % 2 == 0 || dogHouse.length == 0) {
            return address(0x0);
        }
        uint256 tokenId = dogHouse[randomWithRange(seed, dogHouse.length)];
        return stakedDogCatcher[tokenId];
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Shelter directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}
