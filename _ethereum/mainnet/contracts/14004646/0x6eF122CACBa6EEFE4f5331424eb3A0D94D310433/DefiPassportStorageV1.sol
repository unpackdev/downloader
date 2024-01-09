// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Counters.sol";
import "./ISapphirePassportScores.sol";

/**
 * @title Storage for the DefiPassport
 * @dev The difference between V5 and the original is that anything skins related to the 
 *      original DefiPassport is now hidden from external access.
 */
contract DefiPassportStorageV1 {

    /* ========== Structs ========== */

    struct SkinRecord {
        address owner;
        address skin;
        uint256 skinTokenId;
    }

    struct TokenIdStatus {
        uint256 tokenId;
        bool status;
    }

    struct SkinAndTokenIdStatusRecord {
        address skin;
        TokenIdStatus[] skinTokenIdStatuses;
    }

    // Made these internal because the getters override these variables (because this is an upgrade)
    string internal _name;
    string internal _symbol;

    /**
     * @notice The credit score contract used by the passport
     */
    ISapphirePassportScores private passportScoresContract;

    /* ========== Public Variables ========== */

    /**
     * @notice Records the whitelisted skins. All tokens minted by these contracts
     *         will be considered valid to apply on the passport, given they are
     *         owned by the caller.
     */
    mapping (address => bool) private whitelistedSkins;

    /**
     * @notice Records the approved skins of the passport
     */
    mapping (address => mapping (uint256 => bool)) private approvedSkins;

    /**
     * @notice Records the default skins
     */
    mapping (address => bool) private defaultSkins;

    /**
     * @notice Records the default skins
     */
    SkinRecord private defaultActiveSkin;

    /**
     * @notice The skin manager appointed by the admin, who can
     *         approve and revoke passport skins
     */
    address private skinManager;

    /* ========== Internal Variables ========== */

    /**
     * @notice Maps a passport (tokenId) to its active skin NFT
     */
    mapping (uint256 => SkinRecord) internal _activeSkins;

    Counters.Counter internal _tokenIds;
}
