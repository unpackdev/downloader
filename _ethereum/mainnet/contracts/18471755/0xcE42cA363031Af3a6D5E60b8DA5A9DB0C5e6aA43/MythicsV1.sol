// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {DefaultOperatorFiltererUpgradeable} from
    "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./MythicsBase.sol";
import "./BaseSellableUpgradeable.sol";

import "./Oddsoleum.sol";
import "./MythicsEggRedeemer.sol";
import "./MythicEggSampler.sol";

library MythicsStorage {
    /**
     * @notice Encodes an open choice that the stored user can submit for a given purchase ID.
     * @dev A zero-address as `chooser` indicates that this choice is no longer available.
     * @param chooser the address of the user that is eligible to submit the choice.
     * @param numChoices the number of choices.
     */
    struct OpenChoice {
        address chooser;
        uint8 numChoices;
    }

    /**
     * @notice Encodes a final choice for a given mythics token ID.
     * @param numChoicesMinusOne the number of choices minus one (optimisation).
     * @param choice the choice submitted by the user
     */
    struct FinalChoice {
        uint8 numChoicesMinusOne;
        uint8 choice;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("Mythics.storage.location");

    /**
     * @notice This is the storage layout for the Mythics contract.
     * @dev The fields in this struct MUST NOT be removed, renamed, or reordered. Only additionas are allowed to keep
     * the storage layout compatible between upgrades.
     */
    struct Layout {
        /**
         * @notice The number of tokens that have been minted.
         */
        uint256 numMinted;
        /**
         * @notice The base URI for the token metadata.
         */
        string baseTokenURI;
        /**
         * @notice The number of purchases handled by the seller interface.
         * @dev Counter to get sequential purchaseIDs
         */
        uint64 numPurchases;
        /**
         * @notice The MythicsEggRedeemer contract.
         */
        MythicsEggRedeemer eggRedeemer;
        /**
         * @notice Open choices added on purchase.
         * @dev Elements MUST be deleted after locking in a choice.
         */
        mapping(uint256 purchaseId => OpenChoice) openChoices;
        /**
         * @notice Locked-in choices for the given tokenId.
         * @dev Elements MUST and MUST ONLY be added for minted tokens.
         */
        mapping(uint256 tokenId => FinalChoice) finalChoices;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

interface MythicsV1Events {
    /**
     * @notice Emitted when a Mythic is purchased (not minted) to draw random choices for the buyer off-chain.
     */
    event RandomiseMythics(uint256 indexed purchaseId, address indexed chooser, uint8 indexed numChoices);

    /**
     * @notice Emitted when the Mythics choice was locked in for a given purchase (and the Mythic was minted).
     */
    event MythicChosen(uint256 indexed purchaseId, address indexed chooser, uint256 indexed tokenId, uint8 choice);
}

/**
 * @title Mythics V1
 * @notice Mythics V1 allowing tokens to be purchased by redeeming MythicEgss through the MythicsEggRedeemer or by
 * burning Oddities through the Oddsoleum.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract MythicsV1 is MythicsBase, BaseSellableUpgradeable, DefaultOperatorFiltererUpgradeable, MythicsV1Events {
    /**
     * @notice Thrown if a user attempt to lock in a choice that exceeds the number of available choices.
     */
    error ChoiceOutOfBounds(uint256 purchaseId, uint8 numChoices, uint8 choice);

    /**
     * @notice Thrown if a user attempts to submit a choice for a purchase that was already locked in.
     */
    error PurchaseChoiceAlreadyLockedIn(uint256 purchaseId);

    /**
     * @notice Thrown if the caller attempts to lock in an open choice they are not eligible for.
     */
    error CallerIsNotChooser(uint256 purchaseId, address chooser, address caller);

    struct InitArgsV1 {
        address mainAdmin;
        address secondaryAdmin;
        address steerer;
        string baseTokenURI;
        MythicsEggRedeemer eggRedeemer;
        address royaltyReceiver;
    }

    function initializeV1(InitArgsV1 memory init) public virtual reinitializer(2) {
        __MythicsBase_init();
        __BaseSellable_init();
        __DefaultOperatorFilterer_init();

        _grantRole(DEFAULT_ADMIN_ROLE, init.mainAdmin);
        _grantRole(DEFAULT_ADMIN_ROLE, init.secondaryAdmin);
        _changeAdmin(init.mainAdmin);
        _grantRole(DEFAULT_STEERING_ROLE, init.steerer);

        MythicsStorage.layout().baseTokenURI = init.baseTokenURI;
        MythicsStorage.layout().eggRedeemer = init.eggRedeemer;

        _setDefaultRoyalty(init.royaltyReceiver, 500);
    }

    /**
     * @notice Pauses all ERC721 transfers.
     * @dev This includes mints and hence also purchases throught the Seller interface.
     */
    function pause() public virtual onlyRole(DEFAULT_STEERING_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses paused ERC721 transfers.
     */
    function unpause() public virtual onlyRole(DEFAULT_STEERING_ROLE) {
        _unpause();
    }

    /**
     * @notice Loads and returns the base URI for the token metadata according to the v1 storage layout.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return MythicsStorage.layout().baseTokenURI;
    }

    /**
     * @notice Sets the base tokenURI.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) public virtual onlyRole(DEFAULT_STEERING_ROLE) {
        MythicsStorage.layout().baseTokenURI = newBaseTokenURI;
    }

    /**
     * @notice Returns the total supply of Mythics.
     */
    function totalSupply() public view virtual returns (uint256) {
        return MythicsStorage.layout().numMinted;
    }

    /**
     * @notice Overriding the OZ's minting hook to increment the numMinted counter.
     * @dev Must not be called directly as this would mess with sequential token IDs. Use _mintNextTokenId instead.
     */
    function _mint(address to, uint256 tokenId) internal virtual override {
        unchecked {
            // Impossible to overflow in practice, the amount of gas required to mint more than 2**256 is prohibitive.
            MythicsStorage.layout().numMinted++;
        }
        super._mint(to, tokenId);
    }

    /**
     * @notice Convenience function to mint the next tokenId.
     */
    function _mintNextTokenId(address to) internal virtual returns (uint256) {
        uint256 tokenId = MythicsStorage.layout().numMinted;
        _mint(to, tokenId);
        return tokenId;
    }

    /**
     * @notice Tracks purchases and emits an event to randomise mythic choices off-chain.
     */
    function _trackPurchaseAndRandomiseMythics(address chooser, uint8 numChoices) internal returns (uint256) {
        assert(numChoices > 0);
        MythicsStorage.Layout storage layout = MythicsStorage.layout();
        uint256 purchaseId = layout.numPurchases++;

        // Optimisation: Not tracking the purchase in `openChoices` for `numChoices == 1` since there is only one choice
        // and we will lock it in immediately after this call in `_setChoice` deleting the entry again.
        if (numChoices > 1) {
            layout.openChoices[purchaseId] = MythicsStorage.OpenChoice({chooser: chooser, numChoices: numChoices});
        }
        emit RandomiseMythics(purchaseId, chooser, numChoices);

        return purchaseId;
    }

    /**
     * @notice Locks in a choice for a given purchase and mythic token ID.
     */
    function _setChoice(address chooser, uint256 purchaseId, uint256 tokenId, uint8 numChoices, uint8 choice)
        internal
    {
        assert(numChoices > 0);
        MythicsStorage.Layout storage layout = MythicsStorage.layout();

        if (choice >= numChoices) {
            revert ChoiceOutOfBounds(purchaseId, numChoices, choice);
        }

        if (numChoices > 1) {
            // Optimisation: Not deleting `openChoices` for `numChoices == 1` since we did not store anything in that
            // case. See also `_trackPurchaseAndRandomiseMythics`.
            delete layout.openChoices[purchaseId];
        }

        layout.finalChoices[tokenId] = MythicsStorage.FinalChoice({numChoicesMinusOne: numChoices - 1, choice: choice});
        emit MythicChosen(purchaseId, chooser, tokenId, choice);
    }

    /**
     * @notice Convenience wrapper functions for purchases without choices, i.e. `numChoices = 1`, e.g. used for
     * Oddities and stone eggs.
     */
    function _mintWithoutChoice(address to) internal {
        uint8 numChoices = 1;
        uint256 purchaseId = _trackPurchaseAndRandomiseMythics(to, numChoices);
        uint256 tokenId = _mintNextTokenId(to);
        _setChoice(to, purchaseId, tokenId, numChoices, 0);
    }

    /**
     * @notice Encode as choice submission.
     * @param purchaseId the purchase ID the choice should be submitted for
     * @param choice the chosen Mythic for the given purchase ID
     */
    struct ChoiceSubmission {
        uint256 purchaseId;
        uint8 choice;
    }

    /**
     * @notice Locks in the choice for a given purchase with an open choice and mints the Mythics token.
     * @dev Reverts if the caller is not the stored chooser or if a choice was already submitted for the given purchase.
     */
    function _chooseAndMint(ChoiceSubmission calldata submission) internal {
        MythicsStorage.Layout storage layout = MythicsStorage.layout();
        MythicsStorage.OpenChoice memory openChoice = layout.openChoices[submission.purchaseId];

        if (openChoice.chooser == address(0)) {
            revert PurchaseChoiceAlreadyLockedIn(submission.purchaseId);
        }

        if (msg.sender != openChoice.chooser) {
            revert CallerIsNotChooser(submission.purchaseId, openChoice.chooser, msg.sender);
        }

        uint8 numChoices = openChoice.numChoices;
        uint256 tokenId = _mintNextTokenId(msg.sender);
        _setChoice(msg.sender, submission.purchaseId, tokenId, numChoices, submission.choice);
    }

    /**
     * @notice Locks in choices for given purchases and mints the Mythics tokens.
     */
    function chooseAndMint(ChoiceSubmission[] calldata choices) public whenNotPaused {
        for (uint256 i; i < choices.length; ++i) {
            _chooseAndMint(choices[i]);
        }
    }

    /**
     * @inheritdoc BaseSellableUpgradeable
     * @dev Mints Mythics tokens for standard sales (e.g. through the Oddsoleum) or stone egg redemptions or records
     * open choices for non-stone eggs.
     */
    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual override whenNotPaused {
        if (msg.sender != address(MythicsStorage.layout().eggRedeemer)) {
            for (uint256 i; i < num; ++i) {
                _mintWithoutChoice(to);
            }
            return;
        }

        MythicsEggRedemptionLib.PurchasePayload[] memory payloads = MythicsEggRedemptionLib.decode(data);
        assert(num == payloads.length);

        for (uint256 i; i < num; ++i) {
            MythicEggSampler.EggType eggType = payloads[i].eggType;

            if (eggType == MythicEggSampler.EggType.Stone) {
                _mintWithoutChoice(to);
                continue;
            }

            assert(uint8(eggType) <= 2);
            uint8 numChoices = uint8(eggType) + 1;
            _trackPurchaseAndRandomiseMythics(to, numChoices);
        }
    }

    /**
     * @notice Sets the egg redeemer contract.
     */
    function setEggRedeemer(MythicsEggRedeemer newRedeemer) public onlyRole(DEFAULT_STEERING_ROLE) {
        MythicsStorage.layout().eggRedeemer = newRedeemer;
    }

    /**
     * @notice Returns the egg redeemer contract.
     */
    function eggRedeemer() public view returns (MythicsEggRedeemer) {
        return MythicsStorage.layout().eggRedeemer;
    }

    /**
     * @notice Sets the default royalty receiver and fee in basis points.
     */
    function setDefaultRoyalty(address receiver, uint96 feeBasisPoints)
        public
        virtual
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(MythicsBase, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return MythicsBase.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
