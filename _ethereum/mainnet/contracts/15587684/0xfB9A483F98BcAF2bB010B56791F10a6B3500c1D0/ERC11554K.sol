// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./IERC1155MetadataURIUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./IGuardians.sol";
import "./IFeesManager.sol";
import "./IERC11554K.sol";
import "./IERC11554KController.sol";
import "./Strings.sol";
import "./GuardianTimeMath.sol";

/**
 * @dev {ERC11554K} token. 4K collections are created as 4K modified ERC1155 contract,
 * which inherits all ERC1155 and ERC2981 functionality and extends it.
 */
contract ERC11554K is
    Initializable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Strings for uint256;

    /// @notice Guardians contract.
    IGuardians public guardians;
    ///@notice fees manager contract
    IFeesManager public feesManager;
    /// @notice IERC11554KController contract.
    IERC11554KController public controller;
    /// @notice 4K collection URI.
    string private _collectionURI;
    /// @notice Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json.
    string private _uri;
    /// @notice Collection Name. Not part of the 1155 standard but still picked up by platforms.
    string public name;
    /// @notice Collection Symbol. Not part of the 1155 standard but still picked up by platforms.
    string public symbol;
    /// @notice this collection is "verified" by 4k itself
    bool public isVerified;
    /// @notice Maximum royalty fee is 7.5%.
    ///@notice maximum royalty fee
    uint256 public constant MAX_ROYALTY_FEE = 750;

    /**
     * @dev Only admin modifier.
     */
    modifier onlyAdmin() {
        require(controller.owner() == _msgSender(), "must be an admin");
        _;
    }

    /**
     * @notice Initialize ERC11554K contract.
     * @param guardians_ address of the guardian contract
     * @param controller_ address of the controller contract
     * @param feesManager_ address of the fees manager contract
     * @param name_ name of the collection
     * @param symbol_ symbol of the collection
     */
    function initialize(
        IGuardians guardians_,
        IERC11554KController controller_,
        IFeesManager feesManager_,
        string memory name_,
        string memory symbol_
    ) external virtual initializer {
        __Ownable_init();
        __ERC1155Supply_init();
        guardians = guardians_;
        feesManager = feesManager_;
        controller = controller_;
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev Mint function for controller contract.
     *
     * Requirements:
     *
     * 1) The caller must be a controller contract.
     * @param mintAddress address to which the token(s) will be minted to
     * @param tokenId token id of the token within the collection that will be minted
     * @param amount amount of token(s) that will be minted
     */
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external virtual {
        require(
            _msgSender() == address(controller),
            "Only callable by controller"
        );
        _mint(mintAddress, tokenId, amount, "0x");
    }

    /**
     * @dev Burn function for controller contract.
     *
     * Requirements:
     *
     * 1) The caller must be a controller contract.
     * @param burnAddress address that will be burnining token(s)
     * @param tokenId token id of the token within the collection that will be burnt
     * @param amount amount of token(s) that will be burnt
     */
    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external virtual {
        require(
            _msgSender() == address(controller),
            "Only callable by controller"
        );
        _burn(burnAddress, tokenId, amount);
    }

    /**
     * @notice Sets guardians contract.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param guardians_ new guardian contract address
     **/
    function setGuardians(IGuardians guardians_) external virtual onlyAdmin {
        guardians = guardians_;
    }

    /**
     * @notice Sets token URI.
     *
     * Requirements:
     *
     * 1) The caller be a contract owner..
     * @param newuri new root uri for the tokens
     **/
    function setURI(string calldata newuri) external virtual onlyAdmin {
        _uri = newuri;
    }

    /**
     * @notice Sets contract-level collection URI.
     *
     * Requirements:
     *
     * 1) The caller be a contract owner.
     * @param collectionURI_ new collection uri for the collection info
     **/
    function setCollectionURI(string calldata collectionURI_)
        external
        virtual
        onlyAdmin
    {
        _collectionURI = collectionURI_;
    }

    /**
     * @notice Sets the verification status of the contract.
     *
     * 2) The caller be a contract owner..
     * @param _isVerified boolean that signifies if this is a verified collection or not.
     */
    function setVerificationStatus(bool _isVerified)
        external
        virtual
        onlyAdmin
    {
        isVerified = _isVerified;
    }

    /**
     * @notice Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * 1) tokenId must be already minted.
     * 2) receiver cannot be the zero address.
     * 3) feeNumerator cannot be greater than the fee denominator.
     * @param tokenId the token id for which the user is setting the royalty
     * @param receiver the address of the entity that will be getting the royalty
     * @param feeNumerator the amount of royalty the receiver will receive. Numerator that generates percentage, over the _feeDenominator()
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external virtual {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * 1) receiver cannot be the zero address.
     * 2) feeNumerator cannot be greater than the fee denominator.
     * @param receiver the address of the entity that will be getting the default royalty
     * @param feeNumerator the amount of royalty the receiver will receive. Numerator that generates percentage, over the _feeDenominator()
     */
    function setGlobalRoyalty(address receiver, uint96 feeNumerator)
        external
        virtual
        onlyAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Opensea contract-level URI standard
     * see https://docs.opensea.io/docs/contract-level-metadata
     * @return URI of the collection
     */
    function contractURI() external view returns (string memory) {
        return _collectionURI;
    }

    /**
     * @notice uri returns the URI for item with id.
     * @param id token id for which the requester will get the URI
     * @return uri URI of the token
     */
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_uri, id.toPaddedHexString(), ".json"));
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     * @param interfaceId interfaceId to query
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Interal wrapper method for ERC2981 _setDefaultRoyalty used by setGlobalRoyalty.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
        internal
        virtual
        override
        onlyAdmin
    {
        require(feeNumerator <= MAX_ROYALTY_FEE, "higher than maximum");
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Interal wrapper method for ERC2981 _setTokenRoyalty used by setTokenRoyalty.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual override {
        require(
            controller.originators(address(this), tokenId) == _msgSender(),
            "Must be originator of token"
        );
        require(feeNumerator <= MAX_ROYALTY_FEE, "higher than maximum");
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev If an item's guardian class charges guardian fees, then the item should have a minimum to transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            // Non-mint non-burn scenario
            if (from != address(0) && to != address(0)) {
                // No need to prevent transfers or shift guardian fees when items are in a free guardian class
                if (
                    guardians.getGuardianFeeRateByCollectionItem(
                        IERC11554K(address(this)),
                        ids[i]
                    ) > 0
                ) {
                    require(
                        guardians.guardianFeePaidUntil(
                            from,
                            address(this),
                            ids[i]
                        ) >= block.timestamp + guardians.minStorageTime(),
                        "Not enough storage time to transfer"
                    );
                    guardians.shiftGuardianFeesOnTokenMove(
                        from,
                        to,
                        ids[i],
                        amounts[i]
                    );
                }
            }
        }
    }
}
