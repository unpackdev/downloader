// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC721.sol";

/**
 * @title Interface for optional business additions for ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *
 * Interface Id = 0x4a851dfe
 */
interface IERC721BusinessAdditions is IERC721 {
    /**
     * @dev Emitted when `_companyName` is updated from `from` to `to`.
     */
    event UpdatedCompanyName(string indexed from, string indexed to);

    /**
     * @dev Emitted when `_contractURI` is updated from `from` to `to`.
     */
    event UpdatedContractURI(string indexed from, string indexed to);

    /**
     * @dev Updates the `_companyName` for the collection.  Implementation may
     * include access restrictions such as those found in Ownable or AccessControl.
     */
    function updateCompanyName(string memory companyName_) external;

    /**
     * @dev Updates the `_contractURI` for the collection.  Implementation may
     * include access restrictions such as those found in Ownable or AccessControl.
     */
    function updateContractURI(string memory contractURI_) external;

    /**
     * @dev Returns the contract-wide URI.  Used by some third-party marketplaces
     * to provide collection information.
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Returns the name of the company/entity associated with the contract
     */
    function companyName() external view returns (string memory);

    /**
     * @dev Returns the token serial number.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenSerialNumber(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the token terms and conditions URI
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenTermsConditionsURI(uint256 tokenId) external view returns (string memory);
}
