// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ECDSA.sol";
import "./IERC721Enumerable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

error Quest_Edu_Already_Claimed();
error Quest_Edu_Wrong_Verifier();
error Quest_Edu_Not_Enough_Funds();
error Quest_Edu_Only_Owner();
error Quest_Edu_Not_Ended();
error Quest_Edu_Ended();
error Quest_Edu_Not_Started();

contract Quest {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    uint256 public constant BASE_REWARD = 10 * 10**18;
    uint256 public constant FOUNDERS_BONUS = 50 * 10**18;
    uint256 public constant QUEST_DURATION = 7 days;

    address public immutable owner;
    IERC721Enumerable public immutable foundersNft;
    IERC20 public immutable edu;

    address public verifier;
    uint256 public startDate;

    mapping(address => bool) public hasClaimed;
    mapping(uint256 => bool) public usedFoundersBonus;

    constructor(
        address _owner,
        address _edu,
        address _foundersNft
    ) {
        owner = _owner;
        edu = IERC20(_edu);
        foundersNft = IERC721Enumerable(_foundersNft);
    }

    function start(address _verifier) external {
        if (msg.sender != owner) {
            revert Quest_Edu_Only_Owner();
        }

        verifier = _verifier;
        startDate = block.timestamp;
    }

    function finalizeQuest() external {
        if (msg.sender != owner) {
            revert Quest_Edu_Only_Owner();
        }

        if (startDate + QUEST_DURATION > block.timestamp) {
            revert Quest_Edu_Not_Ended();
        }

        edu.safeTransfer(owner, edu.balanceOf(address(this)));
    }

    function claim(bytes calldata verifierSignature) external {
        if (startDate == 0) {
            revert Quest_Edu_Not_Started();
        }

        if (startDate + QUEST_DURATION < block.timestamp) {
            revert Quest_Edu_Ended();
        }

        if (hasClaimed[msg.sender]) {
            revert Quest_Edu_Already_Claimed();
        }

        bytes32 signedMessage = keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash();
        address verificationSigner = signedMessage.recover(verifierSignature);

        if (verificationSigner != verifier) {
            revert Quest_Edu_Wrong_Verifier();
        }

        uint256 award = BASE_REWARD;
        uint256 numberOfFounderNfts = foundersNft.balanceOf(msg.sender);

        unchecked {
            for (uint16 i = 0; i < numberOfFounderNfts; i++) {
                uint256 tokenId = foundersNft.tokenOfOwnerByIndex(msg.sender, i);
                if (!usedFoundersBonus[tokenId]) {
                    award = award + FOUNDERS_BONUS;

                    usedFoundersBonus[tokenId] = true;
                }
            }
        }

        if (edu.balanceOf(address(this)) < award) {
            revert Quest_Edu_Not_Enough_Funds();
        }

        hasClaimed[msg.sender] = true;

        edu.safeTransfer(msg.sender, award);
    }
}
