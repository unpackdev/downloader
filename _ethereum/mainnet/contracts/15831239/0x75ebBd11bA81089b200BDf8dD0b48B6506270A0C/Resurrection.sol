// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721ACommon.sol";
import "./BaseTokenURI.sol";
import "./Address.sol";
import "./Math.sol";

import "./IERC721TransferListener.sol";
import "./Grails2.sol";

/**
 * @title Resurrection
 * @author PROOF
 * @notice This collection contains tokens of Alma Thomas' "Resurrection", which
 * served as inspiration for a grail in season 2.
 * These tokens were airdropped to holders of the respective grails but cannot
 * be transferred (and sold) independently. Instead they are bound to their
 * respective grail counterpart, following them automatically wherever they
 * will be transferred.
 */
contract Resurrection is ERC721ACommon, BaseTokenURI, IERC721TransferListener {
    // =========================================================================
    //                           Errors
    // =========================================================================

    error TransfersDisabled();
    error ApprovalSettingDisabled();
    error InvalidTokenId();
    error IncorrectNumberOfAirdrops();
    error IncorrectGrailId();
    error AirdropOnlyOnce();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The ID of the grail that was derived from
     * "Resurrection" by Alma Thomas.
     */
    uint8 public constant DERIVATIVE_GRAIL_ID = 4;

    /**
     * @notice The address to the grails II contract.
     */
    Grails2 public immutable grails2;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The resurrection token ID (this contract) indexed by the token
     * IDs in the grails contract.
     * @dev The values in this map are shifted by +1 to encode noops as zero,
     * like grail tokens with incorrect grail ID.
     */
    mapping(uint256 => uint256) internal _resurrectionIdByGrailTokenId;

    /**
     * @notice The tokenIDs in the grails contract indexed by resurrection token
     * IDs (this contract).
     * @dev The values in this map are shifted by +1 to encode noops as zero.
     */
    mapping(uint256 => uint256) internal _grailTokenIdByResurrectionId;

    /**
     * @notice Temporary variable to approve the current context to transfer
     * tokens.
     * @dev See also {isApprovedForAll}.
     */
    bool private _tempApproval;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(Grails2 grails2_, string memory baseTokenURI_)
        ERC721ACommon(
            "Resurrection by Alma Thomas",
            "RSRCT",
            payable(address(0xdeadface)),
            0
        )
        BaseTokenURI(baseTokenURI_)
    {
        grails2 = grails2_;
    }

    /**
     * @notice Airdrop resurrection tokens to the respectived derivate grail
     * token holders.
     * @dev Can only be called once.
     * @param grailTokenIds The grail token IDs of the all derivative grails.
     */
    function airdrop(uint256[] calldata grailTokenIds) external {
        if (totalSupply() != 0) {
            revert AirdropOnlyOnce();
        }

        if (
            grailTokenIds.length !=
            grails2.numEditionsByGrailId(DERIVATIVE_GRAIL_ID)
        ) revert IncorrectNumberOfAirdrops();

        // We know that zero is a safe init
        uint256 lastGrailTokenId = 0;

        for (
            uint256 originalId;
            originalId < grailTokenIds.length;
            ++originalId
        ) {
            uint256 grailTokenId = grailTokenIds[originalId];

            if (
                grails2.grailByTokenId(grailTokenId).id != DERIVATIVE_GRAIL_ID
            ) {
                revert IncorrectGrailId();
            }

            // Cheap check to make sure that all supplied grailTokenIds
            // are different and in ascending order.
            if (lastGrailTokenId >= grailTokenId) {
                revert InvalidTokenId();
            }
            lastGrailTokenId = grailTokenId;

            _set(_resurrectionIdByGrailTokenId, grailTokenId, originalId);
            _set(_grailTokenIdByResurrectionId, originalId, grailTokenId);
            _mint(grails2.ownerOf(grailTokenId), 1);
        }
    }

    /**
     * @notice Triggers the transfer of a given resurrection token to the
     * current owner of the respective grail token.
     * @dev This is intended as a fallback solution in case there is a hiccup
     * during setup or with the automated transfers on grail transfer.
     */
    function transfer(uint256 tokenId) public {
        address currentOwner = ownerOf(tokenId);
        address newOwner = grails2.ownerOf(
            grailTokenIdByResurrectionId(tokenId)
        );

        if (newOwner != currentOwner) {
            _approvedTransferFrom(currentOwner, newOwner, tokenId);
        }
    }

    /**
     * @notice Triggers the transfer of a given resurrection token to the
     * owner of the respective grail token.
     * @dev Same as for {transfer}. Reverts if the specified grail tokenId does
     * not correspond to a
     */
    function transferByGrailTokenId(uint256 grailTokenId) public {
        uint256 resurrectionId = resurrectionIdByGrailTokenId(grailTokenId);
        transfer(resurrectionId);
    }

    /**
     * @notice Approves the current context for token transfer and executes it.
     */
    function _approvedTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _tempApproval = true;
        super.transferFrom(from, to, tokenId);
        _tempApproval = false;
    }

    /**
     * @notice Standard ERC721 transfers are disabled for this collection.
     * @dev Instead we transfer them whenever the respective grail token is
     * transferred.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert TransfersDisabled();
    }

    /**
     * @notice Hook that is call when a grail II token is transferred.
     * @dev This triggers the update of the associated resurrection token.
     */
    function onTransfer(
        address,
        address,
        uint256 tokenId
    ) external {
        transferByGrailTokenId(tokenId);
    }

    // =========================================================================
    //                           Approvals
    // =========================================================================

    /**
     * @dev This returns false by default to indicate to marketplaces that this
     * tokens cannot be sold and should therefore not be listed.
     * The return is temporarily overwritten in {_approvedTransferFrom} to
     * allow transfers internally.
     */
    function isApprovedForAll(address, address)
        public
        view
        override
        returns (bool)
    {
        return _tempApproval;
    }

    /**
     * @notice Standard ERC721 approvals are disabled for this collection.
     * @dev This was added to prevent the creation of marketplace listings
     * by failing to approve their contracts.
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert ApprovalSettingDisabled();
    }

    /**
     * @notice Standard ERC721 approvals are disabled for this collection.
     * @dev This was added to prevent the creation of marketplace listings
     * by failing to approve their contracts.
     */
    function approve(address, uint256) public virtual override {
        revert ApprovalSettingDisabled();
    }

    // =========================================================================
    //                           Getters
    // =========================================================================

    /**
     * @notice The resurrection token ID (this contract) indexed by the token
     * IDs in the grails contract.
     * @dev Accounts for the shifted values in the underlying map.
     */
    function resurrectionIdByGrailTokenId(uint256 grailTokenId)
        public
        view
        returns (uint256)
    {
        return _get(_resurrectionIdByGrailTokenId, grailTokenId);
    }

    /**
     * @notice The tokenIDs in the grails contract indexed by resurrection token
     * IDs (this contract).
     * @dev Accounts for the shifted values in the underlying map.
     */
    function grailTokenIdByResurrectionId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _get(_grailTokenIdByResurrectionId, tokenId);
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Getter for a map where values are stored with a +1 shift.
     * @dev The 0 (default) value corresponds to noop. The getter reverts in
     * this case.
     */
    function _get(mapping(uint256 => uint256) storage map, uint256 pos)
        internal
        view
        returns (uint256)
    {
        uint256 val = map[pos];
        if (val == 0) {
            revert InvalidTokenId();
        }
        return val - 1;
    }

    /**
     * @notice Setter for a map where values are stored with a +1 shift.
     */
    function _set(
        mapping(uint256 => uint256) storage map,
        uint256 pos,
        uint256 val
    ) internal {
        map[pos] = val + 1;
    }

    /**
     * @notice Inheritance resolution.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }
}
