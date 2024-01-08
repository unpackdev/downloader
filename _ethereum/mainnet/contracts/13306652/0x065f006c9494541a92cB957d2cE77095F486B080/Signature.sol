// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
   @title Signature library
        This library provides methods to recover a signer of one signature
    + Two types of Minting: ERC721_Minting and ERC1155_Minting (single and batch minting)
    + Four types of trading: NativeCoin_NFT721, NativeCoin_NFT1155, ERC20_NFT721, ERC20_NFT1155   
    + Collection Creation
    + Add sub-collection in one collection 
*/
library Signature {
    enum MintType { 
        ERC721_MINTING,
        ERC1155_MINTING 
    }

    enum TradeType {
        NATIVE_COIN_NFT_721,
        NATIVE_COIN_NFT_1155,
        ERC_20_NFT_721,
        ERC_20_NFT_1155
    }

    struct TradeInfo {
        address _seller;
        address _paymentReceiver;
        address _contractNFT;
        address _paymentToken;
        uint256 _tokenId;
        uint256 _feeRate;
        uint256 _price;
        uint256 _amount;
        uint256 _sellId;
    }

    function getTradingSignature(
        TradeType _type,
        TradeInfo calldata _info,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        // Generate message hash to verify signature
        // Sig = sign(
        //    [
        //     _seller, _paymentReceiver, _contractNFT, _tokenId, _paymentToken,
        //     _feeRate, _price, _amount, _sellId, PURCHASE_TYPE
        //    ]
        // )
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _info._seller, _info._paymentReceiver, _info._contractNFT, _info._tokenId,
                    _info._paymentToken, _info._feeRate, _info._price, _info._amount, _info._sellId, uint256(_type)
                )
            );
        verifier = getSigner(_data, _signature);  
    }

    function getAddSubCollectionSignature(
        uint256 _collectionId,
        uint256 _subcollectionId,
        uint256 _maxEdition,
        uint256 _requestId,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        //  Generate message hash to verify `_signature`
        //  Add Sub-collection request should be signed by Verifier
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _collectionId, _subcollectionId, _maxEdition, _requestId
                )
            );
        verifier = getSigner(_data, _signature);  
    }

    function getSingleMintingSignature(
        MintType _type,
        address _to,
        uint256 _tokenId,
        string calldata _uri,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        //  Generate message hash to verify `_signature`
        //  Minting request should be signed by Verifier
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _to, _tokenId, _uri, uint256(_type)
                )
            );
        verifier = getSigner(_data, _signature);  
    }

    function getBatchMintingSignature(
        MintType _type,
        address _to,
        uint256[] calldata _tokenIds,
        string[] calldata _uris,
        bytes calldata _signature
    ) internal pure returns (address verifier) {
        //  Generate message hash to verify `_signature`
        //  Minting request should be signed by Verifier
        bytes memory _encodeURIs;
        for (uint256 i; i < _uris.length; i++) {
            _encodeURIs = abi.encodePacked(_encodeURIs, _uris[i]);
        }
        bytes32 _data =
            keccak256(
                abi.encodePacked(
                    _to, _tokenIds, _encodeURIs, uint256(_type)
                )
            );
        verifier = getSigner(_data, _signature);    
    }

    function getSigner(bytes32 _data, bytes calldata _signature) private pure returns (address) {
        bytes32 _msgHash = ECDSA.toEthSignedMessageHash(_data);
        return ECDSA.recover(_msgHash, _signature);
    }
}