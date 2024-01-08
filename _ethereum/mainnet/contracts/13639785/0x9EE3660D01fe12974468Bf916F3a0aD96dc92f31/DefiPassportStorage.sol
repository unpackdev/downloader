// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Counters.sol";
import "./ISapphirePassportScores.sol";

contract DefiPassportStorage {

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
    mapping (address => bool) public whitelistedSkins;

    /**
     * @notice Records the approved skins of the passport
     */
    mapping (address => mapping (uint256 => bool)) public approvedSkins;

    /**
     * @notice Records the default skins
     */
    mapping (address => bool) public defaultSkins;

    /**
     * @notice Records the default skins
     */
    SkinRecord public defaultActiveSkin;

    /**
     * @notice The skin manager appointed by the admin, who can
     *         approve and revoke passport skins
     */
    address public skinManager;

    /* ========== Internal Variables ========== */

    /**
     * @notice Maps a passport (tokenId) to its active skin NFT
     */
    mapping (uint256 => SkinRecord) internal _activeSkins;

    Counters.Counter internal _tokenIds;
}
