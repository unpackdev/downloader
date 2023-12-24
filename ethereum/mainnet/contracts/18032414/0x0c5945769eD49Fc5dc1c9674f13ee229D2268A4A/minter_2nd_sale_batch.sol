// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Keisuke OHNO (kei31.eth)

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./AccessControl.sol";


//NFT interface
interface iNFTCollection {
    function balanceOf(address _owner) external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom( address from, address to, uint256 tokenId) external ;
}

contract NFTSellserBatch is Ownable , AccessControl{

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole( ADMIN             , msg.sender);

        setSellserWalletAddress(0xa6EEdDCd3a1a3cAD0d0192ac50630AfB2e75a112);
        setWithdrawAddress(0x0050Ab4970100557F44730ad13c944A1C68dCD61);
        setNFTCollection(0x597D757f8502F1fe8E7dD6fc7FE884A51C5Ae2b9);
    }
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");


    //
    //withdraw section
    //

    address public withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //buy section
    //

    bool public paused = true;
    uint256 public totalCost = 3900000000000000000;
    address public sellerWalletAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;
    address public buyerWalletAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    uint256[] public saleTokenIds;

    //https://eth-converter.com/

    iNFTCollection public NFTCollection;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function buy() public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(totalCost  <= msg.value  , "insufficient funds");
        require( msg.sender == buyerWalletAddress , "You are not on the Arrow List.");
        
        for (uint256 i = 0; i < saleTokenIds.length; i++) {
            require(NFTCollection.ownerOf(saleTokenIds[i]) == sellerWalletAddress , "NFT out of stock");
            NFTCollection.safeTransferFrom( sellerWalletAddress , buyerWalletAddress , saleTokenIds[i] );
        }

    }

    function buyPie( address receiver ) public payable callerIsUser onlyRole(MINTER_ROLE){
        require(!paused, "the contract is paused");
        require(totalCost  <= msg.value  , "insufficient funds");
        require( receiver == buyerWalletAddress , "You are not on the Arrow List.");
        
        for (uint256 i = 0; i < saleTokenIds.length; i++) {
            require(NFTCollection.ownerOf(saleTokenIds[i]) == sellerWalletAddress , "NFT out of stock");
            NFTCollection.safeTransferFrom( sellerWalletAddress , buyerWalletAddress , saleTokenIds[i] );
        }

    }

    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function setTotalCost(uint256 _newCost) public onlyRole(ADMIN) {
        totalCost = _newCost;
    }

    function setBuyerWalletAddress(address _BuyerWalletAddress) public onlyRole(ADMIN)  {
        buyerWalletAddress = _BuyerWalletAddress;
    }

    function setSellserWalletAddress(address _sellerWalletAddress) public onlyRole(ADMIN)  {
        sellerWalletAddress = _sellerWalletAddress;
    }

    function setSaleTokenIds(uint256[] memory _tokenIds ) public onlyRole(ADMIN){
        saleTokenIds = _tokenIds;
    }
    function getSaleTokenIds() public view returns (uint256[] memory){
        return saleTokenIds;
    }

    function setNFTCollection(address _address) public onlyRole(ADMIN) {
        NFTCollection = iNFTCollection(_address);
    }

    function setSaleData(
        uint256 _newCost,
        address _sellerWalletAddress,
        address _buyerWalletAddress,
        address _NFTCollectionAddress,
        uint256[] memory _tokenIds
    ) public onlyRole(ADMIN){
        setTotalCost(_newCost);
        setSellserWalletAddress(_sellerWalletAddress);
        setBuyerWalletAddress(_buyerWalletAddress);
        setNFTCollection(_NFTCollectionAddress);
        setSaleTokenIds(_tokenIds);
    }

    function nftOwnerOf(uint256 _tokenId)public view returns(address){
        return NFTCollection.ownerOf(_tokenId);
    }

    function NFTinStock()public view returns(bool){
        
        if( saleTokenIds.length == 0){
            return false;
        }

        for (uint256 i = 0; i < saleTokenIds.length; i++) {
            if( NFTCollection.ownerOf(saleTokenIds[i]) != sellerWalletAddress ){
                return false;
            }
        }
        
        return true;

    }

}
       