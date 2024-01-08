// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ISporesMinterBatch.sol";
import "./IERC1155Mintable.sol";
import "./IERC721Mintable.sol";
import "./SporesRegistry.sol";
import "./Signature.sol";

/**
   @title SporesNFTMinterBatch contract
   @dev This contract is used to handle minting Spores NFT Tokens. There are two supporting NFT standards:
      + ERC-721 (https://eips.ethereum.org/EIPS/eip-721)
      + ERC-1155 (https://eips.ethereum.org/EIPS/eip-1155)
   This contract uses an interface ISporesMinterBatch.sol which supports batch minting
   Please refert to SporesNFTMinter.sol if you are interested in a non-batch minting version
*/
contract SporesNFTMinterBatch is ISporesMinterBatch, Ownable {
    using Signature for Signature.MintType;

    //  Minter version
    bytes32 public constant VERSION = keccak256("MINTER_BATCH_v1");

    // Define Single Unit of NFT721
    uint256 private constant SINGLE_UNIT = 1;

    // SporesRegistry contract
    SporesRegistry public registry;

    /**
       @notice Initialize SporesRegistry contract 
       @param _registry        Address of SporesRegistry contract
    */
    constructor(address _registry) Ownable() {
        registry = SporesRegistry(_registry);
    }

    /**
       @notice Update new address of SporesRegistry contract
       @dev Caller must be Owner
           SporesRegistry contract is upgradeable smart contract
           Thus, the address remains unchanged in upgrading
           However, this functions is a back up in the worse case 
           that requires to deploy a new SporesRegistry contract
       @param _newRegistry          Address of new SporesRegistry contract
    */
    function updateRegistry(address _newRegistry) external onlyOwner {
        require(
            _newRegistry != address(0),
            "SporesNFTMinterBatch: Set zero address"
        );
        registry = SporesRegistry(_newRegistry);
    }

    /**
       @notice Mint Spores NFT Token (ERC721) to Receiver `msg.sender`
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
    ) external override {
        // verify `_signature` to authorize caller to mint `_tokenId`
        registry.checkAuthorization(
            Signature.MintType.ERC721_MINTING.getSingleMintingSignature(
                _msgSender(),
                _tokenId,
                _uri,
                _signature
            ),
            keccak256(_signature)
        );

        IERC721Mintable(registry.erc721()).mint(_msgSender(), _tokenId, _uri);

        emit SporesNFTMint(
            _msgSender(),
            registry.erc721(),
            _tokenId,
            SINGLE_UNIT
        );
    }

    /**
       @notice Mint batch of Spores NFT Token (ERC721) to Receiver `msg.sender`
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
    ) external override {
        //  If length of `_tokenIds` and `_uris` are not matched
        //  revert with error
        uint256 _size = _tokenIds.length;
        require(
            _size == _uris.length,
            "SporesNFTMinterBatch: Size not matched"
        );

        // verify `_signature` to authorize caller to batch mint `_tokenIds`
        registry.checkAuthorization(
            Signature.MintType.ERC721_MINTING.getBatchMintingSignature(
                _msgSender(),
                _tokenIds,
                _uris,
                _signature
            ),
            keccak256(_signature)
        );

        IERC721Mintable _erc721 = IERC721Mintable(registry.erc721());
        uint256[] memory _amounts = new uint256[](_size);
        for (uint256 i; i < _size; i++) {
            _erc721.mint(_msgSender(), _tokenIds[i], _uris[i]);
            _amounts[i] = 1;
        }

        emit SporesNFTMintBatch(
            _msgSender(),
            registry.erc721(),
            _tokenIds,
            _amounts
        );
    }

    /**
       @notice Mint Spores NFT Token (ERC1155) to Receiver `msg.sender`
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
    ) external override {
        // verify `_signature` to authorize caller to mint `_tokenId`
        registry.checkAuthorization(
            Signature.MintType.ERC1155_MINTING.getSingleMintingSignature(
                _msgSender(),
                _tokenId,
                _uri,
                _signature
            ),
            keccak256(_signature)
        );

        IERC1155Mintable(registry.erc1155()).mint(
            _msgSender(),
            _tokenId,
            _amount,
            _uri,
            ""
        );

        emit SporesNFTMint(_msgSender(), registry.erc1155(), _tokenId, 1);
    }

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
    ) external override {
        //  If length of `_tokenIds`, `_uris`, `_amounts` are not matched
        //  revert with error
        require(
            _tokenIds.length == _amounts.length &&
                _tokenIds.length == _uris.length,
            "SporesNFTMinterBatch: Size not matched"
        );

        // verify `_signature` to authorize caller to batch mint `_tokenIds`
        registry.checkAuthorization(
            Signature.MintType.ERC1155_MINTING.getBatchMintingSignature(
                _msgSender(),
                _tokenIds,
                _uris,
                _signature
            ),
            keccak256(_signature)
        );

        IERC1155Mintable _erc1155 = IERC1155Mintable(registry.erc1155());
        for (uint256 i; i < _tokenIds.length; i++) {
            _erc1155.mint(
                _msgSender(),
                _tokenIds[i],
                _amounts[i],
                _uris[i],
                ""
            );
        }

        emit SporesNFTMintBatch(
            _msgSender(),
            registry.erc1155(),
            _tokenIds,
            _amounts
        );
    }

    function _checkAuthorization(
        Signature.MintType _type,
        uint256 _tokenId,
        string calldata _uri,
        bytes calldata _signature
    ) private {
        registry.checkAuthorization(
            _type.getSingleMintingSignature(
                _msgSender(),
                _tokenId,
                _uri,
                _signature
            ),
            keccak256(_signature)
        );
    }

    function _checkAuthorizationBatch(
        Signature.MintType _type,
        uint256[] calldata _tokenIds,
        string[] calldata _uris,
        bytes calldata _signature
    ) private {
        registry.checkAuthorization(
            _type.getBatchMintingSignature(
                _msgSender(),
                _tokenIds,
                _uris,
                _signature
            ),
            keccak256(_signature)
        );
    }
}
