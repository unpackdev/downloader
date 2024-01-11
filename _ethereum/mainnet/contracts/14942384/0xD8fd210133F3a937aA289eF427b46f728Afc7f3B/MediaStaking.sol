// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.2;

import "./NUGGS.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./IERC165.sol";

abstract contract SEASONONEMEDIA is IERC721 {}

contract MediaStaking is Ownable, Pausable {
    using Address for address;
    using Strings for uint256;
    using Strings for bytes32;
    using ECDSA for bytes32;

    struct Stake {
        uint80 value;
        address owner;
    }

    NUGGS private nuggs;
    SEASONONEMEDIA private s1media;

    constructor() {
        address _nuggs = 0x39b037F154524333CbFCB8f193E08607B241A44C;
        address S1MediaAddress = 0xEA3670f81b7ccE94477B214185D9DD49298FE932;
        nuggs = NUGGS(_nuggs);
        s1media = SEASONONEMEDIA(S1MediaAddress);
    }

    event MediaStaked(address owner, uint256 tokenId, uint256 value);
    event MediaClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    bool public stakingIsActive = true;
    mapping(uint256 => Stake) public mediaDeepFryer;
    uint256 public totalMediaStaked;

    uint256 public constant HOURS_MEDIA_RATE = 25 ether;
    uint256 public constant MINIMUM_TO_EXIT = 6 hours;
    uint256 public constant MAXIMUM_GLOBAL_NUGGS = 300000000 ether;
    uint256 public totalNuggsEarned = 0;
    uint256 public promoMultiplier = 1;

    modifier onlyWhenStakingStarted {
        require(stakingIsActive == true, "Staking must be active");
        _;
    }

    function stakeMedia(uint256[] calldata tokenIds) onlyWhenStakingStarted public {
        for (uint i = 0; tokenIds.length > i; i++) {
            require(s1media.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
            _addMediaToDeepFryer(_msgSender(), tokenIds[i]);
        }
    }

    function claimMediaNUGGSRewards(uint16[] calldata tokenIds, bool unstake) public whenNotPaused {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            owed += _claimMediaFromDeepFryer(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        totalNuggsEarned += owed;
        nuggs.mint(_msgSender(), owed);
    }


    function _addMediaToDeepFryer(address account, uint tokenId) internal whenNotPaused {
        require(mediaDeepFryer[tokenId].owner != account, "You already staked this token");
        mediaDeepFryer[tokenId] = Stake({
        owner: account,
        value: uint80(block.timestamp)
        });
        totalMediaStaked += 1;
        emit MediaStaked(account, tokenId, block.timestamp);

    }

    function _claimMediaFromDeepFryer(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = mediaDeepFryer[tokenId];
        require(stake.owner != 0x0000000000000000000000000000000000000000, "Not Staked");
        require(s1media.ownerOf(tokenId) == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "You need 6 hours of Nuggs");
        if (totalNuggsEarned < MAXIMUM_GLOBAL_NUGGS) {
            owed = ((block.timestamp - stake.value) / 6 hours) * HOURS_MEDIA_RATE * promoMultiplier;
        } else {
            owed = 0; // $NUGGS production stopped already
        }

        if (unstake) {
            delete mediaDeepFryer[tokenId];
            totalMediaStaked -= 1;
        } else {
            mediaDeepFryer[tokenId] = Stake({
            owner: _msgSender(),
            value: uint80(block.timestamp)
            });
        }
        emit MediaClaimed(tokenId, owed, unstake);
    }

    function setStakingState(bool stakingState) external onlyOwner {
        stakingIsActive = stakingState;
    }

    function setPromoMultiplier(uint256 newMultiplier) external onlyOwner {
        promoMultiplier = newMultiplier;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

}