// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IROOT.sol";
import "./IRNFTV2.sol";
import "./IRNFTStaking.sol";

/// @title ROOT Vesting Contract
/// @notice This contract is used for vesting rootNFT rewards on a monthly basis
/// @author nexusflip

contract RNFTVesting is ReentrancyGuard {
    IROOT public root;
    IRNFTV2 public rnftv2;
    IRNFTStaking public rnftStaking;

    uint32 public cliff;
    uint24 public cliffDuration;
    uint128 public withdrawnTokens;
    uint8 public constant NUMBER_OF_CLIFFS = 6;
    uint80 public constant BENEFICIARY_TOKENS = 2000 ether;

    mapping(uint16 => bool) public isTokenIdVested;
    mapping(address => mapping(uint16 => bool)) public userClaimedIds;
    mapping(address => mapping(uint8 => bool)) public isClaimedUserCliffId;
    mapping(uint16 => uint80) public rootClaimedByTokenId;
    mapping(address => uint80) public userClaimedTokens;

    event TokensReleased(uint16 tokenId, uint80 amount);

    constructor(
        address _root,
        address _rnftv2,
        address _rnftStaking,
        uint32 _cliff,
        uint24 _cliffDuration
    ) {
        root = IROOT(_root);
        rnftv2 = IRNFTV2(_rnftv2);
        rnftStaking = IRNFTStaking(_rnftStaking);
        cliff = _cliff;
        cliffDuration = _cliffDuration;
    }

    function _claimTokens(uint16 _tokenId) internal {
        bool userHasClaimed = userClaimedIds[msg.sender][_tokenId];
        bool tokenIdVested = isTokenIdVested[_tokenId];

        if (!userHasClaimed && !tokenIdVested) {
            userClaimedIds[msg.sender][_tokenId] = true;
            isTokenIdVested[_tokenId] = true;
        }

        if (userClaimedIds[msg.sender][_tokenId] && BENEFICIARY_TOKENS > rootClaimedByTokenId[_tokenId]) {
            uint80 toClaim = uint80(BENEFICIARY_TOKENS / NUMBER_OF_CLIFFS);

            if (block.timestamp - cliffDuration >= cliff) {
                toClaim = BENEFICIARY_TOKENS - rootClaimedByTokenId[_tokenId];
            }
            withdrawnTokens += uint128(toClaim);
            rootClaimedByTokenId[_tokenId] += toClaim;
            userClaimedTokens[msg.sender] += toClaim;

            root.mint(msg.sender, toClaim);
            emit TokensReleased(_tokenId, toClaim);
        }
    }

    function claimUserTokens() external nonReentrant {
        uint256[] memory tokens = rnftv2.getUserTokens(msg.sender);
        uint256[] memory stakedTokens = rnftStaking.stakedTokenIds(msg.sender);

        require(
            block.timestamp >= cliff,
            "Vesting: cliff time not reached"
        );
        uint8 currentCliffId = uint8(((block.timestamp - cliff) * NUMBER_OF_CLIFFS) / (cliffDuration));

        if (currentCliffId > NUMBER_OF_CLIFFS) {
            currentCliffId = NUMBER_OF_CLIFFS;
        }

        for (uint8 i = 0; i < currentCliffId; i++) {
            if (!isClaimedUserCliffId[msg.sender][i]) {
                for (uint16 j = 0; j < uint16(tokens.length); j++) {
                    _claimTokens(uint16(tokens[j]));
                }

                for (uint16 k = 0; k < uint16(stakedTokens.length); k++) {
                    _claimTokens(uint16(stakedTokens[k]));
                }

                isClaimedUserCliffId[msg.sender][i] = true;
            }
        }
    }

    function userClaimable(address user) external view returns (uint128) {
        uint128 total = 0;

        uint256[] memory tokens = rnftv2.getUserTokens(user);
        uint256[] memory stakedTokens = rnftStaking.stakedTokenIds(user);

        for (uint16 i = 0; i < tokens.length; i++) {
            if (userClaimedIds[user][uint16(tokens[i])]) {
                total += uint128(BENEFICIARY_TOKENS - rootClaimedByTokenId[uint16(tokens[i])]);
            }

            if(!userClaimedIds[user][uint16(tokens[i])] && !isTokenIdVested[uint16(tokens[i])]) {
                total += uint128(BENEFICIARY_TOKENS - rootClaimedByTokenId[uint16(tokens[i])]);
            }
        }

        for (uint16 j = 0; j < stakedTokens.length; j++) {
            if (userClaimedIds[user][uint16(stakedTokens[j])]) {
                total += uint128(BENEFICIARY_TOKENS - rootClaimedByTokenId[uint16(stakedTokens[j])]);
            }

            if(!userClaimedIds[user][uint16(stakedTokens[j])] && !isTokenIdVested[uint16(stakedTokens[j])]) {
                total += uint128(BENEFICIARY_TOKENS - rootClaimedByTokenId[uint16(stakedTokens[j])]);
            }
        }

        return total;
    }
}