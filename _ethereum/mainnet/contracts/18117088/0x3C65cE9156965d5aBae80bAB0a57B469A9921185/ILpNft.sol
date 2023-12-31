// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IERC4906.sol";
import "./IDittoPool.sol";
import "./IDittoPoolFactory.sol";
import "./IMetadataGenerator.sol";
import "./IERC721.sol";

interface ILpNft is IERC4906 {
    // * =============== State Changing Functions ================== *

    /**
     * @notice Allows an administrator to change the DittoPoolFactory contract that interacts with this LP NFT.
     * @param dittoPoolFactory_ The address of a Ditto Pool Factory contract.
     */
    function setDittoPoolFactory(IDittoPoolFactory dittoPoolFactory_) external;

    /**
     * @notice Allows an admin to update the metadata generator through the pool factory.
     * @dev only the Ditto Pool Factory is allowed to call this function
     * @param metadataGenerator_ The address of the metadata generator contract.
     */
    function setMetadataGenerator(IMetadataGenerator metadataGenerator_) external;

    /**
     * @notice Allows the factory to whitelist DittoPool contracts as allowed to mint and burn liquidity position NFTs.
     * @dev only the Ditto Pool Factory is allowed to call this function
     * @param dittoPool_ The address of the DittoPool contract to whitelist.
     * @param nft_ The address of the NFT contract that the DittoPool trades.
     */
    function setApprovedDittoPool(address dittoPool_, IERC721 nft_) external;

    /**
     * @notice mint function used to create new LP Position NFTs 
     * @dev only callable by approved DittoPool contracts
     * @param to_ The address of the user who will own the new NFT.
     * @return lpId The tokenId of the newly minted NFT.
     */
    function mint(address to_) external returns (uint256 lpId);

    /**
     * @notice burn function used to destroy LP Position NFTs
     * @dev only callable approved DittoPool contracts
     * @param lpId_ The tokenId of the NFT to burn.
     */
    function burn(uint256 lpId_) external;

    /**
     * @notice Updates LP position NFT metadata on trades, as LP's LP information changes due to the trade
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @dev only callable by approved DittoPool contracts
     * @param lpId_ the tokenId of the NFT who's metadata needs to be updated
     */
    function emitMetadataUpdate(uint256 lpId_) external;

    /**
     * @notice Tells off-chain actors to update LP position NFT metadata for all tokens in the collection
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @dev only callable by approved DittoPool contracts
     */
    function emitMetadataUpdateForAll() external;

    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *

    /**
     * @notice Tells you whether a given tokenId is allowed to be spent/used by a given spender on behalf of its owner.
     * @dev see EIP-721 approve() and setApprovalForAll() functions
     * @param spender_ The address of the operator/spender to check.
     * @param lpId_ The tokenId of the NFT to check.
     * @return approved Whether the spender is allowed to send or manipulate the NFT.
     */
    function isApproved(address spender_, uint256 lpId_) external view returns (bool);

    /**
     * @notice Check if an address has been approved as a DittoPool on the LpNft contract
     * @param dittoPool_ The address of the DittoPool contract to check.
     * @return approved Whether the DittoPool is approved to mint and burn liquidity position NFTs.
     */
    function isApprovedDittoPool(address dittoPool_) external view returns (bool);

    /**
     * @notice Returns which DittoPool applies to a given LP Position NFT tokenId.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return pool The DittoPool contract that the LP Position NFT is tied to.
     */
    function getPoolForLpId(uint256 lpId_) external view returns (IDittoPool pool);

    /**
     * @notice Returns the DittoPool and liquidity provider's address for a given LP Position NFT tokenId.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return pool The DittoPool contract that the LP Position NFT is tied to.
     * @return owner The owner of the lpId.
     */
    function getPoolAndOwnerForLpId(uint256 lpId_)
        external
        view
        returns (IDittoPool pool, address owner);

    /**
     * @notice Returns the address of the underlying NFT collection traded by the DittoPool corresponding to an LP Position NFT tokenId.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return nft The address of the underlying NFT collection for that LP position
     */
    function getNftForLpId(uint256 lpId_) external view returns (IERC721);

    /**
     * @notice Returns the amount of ERC20 tokens held by a liquidity provider in a given LP Position.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return value the amount of ERC20 tokens held by the liquidity provider in the given LP Position.
     */
    function getLpValueToken(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the list of NFT Ids (of the underlying NFT collection) held by a liquidity provider in a given LP Position.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return nftIds the list of NFT Ids held by the liquidity provider in the given LP Position.
     */
    function getAllHeldNftIds(uint256 lpId_) external view returns (uint256[] memory);

    /**
     * @notice Returns the count of NFTs held by a liquidity provider in a given LP Position.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return nftCount the count of NFTs held by the liquidity provider in the given LP Position.
     */
    function getNumNftsHeld(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the "value" of an LP positions NFT holdings in ERC20 Tokens,
     *   if it were to be sold at the current base price.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return value the "value" of an LP positions NFT holdings in ERC20 Tokens.
     */
    function getLpValueNft(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the "value" of an LP positions total holdings in ERC20s + NFTs,
     *   if all the Nfts in the holdings were sold at the current base price.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return value the "value" of an LP positions sum total holdings in ERC20s + NFTs.
     */
    function getLpValue(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the address of the DittoPoolFactory contract
     * @return factory the address of the DittoPoolFactory contract
     */
    function dittoPoolFactory() external view returns (IDittoPoolFactory);

    /**
     * @notice returns the next tokenId to be minted
     * @dev NFTs are minted sequentially, starting at tokenId 1
     * @return nextId the next tokenId to be minted
     */
    function nextId() external view returns (uint256);

    /**
     * @notice returns the address of the contract that generates the metadata for LP Position NFTs
     * @return metadataGenerator the address of the contract that generates the metadata for LP Position NFTs
     */
    function metadataGenerator() external view returns (IMetadataGenerator);
}
