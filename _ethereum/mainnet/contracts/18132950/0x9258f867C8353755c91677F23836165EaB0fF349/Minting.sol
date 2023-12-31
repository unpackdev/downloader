// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import necessary OpenZeppelin libraries and contracts
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

// IBBA is an ERC-721 smart contract with additional features
contract IBBA is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {

    // Base URI for token metadata (prefix and suffix)
    string private metadataPrefixURI;
    string private metadataSuffixURI;
    
    // Treasury wallet address for receiving minted NFTs
    address public treasurywallet;

/**
 * @dev Emitted when a new NFT is successfully minted.
 *
 * This event provides information about the minted NFT, including the recipient's treasury wallet address
 * and the unique identifier (ID) of the minted NFT.
 *
 * @param treasuryWallet The address of the treasury wallet to which the NFT is minted.
 * @param nftId The unique identifier (ID) of the minted NFT.
 */
    event MintNFT(address treasuryWallet, uint256 nftId);

/**
 * @dev Emitted when attempting to mint NFTs, and some of the specified token IDs already exist.
 *
 * This event provides information about token IDs that were included in the batch minting
 * request but were already minted prior to the function call.
 *
 * @param alreadyMintedNFTs An array of uint256 values representing the token IDs that already exist.
 */
    event AlreadyMintedNFTs(uint256[] alreadyMintedNFTs);

/**
 * @dev Emitted when a batch of NFTs is successfully minted.
 *
 * This event provides information about the minted NFTs, including the recipient's treasury address
 * and an array of unique identifiers (IDs) of the minted NFTs.
 *
 * @param treasuryAddress The address of the treasury to which the NFTs are minted.
 * @param tokenIds An array of uint256 values representing the unique identifiers (IDs) of the minted NFTs.
 */
    event BatchMinted(
        address indexed treasuryAddress,
        uint256[] tokenIds
    );

/**
 * @dev Emitted when the metadata prefix URI is changed.
 *
 * This event provides information about the new metadata prefix URI.
 *
 * @param newMetadataPrefixURI The updated metadata prefix URI.
 */
    event ChangeMetadataPrefix(string newMetadataPrefixURI);

/**
 * @dev Emitted when the metadata suffix URI is changed.
 *
 * This event provides information about the new metadata suffix URI.
 *
 * @param newMetadataSuffixURI The updated metadata suffix URI.
 */
    event ChangeMetadataSuffix(string newMetadataSuffixURI);

/**
 * @dev Emitted when the treasury wallet address is changed.
 *
 * This event provides information about the new treasury wallet address.
 *
 * @param newTreasuryWallet The updated treasury wallet address.
 */
    event ChangeTreasuryWallet(address newTreasuryWallet);

/**
 * @dev Emitted when ownership of the contract is transferred.
 *
 * This event provides information about the new owner's address.
 *
 * @param newOwner The address of the new owner of the contract.
 */
    event TransferOwnership(address newOwner);


    // Struct to store NFT metadata and burn status
    struct NFTMeta {
        uint256 tokenId;
        string metadata;
        bool isBurnt;
    }

    // Mapping to store NFT metadata by token ID
    mapping(uint256 => NFTMeta) public nftData;

    // Constructor initializes the contract with a treasury wallet address and owner
    constructor(address _treasuryWallet, address _admin) ERC721("Merkletree by IBBA NFTs", "MRKLT") {
        require(_treasuryWallet != address(0),"Treasury wallet can not be empty!");
        treasurywallet = _treasuryWallet;
        _transferOwnership(_admin);
    }

    // Function to change ownership of the contract
    function changeOwnership(address newOwner) external onlyOwner returns (address)  {
        // Ensure the new owner address is not the zero address
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        // Use the built-in function to transfer ownership to the new owner
        _transferOwnership(newOwner);

        // Emit an event to log the ownership transfer
        emit TransferOwnership(newOwner);

        // Return the address of the new owner as confirmation
        return (newOwner);
    }


    // Function to change the treasury wallet address
    function changeTreasuryWallet(address newTreasuryWallet) external onlyOwner returns (address)  {
        // Ensure the new treasury wallet address is not the zero address
        require(newTreasuryWallet != address(0), "Treasuru Address is the zero address");
        
        // Update the treasury wallet address to the new address
        treasurywallet = newTreasuryWallet;

        // Emit an event to log the change of the treasury wallet address
        emit ChangeTreasuryWallet(newTreasuryWallet);

        // Return the new treasury wallet address as confirmation
        return (newTreasuryWallet);
    }

/**
 * @dev Retrieves the metadata prefix URI.
 *
 * This function allows the owner of the contract to access the current metadata
 * prefix URI, which is used to construct the full metadata URI for NFTs.
 *
 * @return The current metadata prefix URI as a string.
 */
    function getMetadataPrefixURI() external onlyOwner view returns (string memory) {
        return metadataPrefixURI;
    }

/**
 * @dev Retrieves the metadata suffix URI.
 *
 * This function allows the owner of the contract to access the current metadata
 * suffix URI, which is used to construct the full metadata URI for NFTs.
 *
 * @return The current metadata suffix URI as a string.
 */
    function getMetadataSuffixURI() external onlyOwner view returns (string memory) {
        return metadataSuffixURI;
    }

/**
 * @dev Pauses contract functionality.
 *
 * This function allows the owner of the contract to pause certain contract
 * functionalities, preventing certain operations from being executed temporarily.
 * It uses the built-in `_pause` function provided by the OpenZeppelin Pausable contract.
 * Once paused, the contract cannot perform specific actions until it is unpaused.
 */
    function pause() external onlyOwner {
        _pause();
    }

/**
 * @dev Unpauses contract functionality.
 *
 * This function allows the owner of the contract to unpause previously paused
 * contract functionalities, allowing them to resume normal operations.
 * It uses the built-in `_unpause` function provided by the OpenZeppelin Pausable contract.
 * After unpausing, the contract can perform actions as usual.
 */
    function unpause() external onlyOwner {
        _unpause();
    }


/**
 * @dev Batch mint NFTs by specifying custom token IDs and associated metadata.
 *
 * This function allows the contract owner to mint a batch of NFTs by specifying custom
 * token IDs provided in the `tokenIds` array. The number of NFTs to mint is determined by
 * the length of the `tokenIds` array. Each NFT is minted to the treasury wallet address,
 * and its metadata is fetched based on the token ID and set accordingly. The minted NFTs'
 * metadata and burn status are stored in the contract's mapping.
 *
 * @param numberOfNFTs The number of NFTs to mint, inferred from the length of `tokenIds`.
 * @param tokenIds An array of custom token IDs for the NFTs.
 * @return tokenId An array containing the custom token IDs of the newly minted NFTs.
 */
    function batchMintingByPassingTokenIds(uint256 numberOfNFTs, uint256[] memory tokenIds) external onlyOwner returns (bool) {
        // Ensure that the number of provided token IDs matches the number of NFTs to mint
        require(tokenIds.length == numberOfNFTs, "The number of Token IDs for NFTs does not match the number of NFTs");

        uint256[] memory tokenIdsAlreaydMinted = new uint256[](tokenIds.length);
        uint256[] memory newlyMintedNFTs = new uint256[](tokenIds.length);
        uint256 numberOfAlreadyMintedNFTs = 0;
        uint256 numberOfNewlyMintedNFTs = 0;
        // Iterate through the specified number of NFTs
        for(uint i = 0; i < numberOfNFTs; i++){
             if (_exists(tokenIds[i])) {
                 tokenIdsAlreaydMinted[numberOfAlreadyMintedNFTs] = tokenIds[i];
                 numberOfAlreadyMintedNFTs++;
             }
             else{
                
                // Mint the NFT with the provided token ID to the treasury wallet
                _safeMint(treasurywallet, tokenIds[i]);

                // Get metadata for the NFT based on the provided token ID
                string memory metaData = tokenURI(tokenIds[i]);

                // Set the metadata of the minted NFT with its token ID
                _setTokenURI(tokenIds[i], metaData);

                // Store NFT metadata in the contract's mapping
                nftData[tokenIds[i]] = NFTMeta(
                    tokenIds[i],
                    metaData,
                    false         
                );

                newlyMintedNFTs[numberOfNewlyMintedNFTs] = tokenIds[i];
                numberOfNewlyMintedNFTs++;

             }

        }

        // Emit the BatchMinted event to log the minting of NFTs
        emit BatchMinted(treasurywallet, newlyMintedNFTs);  
        emit AlreadyMintedNFTs(tokenIdsAlreaydMinted);

        assembly {
            mstore(tokenIdsAlreaydMinted, numberOfAlreadyMintedNFTs)
            mstore(newlyMintedNFTs, numberOfNewlyMintedNFTs)
        }

        // Return status true if function execute properly
        return true;
    }


/**
 * @dev Mint an NFT with a specific token ID and associated metadata.
 *
 * This function allows the contract owner to mint an NFT with a specified token ID and
 * associate it with the provided recipient address. It performs checks to ensure that the
 * specified token ID does not already exist, then mints the NFT, sets its metadata based on
 * the token ID, and stores metadata and burn status in the contract's mapping. The function
 * emits the `MintNFT` event to log the minting.
 *
 * @param tokenId The unique token ID for the NFT.
 * @param to The recipient address to receive the minted NFT.
 * @return The minted token ID, recipient address, and associated metadata.
 */
    function mintingByTokenId(uint256 tokenId, address to) external onlyOwner returns (uint256, address, string memory) {
        // Ensure the specified token ID does not already exist
        if (_exists(tokenId)) revert("Token ID already exists!");
      

        // Emit the MintNFT event to log the minting
        emit MintNFT(to, tokenId);
        // Mint the NFT with the specified token ID to the provided recipient address
        _safeMint(to, tokenId);

        // Get metadata for the NFT based on the token ID
        string memory metaData = tokenURI(tokenId);

        // Set the metadata of the minted NFT with its token ID
        _setTokenURI(tokenId, metaData);

         // Store NFT metadata in the contract's mapping
        nftData[tokenId] = NFTMeta(
            tokenId,
            metaData,
            false         
        );

        // Return the minted token ID, recipient address, and associated metadata
        return (tokenId, to, metaData);
    }


    function updateMetadataURI(uint256 tokenId, string memory metadataUri) external onlyOwner returns(bool){
         // Ensure the token ID exists
        if (!_exists(tokenId)) revert("Token ID does not exist!");
        _setTokenURI(tokenId, metadataUri);

        return true;
    }


/**
 * @dev Modifier to handle token transfers before execution.
 *
 * This internal modifier is used to handle token transfers before the actual transfer
 * is executed. It is called by the OpenZeppelin `ERC721` and `ERC721Enumerable` contracts
 * as part of the transfer process. The modifier checks that the contract is not paused
 * (i.e., its functionality is not temporarily halted) and delegates the transfer handling
 * to the parent contracts for `ERC721` and `ERC721Enumerable`.
 *
 * @param from The address from which the tokens are transferred.
 * @param to The address to which the tokens are transferred.
 * @param tokenId The unique identifier of the token being transferred.
 * @param batchSize The batch size (used for ERC721Enumerable) for multiple token transfers.
 */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


/**
 * @dev Internal function to handle burning of NFTs.
 *
 * This function is used internally to handle the burning (destruction) of NFTs.
 * It overrides the `_burn` function provided by the OpenZeppelin `ERC721` and
 * `ERC721URIStorage` contracts to add custom logic.
 *
 * @param tokenId The unique identifier of the NFT to be burnt.
 */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        
        // Mark the NFT as burnt in the contract's mapping
        nftData[tokenId].isBurnt = true;
    }

    // Function to get the token URI for a given token ID
