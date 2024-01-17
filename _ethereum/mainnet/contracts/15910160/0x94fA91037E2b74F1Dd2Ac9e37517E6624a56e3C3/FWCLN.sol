
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LEGENDS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//    pragma solidity >=0.6.0 <0.8.0;                                                                                                   //
//                                                                                                                                      //
//    import "./ERC1155PresetMinterPauser.sol";                                                           //
//                                                                                                                                      //
//    contract NftLegends is ERC1155PresetMinterPauser{                                                                                 //
//                                                                                                                                      //
//        // A struct to store NFT Piece information                                                                                    //
//        struct NftType {                                                                                                              //
//            address creator;       // creator address of this piece type                                                              //
//            uint256 marketLimit;   // market limit of this nft                                                                        //
//        }                                                                                                                             //
//                                                                                                                                      //
//        // number of rarities types: COMMON=>1000, RARE=>500, EPIC=>250, LEGENDARY=>100                                               //
//        uint256[] public pieceOfCardArray = [1000, 500, 250, 100];                                                                    //
//                                                                                                                                      //
//        //  nonce for nft collection type                                                                                             //
//     uint256 private nonce;                                                                                                           //
//                                                                                                                                      //
//        // Events                                                                                                                     //
//        event NftCreated(uint256 indexed pieceId, address creator);                                                                   //
//                                                                                                                                      //
//        // Info about each type of Nft                                                                                                //
//     mapping(uint256 => NftType) private NftInfo;                                                                                     //
//                                                                                                                                      //
//         string public baseURI;                                                                                                       //
//                                                                                                                                      //
//        constructor(string memory uri) public ERC1155PresetMinterPauser(uri){                                                         //
//            _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);                                                                           //
//                                                                                                                                      //
//     }                                                                                                                                //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Create a new type of piece                                                                                                //
//            @param _cardType cardType of created piece: 0:COMMON, 1: CLASSIC, 2: RARE, 3: EPIC, 4: LEGENDARY                          //
//            @param _market_limit Limit number of pieces on market                                                                     //
//         */                                                                                                                           //
//        function createNft(                                                                                                           //
//            uint256 _cardType,                                                                                                        //
//            uint256 _market_limit                                                                                                     //
//        ) public{                                                                                                                     //
//            require(hasRole(MINTER_ROLE, _msgSender()), "NftLegends: Only minters can create new NFT");                               //
//            NftInfo[nonce++] = NftType(                                                                                               //
//                msg.sender,                                                                                                           //
//                _market_limit                                                                                                         //
//            );                                                                                                                        //
//            emit NftCreated(nonce-1, msg.sender);                                                                                     //
//                                                                                                                                      //
//            // mint initial supply to the creator                                                                                     //
//            mint(msg.sender, nonce - 1, pieceOfCardArray[_cardType], "");                                                             //
//        }                                                                                                                             //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Grant a new minter                                                                                                        //
//            @param _candidate user address to be a new minter                                                                         //
//         */                                                                                                                           //
//        function grantMinter(address _candidate) external {                                                                           //
//            grantRole(MINTER_ROLE, _candidate);                                                                                       //
//        }                                                                                                                             //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Revoke a minter                                                                                                           //
//            @param _minter minter address to be reverted                                                                              //
//         */                                                                                                                           //
//        function revokeMinter(address _minter) external {                                                                             //
//            revokeRole(MINTER_ROLE, _minter);                                                                                         //
//        }                                                                                                                             //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Get pre-defined market limit for a token                                                                                  //
//            @param _tokenID id of token                                                                                               //
//         */                                                                                                                           //
//        function getMarketLimit(uint256 _tokenID) external view returns (uint256) {                                                   //
//            return NftInfo[_tokenID].marketLimit;                                                                                     //
//        }                                                                                                                             //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Get nonce:                                                                                                                //
//         */                                                                                                                           //
//        function getNonce() external view returns(uint256) {                                                                          //
//            return nonce;                                                                                                             //
//        }                                                                                                                             //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Get piece info                                                                                                            //
//            @param _id piece id                                                                                                       //
//         */                                                                                                                           //
//        function getPieceInfo(uint256 _id) external view returns(uint256 _marketLimit, address _creator){                             //
//            _marketLimit = NftInfo[_id].marketLimit;                                                                                  //
//            _creator = NftInfo[_id].creator;                                                                                          //
//        }                                                                                                                             //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Get nft token URI                                                                                                         //
//         */                                                                                                                           //
//        function uri(uint256 tokenId) external view virtual override returns (string memory) {                                        //
//            require(tokenId < nonce, "NftLegends: Token ID should be less than nonce");                                               //
//            string memory currentBaseURI = _baseURI();                                                                                //
//            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json")) : "";     //
//        }                                                                                                                             //
//                                                                                                                                      //
//                                                                                                                                      //
//        /**                                                                                                                           //
//            Set the nft BaseURI                                                                                                       //
//         */                                                                                                                           //
//        function setBaseURI(string calldata baseURI_) external {                                                                      //
//            require(hasRole(MINTER_ROLE, _msgSender()), "NftLegends: Only minter can change the baseURI");                            //
//            baseURI = baseURI_;                                                                                                       //
//        }                                                                                                                             //
//                                                                                                                                      //
//        function _baseURI() internal view virtual returns (string memory) {                                                           //
//          return baseURI;                                                                                                             //
//        }                                                                                                                             //
//                                                                                                                                      //
//        /**                                                                                                                           //
//         * @dev Converts a uint256 to its ASCII string decimal representation.                                                        //
//         */                                                                                                                           //
//        function _toString(uint256 value) internal pure returns (string memory ptr) {                                                 //
//            assembly {                                                                                                                //
//                // The maximum value of a uint256 contains 78 digits (1 byte per digit),                                              //
//                // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.                                     //
//                                                                                                                                      //
//    // We will need 1 32-byte word to store the length,                                                                               //
//                // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.                                     //
//                ptr := add(mload(0x40), 128)                                                                                          //
//                // Update the free memory pointer to allocate.                                                                        //
//                mstore(0x40, ptr)                                                                                                     //
//                                                                                                                                      //
//                // Cache the end of the memory to calculate the length later.                                                         //
//                let end := ptr                                                                                                        //
//                                                                                                                                      //
//                // We write the string from the rightmost digit to the leftmost digit.                                                //
//                // The following is essentially a do-while loop that also handles the zero case.                                      //
//                // Costs a bit more than early returning for the zero case,                                                           //
//                // but cheaper in terms of deployment and overall runtime costs.                                                      //
//                for {                                                                                                                 //
//                    // Initialize and perform the first pass without check.                                                           //
//                    let temp := value                                                                                                 //
//                    // Move the pointer 1 byte leftwards to point to an empty character slot.                                         //
//                    ptr := sub(ptr, 1)                                                                                                //
//                    // Write the character to the pointer. 48 is the ASCII index of '0'.                                              //
//                    mstore8(ptr, add(48, mod(temp, 10)))                                                                              //
//                    temp := div(temp, 10)                                                                                             //
//                } temp {                                                                                                              //
//                    // Keep dividing temp until zero.                                                                                 //
//                    temp := div(temp, 10)                                                                                             //
//                } { // Body of the for loop.                                                                                          //
//                    ptr := sub(ptr, 1)                                                                                                //
//                    mstore8(ptr, add(48, mod(temp, 10)))                                                                              //
//                }                                                                                                                     //
//                                                                                                                                      //
//                let length := sub(end, ptr)                                                                                           //
//                // Move the pointer 32 bytes leftwards to make room for the length.                                                   //
//                ptr := sub(ptr, 32)                                                                                                   //
//                // Store the length.                                                                                                  //
//                mstore(ptr, length)                                                                                                   //
//            }                                                                                                                         //
//        }                                                                                                                             //
//    }                                                                                                                                 //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FWCLN is ERC721Creator {
    constructor() ERC721Creator("LEGENDS", "FWCLN") {}
}
