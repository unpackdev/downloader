// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721MetadataUpgradable.sol";
import "./IERC2309.sol";

/**
 * @dev Interface of the BootlegNFT
 */
interface IBootlegNFT is IERC2309, IERC721MetadataUpgradeable {

    /**
     * @dev Mints new Bootleg NFT from the original NFT (found by the contractAddress and originalTokenId parameters)
     *
     * Requirements:
     *
     * - `originalContractAddress` the address of the contract for the original NFT
     * - `originalTokenId` the id of the original NFT
     * - `chainId` the chain id from where the token can be obtained from
     *
     * Emits a {Transfer} event.
     */
    function mint(address originalContractAddress, uint256 originalTokenId, uint256 chainId) external returns (uint256 tokenId);


    /**
    * @dev Mints multiple new Bootleg NFTs from the original NFTs (found by the contractAddresses and originalTokenIds parameters)
     *
     * Requirements:
     *
     * - `originalContractAddresses` the addresses of the contracts for the original NFTs
     * - `originalTokenIds` the ids of the original NFTs
     * - `originalContractAddresses` and `originalTokenIds` must be of the same length
     * - `contractAddresses` and `originalTokenIds` can't have length > numCopiesBatch
     * - `chainId` the chain id from where the token can be obtained from
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function mintBatch(address[] memory originalContractAddresses, uint256[] memory originalTokenIds, uint256 chainId) external;

    /**
     * @dev Returns the Bootleg token information by id
     *
     * Requirements:
     *
     * - `tokenId` the id of the token
     */
    function getTokenInfo(uint256 tokenId) external view returns (address owner, address originalContractAddress, uint256 originalTokenId, uint256 chainId);

    /**
     * @dev Returns the current minting price.
     *
     */
    function getMintingPrice() external view returns (uint256 mintingPrice);


    /**
     * @dev Returns the initial minting fee.
     */
    function getInitialMintingFee() external view returns (uint256 initialMintingFee);


    /**
     * @dev Returns the number of minted copies for particular original token (identified by `contractAddress` and `originalTokenId`)
     *
     * Requirements:
     *
     * - `originalContractAddress` the id of the token
     * - `originalTokenId` the id of the token
     */
    function getMintedCopiesAmount(address originalContractAddress, uint256 originalTokenId) external view returns (uint256 copiesMinted);

}