/**
 * @dev Retrieve the token's metadata URI.
 *
 * This function is used to retrieve the metadata URI associated with a specific token ID.
 * It constructs the full metadata URI by combining the metadata prefix, the token ID
 * converted to a string, and the metadata suffix. The resulting URI points to the location
 * of the token's metadata, which can be used to access information about the token.
 *
 * @param tokenId The unique identifier of the token for which to retrieve the metadata URI.
 * @return The full metadata URI as a string.
 * @notice Reverts if the specified token ID does not exist.
 */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {  
        // Ensure the token ID exists
        if (!_exists(tokenId)) revert("Token ID does not exist!");
        
        // Construct and return the full metadata URI
        string memory uri = concatenateStrings(metadataPrefixURI,Strings.toString(tokenId),metadataSuffixURI);
        return string(uri);
    }

    function concatenateStrings(string memory a, string memory b, string memory c) public pure returns (string memory) {
        bytes memory string1 = bytes(a);
        bytes memory string2 = bytes(b);
        bytes memory string3 = bytes(c);
        
        bytes memory combined = new bytes(string1.length + string2.length + string3.length);

        uint k = 0;
        for (uint i = 0; i < string1.length; i++) {
            combined[k++] = string1[i];
        }

        for (uint i = 0; i < string2.length; i++) {
            combined[k++] = string2[i];
        }

        for (uint i = 0; i < string3.length; i++) {
            combined[k++] = string3[i];
        }

        return string(combined);
    }
