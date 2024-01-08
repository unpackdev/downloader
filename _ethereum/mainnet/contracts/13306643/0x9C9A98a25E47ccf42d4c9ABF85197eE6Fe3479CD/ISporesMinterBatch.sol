// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
   @title Interface ISporesMinterBatch
   @dev This is an interface to define SporesNFTMinterBatch contract
   The interface includes a feature of minting batch of Spores NFT Tokens
   Please refer to ISporesMinter.sol if you are interested in non-batch minting version
*/
interface ISporesMinterBatch {

    //  Emit when minting a single SporesNFT Token
    event SporesNFTMint(
        address indexed _to,
        address indexed _nft,
        uint256 _id,
        uint256 _amount
    );

    //  Emit when minting a batch of SporesNFT Tokens
    event SporesNFTMintBatch(
        address indexed _to,
        address indexed _nft,
        uint256[] _ids,
        uint256[] _amounts
    );

    /**
       @notice Mint Spores NFT Token (ERC721) to Receiver `to`
       @dev Caller can be ANY
            Only Users of Spores Network are allowed to mint Spores NFT Tokens
            Require a signature from Verifier
       @param _tokenId          Token ID 
       @param _uri              Token URI
       @param _signature        A signature from Verifier
    */
    function mintSporesERC721(
        uint256 _tokenId,
        string calldata _uri,
        bytes calldata _signature
    ) external;

    /**
       @notice Mint batch of Spores NFT Token (ERC721) to Receiver `to`
       @dev Caller can be ANY
            Only Users of Spores Network are allowed to mint Spores NFT Tokens
            Require a signature from Verifier
       @param _tokenIds          Array of Token IDs 
       @param _uris              Array of Token URIs
       @param _signature         A signature from Verifier
    */
    function mintBatchSporesERC721(
        uint256[] calldata _tokenIds,
        string[] calldata _uris,
        bytes calldata _signature
    ) external;

    /**
       @notice Mint Spores NFT Token (ERC1155) to Receiver `to`
       @dev Caller can be ANY
            Only Users of Spores Network are allowed to mint Spores NFT Tokens
            Require a signature from Verifier
       @param _tokenId          Token ID 
       @param _amount           An amount of Spores NFT Tokens being minted
       @param _uri              Token URI
       @param _signature        A signature from Verifier
    */
    function mintSporesERC1155(
        uint256 _tokenId,
        uint256 _amount,
        string calldata _uri,
        bytes calldata _signature
    ) external;

    /**
       @notice Mint batch of Spores NFT Token (ERC1155) to Receiver `to`
       @dev Caller can be ANY
            Only Users of Spores Network are allowed to mint Spores NFT Tokens
            Require a signature from Verifier
       @param _tokenIds          Token ID 
       @param _amounts           An amount of Spores NFT Tokens being minted
       @param _uris              Token URI
       @param _signature         A signature from Verifier
    */
    function mintBatchSporesERC1155(
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        string[] calldata _uris,
        bytes calldata _signature
    ) external;
}
