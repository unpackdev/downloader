// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./LibEIP712.sol";

/**
 * @dev Helper for Swap object. Define de structs type data and other utils
 */
library LibSwap  {
    
    /**
    * @dev Hash for the EIP712 Swap Schema:
    */
    bytes32 constant private _EIP712_SWAP_SCHEMA_HASH = 
        keccak256(
            abi.encodePacked(
                "Swap(",
                "string version,",
                "address makerAddress,",
                "address takerAddress,",
                "uint256 expirationTimeSeconds,",
                "uint256 createTimeSeconds,",
                "uint256 salt,",
                "TokenData[] makerTokenData,",
                "TokenData[] takerTokenData",
                ")",
                "TokenData(",
                "uint8 tokenType,",
                "address tokenContract,",
                "uint256 amount,",
                "uint256 tokenId"
                ")"
            )
        );

    /**
    * @dev Hash for the EIP712 TokenData Schema:
    */
     bytes32 constant private _EIP712_TOKEN_DATA_SCHEMA_HASH = 
        keccak256(
            abi.encodePacked(
                "TokenData(",
                "uint8 tokenType,",
                "address tokenContract,",
                "uint256 amount,",
                "uint256 tokenId"
                ")"
            )
        );

    /**
    * @dev Swap status after assert
    */
    enum SwapStatus {
        INVALID,
        INVALID_SIGNATURE,                   
        INVALID_MAKER_TOKEN_AMOUNT,
        INVALID_TAKER_TOKEN_AMOUNT,
        FILLABLE,            
        EXPIRED,             
        FILLED,              
        CANCELLED            
    }

    /**
    * @dev Allows type tokens to swap
    */
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
    * @dev Structure of data to swap
    */
    struct TokenData {
        TokenType tokenType;
        address tokenContract;
        uint256 amount;
        uint256 tokenId;
    }

    /**
    * @dev Swap structure
    */
    struct Swap {
        string version;
        address makerAddress;           
        address takerAddress;           
        uint256 expirationTimeSeconds;  
        uint256 createTimeSeconds;
        uint256 salt;                   
        TokenData[] makerTokenData;       
        TokenData[] takerTokenData;
    }

    /**
    * @dev Swap processing info
    */
    struct SwapInfo {
        SwapStatus swapStatus;                 
        bytes32 swapHash;
        uint256 timestamp;                      
    }

    /**
     * @dev Returns the hash from Swap usin  domain as specifiede in EIP-712
     * @param swap swap to hash
     * @param domain domain as specified in EIP-712
     * @return swapHash hash as specified in EIP-712
     */
    function getHash(Swap memory swap, LibEIP712.EIP712Domain memory domain) internal pure returns (bytes32 swapHash) { 
        swapHash = LibEIP712.hashTypedData(domain, _getStructHash(swap));
        return swapHash;
    }

    /**
     * @dev Returns the struct hash from Swap as specified in EIP-712
     * @param swap swap to hash
     * @return structHash hash as specified in EIP-712
     */
    function _getStructHash(Swap memory swap) private pure returns (bytes32 structHash) {
        structHash = 
            keccak256(
                abi.encode(
                    _EIP712_SWAP_SCHEMA_HASH,
                    keccak256(bytes(swap.version)),
                    swap.makerAddress,
                    swap.takerAddress,
                    swap.expirationTimeSeconds,
                    swap.createTimeSeconds,
                    swap.salt,
                    _getStructHash(swap.makerTokenData),
                    _getStructHash(swap.takerTokenData)
                )
            );

        return structHash;
    }

    /**
     * @dev Returns the array struct hash from TokenData as specified in EIP-712
     * @param tokenData array of TokenData
     * @return structHash hash as specified in EIP-712
     */
    function _getStructHash(TokenData[] memory tokenData) private pure returns (bytes32 structHash) {
        if(tokenData.length > 0){
            bytes memory encode =  abi.encodePacked(_getStructHash(tokenData[0]));
            for (uint256 i = 1; i < tokenData.length; i++) {
                encode = abi.encodePacked(encode, _getStructHash(tokenData[i]));
            }
            structHash = keccak256(encode);
        }

        return structHash;
    }

    /**
     * @dev Returns the struct hash from TokenData as specified in EIP-712
     * @param tokenData struct TokenData
     * @return structHash hash as specified in EIP-712
     */
    function _getStructHash(TokenData memory tokenData) private pure returns (bytes32 structHash) {
        structHash = 
            keccak256(
                abi.encode(
                    _EIP712_TOKEN_DATA_SCHEMA_HASH,
                    tokenData.tokenType,
                    tokenData.tokenContract,
                    tokenData.amount,
                    tokenData.tokenId
                )
            );

        return structHash;
    }    
}