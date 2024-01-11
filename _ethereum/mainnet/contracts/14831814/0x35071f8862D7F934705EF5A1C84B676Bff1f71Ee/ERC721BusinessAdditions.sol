// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC721.sol";
import "./IERC721BusinessAdditions.sol";


/**
 * @title Optional business additions for ERC-721 Non-Fungible Token Standard
 * @author Ryan Farley <ryan@artmtoken.com>
 * @dev This implements an optional extension of {ERC721} that adds on-chain storage
 * for critical business related metadata.  This contract was designed to be inherited
 * by a child contract that can implement access controls & the necessary logic to
 * secure _setTokenSerialNumber() & _setTokenTermsConditionsURI() as desired.  This can
 * be accomplished by calling them after _mint() or in a custom function.
 *
 * Useful for scenarios where a company desires an ERC721 token contract that can store:
 * - Collection-wide URI for use in third-party marketplaces
 * - Name of the company/entity associated with the contract
 * - Unique serial numbers for each token Id (i.e. physical merch tie-in)
 * - Terms and Conditions for each individual token Id
 */
abstract contract ERC721BusinessAdditions is ERC721, IERC721BusinessAdditions {
    // Contract-wide URI
    string private _contractURI;

    // Company/entity name associated with the contract
    string private _companyName;

    // Mapping from token ID to serial number
    mapping(uint256 => string) private _tokenSerialNumbers;

    // Mapping from token ID to terms and conditions URI
    mapping(uint256 => string) private _tokenTermsConditionsURI;

    /**
     * @dev Initializes the contract by setting a `contractURI` for the token collection.
     */
    constructor(string memory contractURI_) {
        // Set initial _contractURI value
        _contractURI = contractURI_;
    }

    /**
     * @dev See {IERC721BusinessAdditions-updateContractURI}.
     */
    function updateContractURI(string memory newContractURI) external virtual override {
        string memory originalContractURI = _contractURI;

        require(_updateBusinessAdditionsAccess(), "ERC721BusinessAdditions: must have permission to update");

        _contractURI = newContractURI;

        emit UpdatedContractURI(originalContractURI, _contractURI);
    }

    /**
     * @dev See {IERC721BusinessAdditions-updateCompanyName}.
     */
    function updateCompanyName(string memory newCompanyName) external virtual override {
        string memory originalCompanyName = _companyName;

        require(_updateBusinessAdditionsAccess(), "ERC721BusinessAdditions: must have permission to update");

        _companyName = newCompanyName;

        emit UpdatedCompanyName(originalCompanyName, _companyName);
    }

    /**
     * @dev See {IERC721BusinessAdditions-tokenSerialNumber}.
     */
    function tokenSerialNumber(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721BusinessAdditions: nonexistent token");

        return _tokenSerialNumbers[tokenId];
    }

    /**
     * @dev See {IERC721BusinessAdditions-tokenTermsConditionsURI}.
     */
    function tokenTermsConditionsURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721BusinessAdditions: nonexistent token");

        return _tokenTermsConditionsURI[tokenId];
    }

    /**
     * @dev See {IERC721BusinessAdditions-contractURI}.
     */
    function contractURI() external view virtual override returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev See {IERC721BusinessAdditions-companyName}.
     */
    function companyName() external view virtual override returns (string memory) {
        return _companyName;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721BusinessAdditions).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets `_tokenSerialNumber` as the serial number of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenSerialNumber(uint256 tokenId, string memory _tokenSerialNumber) internal virtual {
        require(_exists(tokenId), "ERC721BusinessAdditions: nonexistent token");
        _tokenSerialNumbers[tokenId] = _tokenSerialNumber;
    }

    /**
     * @dev Sets `_tokenTermsConditionURI` as the terms and conditions of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenTermsConditionsURI(uint256 tokenId, string memory _tokenTermsConditionURI) internal virtual {
        require(_exists(tokenId), "ERC721BusinessAdditions: nonexistent token");
        _tokenTermsConditionsURI[tokenId] = _tokenTermsConditionURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        if (bytes(_tokenSerialNumbers[tokenId]).length != 0) {
            delete _tokenSerialNumbers[tokenId];
        }

        if (bytes(_tokenTermsConditionsURI[tokenId]).length != 0) {
            delete _tokenTermsConditionsURI[tokenId];
        }

        super._burn(tokenId);
    }

    /**
     * @dev Hook to allow adding access control constraints in child contract.
     *
     * NOTE: This function must be overridden in the child contract to return a
     * true value. This function secures updateContractURI() and updateCompanyName().
     * Returns false by default.
     *
     */
    function _updateBusinessAdditionsAccess() internal virtual returns(bool) {
        return false;
    }
}