/**
 * @dev Change the prefix of the metadata URI.
 *
 * This function allows the contract owner to change the prefix of the metadata URI.
 * The new metadata prefix is specified as `newMetaDataPrefixURI`. After changing
 * the prefix, all newly minted NFTs will use the updated prefix in their metadata URI.
 *
 * @param newMetaDataPrefixURI The new metadata URI prefix to set.
 * @return The updated metadata URI prefix.
 */
    function changeMetaDataPrefixURI(string memory newMetaDataPrefixURI) external onlyOwner returns (string memory) {
        // Update the metadata URI prefix
        metadataPrefixURI = newMetaDataPrefixURI;

        // Emit the ChangeMetadataPrefix event to log the change
        emit ChangeMetadataPrefix(newMetaDataPrefixURI);

        // Return the updated metadata URI prefix
        return metadataPrefixURI;
    }

/**
 * @dev Change the suffix of the metadata URI.
 *
 * This function allows the contract owner to change the suffix of the metadata URI.
 * The new metadata suffix is specified as `newMetadataSuffixURI`. After changing
 * the suffix, all newly minted NFTs will use the updated suffix in their metadata URI.
 *
 * @param newMetadataSuffixURI The new metadata URI suffix to set.
 * @return The updated metadata URI suffix.
 */
    function changeMetaDataSuffixURI(string memory newMetadataSuffixURI) external onlyOwner returns (string memory) {
        // Update the metadata URI suffix
        metadataSuffixURI = newMetadataSuffixURI;

        // Emit the ChangeMetadataSuffix event to log the change
        emit ChangeMetadataSuffix(newMetadataSuffixURI);

        // Return the updated metadata URI suffix
        return metadataSuffixURI;
    }

/**
 * @dev Check if an interface is supported.
 *
 * This function checks whether a specific interface, identified by its `interfaceId`, is
 * supported by the contract. It overrides the `supportsInterface` function provided by
 * the OpenZeppelin `ERC721`, `ERC721Enumerable`, and `ERC721URIStorage` contracts.
 *
 * @param interfaceId The interface identifier to check for support.
 * @return `true` if the interface is supported; otherwise, `false`.
 */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        // Call the parent contract's supportsInterface function and return the result
        return super.supportsInterface(interfaceId);
    }

}
