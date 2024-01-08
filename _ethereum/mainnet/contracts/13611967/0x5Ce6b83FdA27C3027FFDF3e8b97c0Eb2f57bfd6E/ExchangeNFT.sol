//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

contract ExchangeNFT is IERC1155Receiver, Ownable {
    address private contractAddress = 0x7EeF591A6CC0403b9652E98E88476fe1bF31dDeb;      //contract address of new NFT
    address private ownerAddress = 0x05A56DB5f286a099b12ac78d9713e55Ad42Eebb4;     //owner address of new NFT contract
    address[] private oldNftContractAddress;    //addresses of old NFTs. must be initialized after deployed

    mapping (uint256 => uint256) private tokenIDs;   //must be initialized after deployed
    
    mapping (uint256 => uint256) private tokens;
    
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
        if(from == ownerAddress) {
            tokens[id] = tokens[id] + value;
        }
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
    
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256,uint256,bytes)"));
    }
    
    /// @dev Exchange old and new Citizen NFTs
    /// @param nftContractAddress address of old NFT's contract
    /// @param tokenId tokenId of old nft
    function exchangeNFT(address nftContractAddress, uint256 tokenId) public {
        // Check if old nft address is valid
        bool isValidAddress = false;
        for (uint256 i = 0; i < oldNftContractAddress.length; i++) {
            if(oldNftContractAddress[i] == nftContractAddress) {
                isValidAddress = true;
            }
        }

        uint256 senderTokenId = tokenIDs[tokenId];

        require(isValidAddress == true, "Not old citizen nft");

        IERC1155 nft = IERC1155(nftContractAddress);
        uint256 ownNftCount = nft.balanceOf(msg.sender, tokenId);
        require(ownNftCount > 0, "Not found old Citizen NFTs");
        require(tokens[senderTokenId] > 0, "out of NFTs");
        require(tokens[senderTokenId] >= ownNftCount, "out of NFTs");
        nft.safeTransferFrom(msg.sender, address(this), tokenId, ownNftCount, "");

        IERC1155 nft_exchange = IERC1155(contractAddress);
        nft_exchange.safeTransferFrom(address(this), msg.sender, senderTokenId, ownNftCount, "");
        tokens[senderTokenId] = tokens[senderTokenId] - ownNftCount;
    }

    function getNftCounts(address nftContractAddress, address[] calldata account, uint256[] calldata id) public view returns (uint256[] memory) {
        IERC1155 nft = IERC1155(nftContractAddress);
        return nft.balanceOfBatch(account, id);
    }

    function supportsInterface(bytes4 interfaceID) override external view returns (bool) {
    return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    function getTokenCount(uint256 _id) public view returns (uint) { 
        return tokens[_id];
    }

    function getTokenID(uint256 _id) public view returns (uint) { 
        return tokenIDs[_id];
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }

    function setNewNftContractAddress(address _contractAddress) public onlyOwner {
        contractAddress = _contractAddress;
    }

    function setOldNftContractAddress(address[] calldata _oldNftContractAddress) public onlyOwner {
        oldNftContractAddress = _oldNftContractAddress;
    }

    function setTokenID(uint256 oldId, uint256 newId) public onlyOwner {
        tokenIDs[oldId]=newId;
    }
}