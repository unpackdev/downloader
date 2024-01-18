// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./IERC1155.sol";
// import "./console.sol";
contract NFTAirdrop {

    // events
    event Erc721AirDrop(address indexed nftContract, address indexed owner, uint[] indexed ids, address[] users);
    event Erc1155AirDrop(address indexed nftContract, address indexed owner, uint[] indexed ids, uint[] amounts, address[] users);

    function erc721Airdrop(
        address _nftCollectionContract, 
        uint[] calldata _ids, 
        address[] calldata _users) 
        external {

            require(_ids.length == _users.length, "NFTAirdrop: ids and users length mismatch");
            require(_ids.length > 0, "NFTAirdrop: ids length is 0");

            // check if the contract is an erc721 contract
            require(IERC721(_nftCollectionContract).supportsInterface(0x80ac58cd), "Not an ERC721 contract");

            // loop through the users and transfer the nfts
            for (uint i = 0; i < _users.length; i++) {
                IERC721(_nftCollectionContract).safeTransferFrom(msg.sender, _users[i], _ids[i]);
            }
            // emit event
            emit Erc721AirDrop(_nftCollectionContract, msg.sender, _ids, _users);
    }


    function erc1155Airdrop(
        address _nftCollectionContract, 
        uint[] calldata _ids, uint[] calldata _amount, 
        address[] calldata _users) 
        external {
            require(_ids.length == _users.length, "NFTAirdrop: ids and users length mismatch");
            require(_ids.length == _amount.length, "NFTAirdrop: ids and amounts length mismatch");
            require(_ids.length > 0, "NFTAirdrop: ids length is 0");

            // check if the contract is an erc1155 contract
            require(IERC1155(_nftCollectionContract).supportsInterface(0xd9b67a26), "Not an ERC1155 contract");

            // loop through the users and transfer the nfts
            for (uint i = 0; i < _users.length; i++) {
                IERC1155(_nftCollectionContract).safeTransferFrom(msg.sender, _users[i], _ids[i], _amount[i], "");
            }

            // emit event
            emit Erc1155AirDrop(_nftCollectionContract, msg.sender, _ids, _amount, _users);

    }
}