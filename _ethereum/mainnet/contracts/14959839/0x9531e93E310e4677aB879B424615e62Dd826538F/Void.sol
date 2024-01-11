// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";

import "./ERC721A.sol";

import "./Voidish.sol";

/**************************************************************
 * Journey to the void, and cast yourself in.
 * You may find you gain Something you didn't possess before.
 *************************************************************/

contract Void is Voidish, Ownable, ReentrancyGuard {
    event EnteredVoid(uint256 indexed tokenId, address indexed renouncer);
    event ExitedVoid(uint256 indexed tokenId, address indexed renouncer);

    struct Vanishing {
        address renouncer;
        uint64 disappearance;
    }

    IERC721A public nothings;
    uint256 constant public epoch = 72 hours;
    mapping(uint256 => bool) public voided;
    mapping(uint256 => Vanishing) public vanished;

    constructor(address _nothings) {
        nothings = IERC721A(_nothings);
    }

    /**
     * Your time will soon be near, where we shall no longer return.
     * There, demands of strength will be forthright and none will be the wiser to your transgressions.
     * Despite your intentions, the deed has been done.
     * Renew yourself, and find me amongst the Nothings.
     */

    function enterTheVoid(uint256[] calldata tokenIds) external nonReentrant {
        require(msg.sender == tx.origin, "must be someone");
        require(nothings.isApprovedForAll(msg.sender, address(this)), "permit yourself to let go");

        uint256 count = tokenIds.length;
        for (uint256 idx; idx < count; ++idx) {
            _castIntoTheVoid(tokenIds[idx]);
        }
    }

    /**
     * This domain is full of torment, in it, verifiably Nothing.
     * But, there is much left to discover; a beauty unlike anything your mind can imagine.
     * Perhaps a bounty.
     * Perhaps Nothing.
     */

    function exitTheVoid(uint256[] calldata tokenIds) external nonReentrant {
        require(msg.sender == tx.origin, "must be someone");

        uint256 count = tokenIds.length;
        for (uint256 idx; idx < count; ++idx) {
            _summonFromTheVoid(tokenIds[idx]);
        }
    }

    function isWithinTheVoid(uint256 tokenId) external view returns (bool) {
        return vanished[tokenId].disappearance > 0;
    }

    /**
     * What do you seek from me?
     * You know nothing of me, yet stick to me.
     * I hold no secrets, I give no secrets.
     * You cannot embark on a journey alone nor leave without a Key.
     * Alas, much of what you have learned has been concealed from you.
     * A superficial understanding breeds arrogance; true understanding breeds fear.
     */

    function hasBecomeSomething(uint256 tokenId) external view returns (bool) {
        if (voided[tokenId]) {
            return true;
        }

        Vanishing storage vanishing = vanished[tokenId];
        if (vanishing.disappearance == 0) {
            return false;
        }

        return block.timestamp - uint256(vanishing.disappearance) >= epoch;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _castIntoTheVoid(uint256 tokenId) internal {
        nothings.safeTransferFrom(msg.sender, address(this), tokenId);
        vanished[tokenId] = Vanishing({
            renouncer: msg.sender,
            disappearance: uint64(block.timestamp)
        });

        emit EnteredVoid(tokenId, msg.sender);
    }

    function _summonFromTheVoid(uint256 tokenId) internal {
        Vanishing storage vanishing = vanished[tokenId];
        require(vanishing.renouncer == msg.sender, "you cannot recover what you did not first lose");

        if (block.timestamp - uint256(vanishing.disappearance) >= epoch) {
            voided[tokenId] = true;
        }

        nothings.safeTransferFrom(address(this), msg.sender, tokenId);
        delete vanished[tokenId];

        emit ExitedVoid(tokenId, msg.sender);
    }
}
