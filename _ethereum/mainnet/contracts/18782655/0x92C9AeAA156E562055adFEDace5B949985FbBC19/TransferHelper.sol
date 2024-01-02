//SPDX-License-Identifier: MIT

/*************************************
*                                    *
*     developed by brandneo GmbH     *
*        https://brandneo.de         *
*                                    *
**************************************/

pragma solidity ^0.8.21;

interface IERC721 {
    function ownerOf(uint256 tokenId) view external returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
}

interface IERC1155 {
    function balanceOf(uint256 tokenId) view external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount) external payable;
}

contract TransferHelper {
    event TransferERC721(address _contract, address _to, uint256[] _tokenIds);
    event TransferERC1155(address _contract, address _to, IERC1155TokenIds[] _tokenIds);

     constructor() {}

     struct IERC1155TokenIds {
        uint256 id;
        uint256 amount;
     }

    function bulkTransferERC721(address _contract, address _to, uint256[] calldata _tokenIds) external {
        uint256 count = _tokenIds.length;
        IERC721 transferContract = IERC721(_contract);
        
        require(count <= 50,  "to many tokens");

        for (uint256 i = 0; i < count; ++i) {
            uint256 tokenId = _tokenIds[i];

            require(msg.sender == transferContract.ownerOf(tokenId),  "not the token owner");
            
            transferContract.safeTransferFrom(msg.sender, _to, tokenId);
        }
        
        emit TransferERC721(_contract, _to, _tokenIds);
    }

    function bulkTransferERC1155(address _contract, address _to, IERC1155TokenIds[] calldata _tokenIds) external {
        uint256 count = _tokenIds.length;
        IERC1155 transferContract = IERC1155(_contract);
        
        require(count <= 50,  "to many tokens");

        for (uint256 i = 0; i < count; ++i) {
            IERC1155TokenIds calldata token = _tokenIds[i];

            require(transferContract.balanceOf(token.id) >= token.amount,  "not enough supply");
            
            transferContract.safeTransferFrom(msg.sender, _to, token.id, token.amount);
        }
        
        emit TransferERC1155(_contract, _to, _tokenIds);
    }
}