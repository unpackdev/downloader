// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.1;

import "./NUGGS.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./IERC165.sol";

abstract contract EWALKS is IERC721 {}
abstract contract NERDYNUGGETS is IERC721 {}

contract DeepFryer is Ownable, Pausable {
    using Address for address;
    using Strings for uint256;
    using Strings for bytes32;
    using ECDSA for bytes32;

    struct Stake {
        uint16 kills;
        uint80 value;
        address owner;
    }

    NUGGS private nuggs;
    EWALKS private ewalk;
    NERDYNUGGETS private nerdyNuggets;

    constructor() {
        address _nuggs = 0x39b037F154524333CbFCB8f193E08607B241A44C;
        address EwalksAddress = 0x4691b302c37B53c68093f1F5490711d3B0CD2b9C;
        address NerdyNuggetsAddress = 0xb45F2ba6b25b8f326f0562905338b3Aa00D07640;
        nuggs = NUGGS(_nuggs);
        ewalk = EWALKS(EwalksAddress);
        nerdyNuggets = NERDYNUGGETS(NerdyNuggetsAddress);
    }

    event TokenStaked(address owner, uint256 kills, uint256 tokenId, uint256 value);
    event NuggetStaked(address owner, uint256 tokenId, uint256 value);
    event ZombiesClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event HumansClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event NuggetsClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    bool public stakingIsActive = true;
    address public dataSigner = 0x7A513630e4826Ad0356a5a9031923444F5C0212D;
    mapping(uint256 => Stake) public zombieDeepFryer;
    mapping(uint256 => Stake) public humanDeepFryer;
    mapping(uint256 => Stake) public nuggetDeepFryer;
    uint256 public totalZombiesStaked;
    uint256 public totalHumansStaked;
    uint256 public totalNuggetsStaked;

    uint256 public constant HOURS_NUGGS_RATE = 25 ether;
    uint256 public constant HOURS_NUGGETS_RATE = 30 ether;
    uint256 public constant MINIMUM_TO_EXIT = 6 hours;
    uint256 public constant MAXIMUM_GLOBAL_NUGGS = 600000000 ether;
    uint256 public totalNuggsEarned = 0;
    uint256 public promoMultiplier = 1;
    uint256 public humanMultiplier = 10; // Will be less after S2 launch
    uint256 public humanReduction = 1;

    modifier onlyWhenStakingStarted {
        require(dataSigner != address(0), "Staking is not available yet");
        require(stakingIsActive == true, "Staking must be active");
        _;
    }

    function stakeZombies(uint256[] calldata tokenIds, uint256[] calldata killCounts, bytes[] calldata killSignatures) onlyWhenStakingStarted public {
        require(killCounts.length == killSignatures.length);
        require(tokenIds.length == killSignatures.length);
        for (uint i = 0; killCounts.length > i; i++) {
            uint k = (killCounts[i] * 10000 + tokenIds[i]) * 10 + 1;
            bytes32 userhash = keccak256(abi.encodePacked(k));
            require(userhash.toEthSignedMessageHash().recover(killSignatures[i]) == dataSigner, "Invalid Signature");
            require(ewalk.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
            _addZombieToDeepFryer(_msgSender(), tokenIds[i], killCounts[i]);
        }
    }

    function stakeHumans(uint256[] calldata tokenIds, uint256[] calldata killCounts, bytes[] calldata killSignatures) onlyWhenStakingStarted public {
        require(killCounts.length == killSignatures.length);
        require(tokenIds.length == killSignatures.length);
        for (uint i = 0; killSignatures.length > i; i++) {
            uint k = (killCounts[i] * 10000 + tokenIds[i]) * 10;
            bytes32 userhash = keccak256(abi.encodePacked(k));
            require(userhash.toEthSignedMessageHash().recover(killSignatures[i]) == dataSigner, "Invalid Signature");
            require(ewalk.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
            _addHumanToDeepFryer(_msgSender(), tokenIds[i]);
        }
    }

    function stakeNugget(uint256[] calldata tokenIds) onlyWhenStakingStarted public {
        for (uint i = 0; tokenIds.length > i; i++) {
            require(nerdyNuggets.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
            _addNuggetToDeepFryer(_msgSender(), tokenIds[i]);
        }
    }

    function claimZombieNUGGSRewards(uint16[] calldata tokenIds, bool unstake) public whenNotPaused {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _claimZombiesFromDeepFryer(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        totalNuggsEarned += owed;
        nuggs.mint(_msgSender(), owed);
    }

    function claimHumanNUGGSRewards(uint16[] calldata tokenIds, bool unstake) public whenNotPaused {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _claimHumansFromDeepFryer(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        totalNuggsEarned += owed;
        nuggs.mint(_msgSender(), owed);
    }

    function claimNerdyNuggetsNUGGSRewards(uint16[] calldata tokenIds, bool unstake) public whenNotPaused {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _claimNuggetsFromDeepFryer(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        totalNuggsEarned += owed;
        nuggs.mint(_msgSender(), owed);
    }

    function _addZombieToDeepFryer(address account, uint tokenId, uint kills) internal whenNotPaused {
        require(zombieDeepFryer[tokenId].owner != account, "You already staked this token");
        zombieDeepFryer[tokenId] = Stake({
        owner: account,
        kills: uint16(kills),
        value: uint80(block.timestamp)
        });
        totalZombiesStaked += 1;
        emit TokenStaked(account, kills, tokenId, block.timestamp);

    }

    function _addHumanToDeepFryer(address account, uint tokenId) internal whenNotPaused {
        require(humanDeepFryer[tokenId].owner != account, "You already staked this token");
        humanDeepFryer[tokenId] = Stake({
        owner: account,
        kills: 0,
        value: uint80(block.timestamp)
        });
        totalHumansStaked += 1;
        emit TokenStaked(account, 0, tokenId, block.timestamp);

    }

    function _addNuggetToDeepFryer(address account, uint tokenId) internal whenNotPaused {
        require(nuggetDeepFryer[tokenId].owner != account, "You already staked this token");
        nuggetDeepFryer[tokenId] = Stake({
        owner: account,
        kills: 0,
        value: uint80(block.timestamp)
        });
        totalNuggetsStaked += 1;
        emit NuggetStaked(account, tokenId, block.timestamp);

    }

    function _claimZombiesFromDeepFryer(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = zombieDeepFryer[tokenId];
        require(stake.owner != 0x0000000000000000000000000000000000000000, "Not Staked");
        require(ewalk.ownerOf(tokenId) == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "You need 6 hours of Nuggs");
        if (totalNuggsEarned < MAXIMUM_GLOBAL_NUGGS) {
            owed = ((block.timestamp - stake.value) / 6 hours) * (HOURS_NUGGS_RATE + (stake.kills * 1 ether)) * promoMultiplier;
        } else {
            owed = 0; // $NUGGS production stopped already
        }

        if (unstake) {
            delete zombieDeepFryer[tokenId];
            totalZombiesStaked -= 1;
        } else {
            zombieDeepFryer[tokenId] = Stake({
            owner: _msgSender(),
            kills: uint16(stake.kills),
            value: uint80(block.timestamp)
            });
        }
        emit ZombiesClaimed(tokenId, owed, unstake);
    }

    function _claimHumansFromDeepFryer(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = humanDeepFryer[tokenId];
        require(stake.owner != 0x0000000000000000000000000000000000000000, "Not Staked");
        require(ewalk.ownerOf(tokenId) == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "You need 12 hours of Nuggs");
        if (totalNuggsEarned < MAXIMUM_GLOBAL_NUGGS) {
            owed = (((block.timestamp - stake.value) / 6 hours) * HOURS_NUGGS_RATE * humanMultiplier) / humanReduction;
        } else {
            owed = 0; // $NUGGS production stopped already
        }

        if (unstake) {
            delete humanDeepFryer[tokenId];
            totalHumansStaked -= 1;
        } else {
            humanDeepFryer[tokenId] = Stake({
            owner: _msgSender(),
            kills: 0,
            value: uint80(block.timestamp)
            });
        }
        emit HumansClaimed(tokenId, owed, unstake);
    }

    function _claimNuggetsFromDeepFryer(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = nuggetDeepFryer[tokenId];
        require(stake.owner != 0x0000000000000000000000000000000000000000, "Not Staked");
        require(nerdyNuggets.ownerOf(tokenId) == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "You need 12 hours of Nuggs");
        if (totalNuggsEarned < MAXIMUM_GLOBAL_NUGGS) {
            owed = ((block.timestamp - stake.value) / 6 hours) * HOURS_NUGGETS_RATE * promoMultiplier;
        } else {
            owed = 0; // $NUGGS production stopped already
        }

        if (unstake) {
            delete nuggetDeepFryer[tokenId];
            totalNuggetsStaked -= 1;
        } else {
            nuggetDeepFryer[tokenId] = Stake({
            owner: _msgSender(),
            kills: 0,
            value: uint80(block.timestamp)
            });
        }
        emit NuggetsClaimed(tokenId, owed, unstake);
    }

    function setDataSigner(address newDataSigner) external onlyOwner {
        dataSigner = newDataSigner;
    }

    function setStakingState(bool stakingState) external onlyOwner {
        stakingIsActive = stakingState;
    }

    function setHumanMultiplier(uint256 newMultiplier) external onlyOwner {
        humanMultiplier = newMultiplier;
    }

    function setPromoMultiplier(uint256 newMultiplier) external onlyOwner {
        promoMultiplier = newMultiplier;
    }

    function setHumanReduction(uint256 newValue) external onlyOwner {
        humanReduction = newValue;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

}