// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC721ContractMetadata.sol";

import "./INonFungibleSeaDropToken.sol";

import "./ISeaDrop.sol";

import "./SeaDropStructs.sol";

import "./ERC721A.sol";

import "./IERC165.sol";

/**
 * @title  ERC721SeaDrop
 * @author jameswenzel, ryanio, stephankmin
 * @notice ERC721SeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop.
 */
contract ERC721SeaDrop is ERC721ContractMetadata, INonFungibleSeaDropToken {
    /// @notice Track the allowed SeaDrop addresses.
    mapping(address => bool) internal _allowedSeaDrop;

    /// @notice Track the enumerated allowed SeaDrop addresses.
    address[] internal _enumeratedAllowedSeaDrop;

    /**
     * @notice Modifier to restrict access exclusively to
     *         allowed SeaDrop contracts.
     */
    modifier onlyAllowedSeaDrop(address seaDrop) {
        if (_allowedSeaDrop[seaDrop] != true) {
            revert OnlySeaDrop();
        }
        _;
    }

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721ContractMetadata(name, symbol) {
        // Put the length on the stack for more efficient access.
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Set the mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        virtual
        override
        onlyOwner
    {
        _updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {
        // Put the length on the stack for more efficient access.
        uint256 enumeratedAllowedSeaDropLength = _enumeratedAllowedSeaDrop
            .length;
        uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
        for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
            _allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
            unchecked {
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
        for (uint256 i = 0; i < allowedSeaDropLength; ) {
            _allowedSeaDrop[allowedSeaDrop[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Set the enumeration.
        _enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
        emit AllowedSeaDropUpdated(allowedSeaDrop);
    }

    /**
     * @dev Overrides the `_startTokenId` function from ERC721A
     *      to start at token id `1`.
     *
     *      This is to avoid future possible problems since `0` is usually
     *      used to signal values that have not been set or have been removed.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity)
        external
        payable
        override
        onlyAllowedSeaDrop(msg.sender)
    {
        // Mint the quantity of tokens to the minter.
        _mint(minter, quantity);
    }

    /**
     * @notice Update public drop data for this nft contract on SeaDrop.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override onlyOwner {
        // Update the public drop data on SeaDrop.
        ISeaDrop(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update allow list data for this nft contract on SeaDrop.
     *
     *         Note: Only authorized users can call this.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external virtual override onlyOwner {
        // Update the allow list on SeaDrop.
        ISeaDrop(seaDropImpl).updateAllowList(allowListData);
    }

    /**
     * @notice Update token gated drop stage data for this nft contract
     *         on SeaDrop.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing simultaneous
     *         token gated drop promotions for each other, they can be
     *         minted by the same actor until `maxTokenSupplyForStage`
     *         is reached. Please ensure the `allowedNftToken` is not
     *         running an active drop during the `dropStage` time period.
     *
     * @param seaDropImpl     The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external virtual override onlyOwner {
        // Update the token gated drop stage.
        ISeaDrop(seaDropImpl).updateTokenGatedDrop(allowedNftToken, dropStage);
    }

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external
        virtual
        override
        onlyOwner
    {
        // Update the drop URI.
        ISeaDrop(seaDropImpl).updateDropURI(dropURI);
    }

    /**
     * @notice Update the creator payout address for this nft contract on SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external onlyOwner {
        // Update the creator payout address.
        ISeaDrop(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external virtual onlyOwner {
        // Update the allowed fee recipient.
        ISeaDrop(seaDropImpl).updateAllowedFeeRecipient(feeRecipient, allowed);
    }

    /**
     * @notice Update the server-side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can update the signers.
     *
     * @param seaDropImpl                The allowed SeaDrop contract.
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters to
     *                                   enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external virtual override onlyOwner {
        // Update the signer.
        ISeaDrop(seaDropImpl).updateSignedMintValidationParams(
            signer,
            signedMintValidationParams
        );
    }

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    ) external virtual override onlyOwner {
        // Update the signers.
        ISeaDrop(seaDropImpl).updatePayer(payer, allowed);
    }

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @param minter The minter address.
     */
    function getMintStats(address minter)
        external
        view
        override
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        )
    {
        minterNumMinted = _numberMinted(minter);
        currentTotalSupply = totalSupply();
        maxSupply = _maxSupply;
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(INonFungibleSeaDropToken).interfaceId ||
            interfaceId == type(ISeaDropTokenContractMetadata).interfaceId ||
            // ERC721A returns supportsInterface true for
            // ERC165, ERC721, ERC721Metadata
            super.supportsInterface(interfaceId);
    }
}
