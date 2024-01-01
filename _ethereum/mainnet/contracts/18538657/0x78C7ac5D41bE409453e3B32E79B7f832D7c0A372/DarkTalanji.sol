// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Ownable.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

interface IWrapper {
    function transferFromBatch(address from, address to, uint256[] calldata tokenId) external;
}

interface ISoulsLocker {
    function getSoulsInHero(uint256 heroId) external view returns (uint16[] memory);
}

interface IExpManager {
    function creditExperience(uint256 heroId, uint64 expToCredit, uint256 minterIdx) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

interface IERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data, uint256 minterIdx) external;
}

/// @title Dark Talanji
/// @author Mauro
/// @notice Implementation of Dark Talanji - The Spirit Devourer Contract
contract DarkTalanji is Ownable {
    event SpiritsSacrificed(uint256 indexed heroId, uint256[] tokenId, uint256 expCredited);

    // Le Anime v2 tokenId offset (tokenId = editionNr + OFFSETAN2)
    uint256 private constant OFFSETAN2 = 100000;

    // EXP Minter index in the Experience Manager Contract
    uint256 public constant EXP_MINTER_IDX = 0;

    // Editions Minter index in the ERC1155 Contract
    uint256 public constant EDITIONS_MINTER_IDX = 1;

    // SuperRare Original Talanji NFT Contract and ID
    address public constant SUPERRARE = 0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;

    uint256 public constant TALANJI_ID = 17686;

    // New Dark Talanji NFT Contract and ID (toomuchlag 1/1s Contract)
    address public constant TML = 0x0e847aAd9B5b25CEa58613851199484BE3C4Fa13;

    uint256 public constant DARKTALANJI_ID = 4;

    // Number of Spirits sacrificed to unlock the original Talanji
    uint256 public constant OG_UNLOCK_NUM = 2020;

    // Number of Spirits to cap limited edition mint
    uint256 public constant PRIME_SACRIFICE = 250;

    // Le Anime Contracts (Main ERC721, NFT Locker, and Exp Manager, 1155 Editions)
    address public immutable wrapper;
    address public immutable locker;
    address public immutable expManager;
    address public immutable editions;

    // Scores of Le Anime characters stored via SSTORE2
    address public immutable pointerScores;

    // Experience start and end timestamps
    uint64 public immutable expStart;
    uint64 public immutable expEnd;

    bool public sacrificeActive;

    constructor() {
        // mainnet
        wrapper = 0x03BEbcf3D62C1e7465f8a095BFA08a79CA2892A1;
        locker = 0x1eb4490091bd0fFF6c3973623C014D082936EA03;
        expManager = 0x55124b7C32Ab50932725ec6e34bDB53725e2bbd2;
        pointerScores = 0xB6c6De2C865bC497A5CF8A9480Dd2e67504425ae;
        editions = 0xfb0EcD5d5cAD8E498f49000A6CE5423763b039EC;

        expStart = uint64(1651738261); // 5 May 2022
        expEnd = uint64(1735689599); // 31 Dec 2024
    }

    /////////////
    // ADMIN FUNCTIONS
    /////////////

    /// @notice Activate the Sacrifice - owner only
    /// @param activate set true to activate the Sacrifice
    function activateSacrifice(bool activate) external onlyOwner {
        sacrificeActive = activate;
    }

    /// @notice Withdraw the original Talanji - contract owner only + owner of dark talanji - to be renounced and deactivated
    function ownerWithdrawTalanji() external onlyOwner {
        require(IERC721(TML).ownerOf(DARKTALANJI_ID) == msg.sender, "Not the owner of Dark Talanji");

        IERC721(SUPERRARE).transferFrom(address(this), msg.sender, TALANJI_ID);
    }

    /////////////
    // REDEEM TALANJI - DARK TALANJI OWNER ONLY
    /////////////

    /// @notice Redeem the OG SuperRare Talanji. Only if balance of this contract >= threshold (2020 NFTs from the collection)
    function redeemOGTalanji() external {
        require(IERC721(wrapper).balanceOf(address(this)) >= OG_UNLOCK_NUM, "Not unlocked");

        require(IERC721(TML).ownerOf(DARKTALANJI_ID) == msg.sender, "Not the owner of Dark Talanji");

        IERC721(SUPERRARE).transferFrom(address(this), msg.sender, TALANJI_ID);
    }

    /////////////
    // SPIRIT TO EXP FUNCTIONS
    /////////////

    /// @notice Sacrifice Spirits in exchange for EXP in your Hero
    /// @param heroId Hero that will receive EXP
    /// @param tokenId IDs of Spirits to Sacrifice
    function spiritsToExp(uint256 heroId, uint256[] calldata tokenId) external {
        require(sacrificeActive, "Not Active");
        require(ISoulsLocker(locker).getSoulsInHero(heroId).length > 0, "Not a merged Hero");

        // Load on-chain Scores of all 10627 tokenIds
        // each byte is the score of a Soul/Spirits
        // allData[id - 1] is the score of Soul/Spirit #id
        bytes memory allData;

        // address of the contract storing Scores data
        address pointer = pointerScores;

        // efficently load all scores from external storage contract
        // assembly adapted from SSTORE2 code (https://github.com/0xsequence/sstore2)
        assembly {
            // Get the pointer to the free memory and allocate
            allData := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // Allocate enough 32-byte words for the data and the length of the data
            // This is the new "memory end" including padding
            // mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(0x40, add(allData, 10688))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(allData, 10627)

            // Copy the code into memory right after the 32 bytes used to store the size.
            extcodecopy(pointer, add(allData, 32), 1, 10627)
        }

        // total Score of the sacrificed Spirits
        uint256 totalScore;

        // temporary variable to store current token Id
        uint16 currTokenId;

        // compute totalScore of sacrificed spirits
        for (uint256 i = 0; i < tokenId.length; ++i) {
            currTokenId = uint16(tokenId[i] - OFFSETAN2);

            // needs to be a Spirit NFT (tokenId >= 1574)
            require(currTokenId > 1573, "Not a Spirit");

            // check that the NFT is not a Hero - it needs to contain 0 NFTs
            require(ISoulsLocker(locker).getSoulsInHero(currTokenId).length == 0, "Cannot sacrifice a Hero");

            unchecked {
                totalScore += uint8(allData[currTokenId - 1]);
            }
        }

        // calculate the redeemable exp from the sacrifice
        uint64 expToCredit = uint64(calculateRedeemableExp(totalScore));

        // Mint a limited edition for each 10 spirits burned in one go, if balance is < 250
        uint256 totalSacrifice = IERC721(wrapper).balanceOf(address(this));

        // credit the experience to the Hero, via the ExpManager contract
        IExpManager(expManager).creditExperience(heroId, expToCredit, EXP_MINTER_IDX);

        // Transfer and lock all the sacrificed spirits into this contract
        IWrapper(wrapper).transferFromBatch(msg.sender, address(this), tokenId);

        // Mint a limited editions every 10 Spirits if totalSacrifice < 250
        if (totalSacrifice < PRIME_SACRIFICE) {
            uint256 qtyToMint = tokenId.length / 10;
            uint256 remaining = (PRIME_SACRIFICE - totalSacrifice) / 10 + 1;

            if (qtyToMint > 0) {
                if (remaining < qtyToMint) {
                    qtyToMint = remaining;
                }
                IERC1155(editions).mint(msg.sender, 1, qtyToMint, "", EDITIONS_MINTER_IDX);
            }
        }

        emit SpiritsSacrificed(heroId, tokenId, expToCredit);
    }

    /////////////
    // REEDEMABLE EXP CALCULATIONS
    /////////////

    /// @notice Calculate the bonus EXP given a Score
    /// @param score Score of a charachter
    function calculateBonusExp(uint256 score) public pure returns (uint256 bonus) {
        if (score >= 100000) bonus = 50;
        else if (score >= 50000) bonus = 45;
        else if (score >= 25000) bonus = 32;
        else if (score >= 10000) bonus = 25;
        else if (score >= 5000) bonus = 20;
        else if (score >= 2500) bonus = 16;
        else if (score >= 1000) bonus = 13;
        else if (score >= 500) bonus = 10;
        else if (score >= 250) bonus = 8;
        else if (score >= 100) bonus = 6;
        else if (score >= 50) bonus = 4;
        else if (score >= 25) bonus = 2;
        else bonus = 0;
    }

    /// @notice Calculate the EXP currently redeemable by sacrificing Spirits
    /// @param score Total Score of the Spirits sacrificed
    function calculateRedeemableExp(uint256 score) public view returns (uint256 claimableExp) {
        uint256 currentTimestamp = block.timestamp >= expEnd ? expEnd : block.timestamp;

        // Exp is proportional to the Total Score + bonus
        uint256 expMultiplier = score * (100 + calculateBonusExp(score));

        uint256 deltaT = expEnd - currentTimestamp;
        uint256 deltaT2 = expEnd - expStart;
        uint256 deltaT1 = currentTimestamp - expStart;
        uint256 duration = expEnd - expStart;

        return expMultiplier * deltaT - (expMultiplier * (deltaT2 * deltaT2 - deltaT1 * deltaT1)) / (duration * 4);
    }
}
