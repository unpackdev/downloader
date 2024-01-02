// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Keisuke OHNO

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
import "./MerkleProof.sol";


interface iNFTCollection {
    function balanceOf(address _owner) external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getStageByTokenId( uint256 _tokenId ) external view returns(uint256);
    function setStageByTokenId(uint256 _tokenId , uint256 _stage ) external ; 
    function DonationEvent(uint256 _tokenId , address user) external;

 }

contract changeStage is Ownable , AccessControl{


    constructor(){
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole( ADMIN             , msg.sender);

        _setupRole(DEFAULT_ADMIN_ROLE, 0xF2514B3A47a8e7Cd4B5684d80D5C70fEF8d536A0);
        grantRole(ADMIN             , 0xF2514B3A47a8e7Cd4B5684d80D5C70fEF8d536A0);

        setNFTCollection(0x8b81aef8446379B4aC6B32ac2Ca169130AD8aAAB);

    }

    iNFTCollection public NFTCollection;
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");


    //
    //withdraw section
    //

    address public withdrawAddress = 0x3742FFF5D84AA72E4b1d700e87D22e43644F82C5;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setNFTCollection(address _address) public onlyRole(ADMIN) {
        NFTCollection = iNFTCollection(_address);
    }

    function nftOwnerOf(uint256 _tokenId)public view returns(address){
        return NFTCollection.ownerOf(_tokenId);
    }

    function nftBalanceOf(address _address)public view returns(uint256){
        return NFTCollection.balanceOf(_address);
    }

    function nftGetStageByTokenId(uint256 _tokenId )public view returns(uint256){
        return NFTCollection.getStageByTokenId(_tokenId);
    }
    

    //https://eth-converter.com/
    uint256 public cost = 7000000000000000;
    bool public pausedDonation = true;

    function setPauseDonation(bool _state) public onlyRole(ADMIN) {
        pausedDonation = _state;
    }

    function setCost(uint256 _newCost) public onlyRole(ADMIN) {
        cost = _newCost;
    }

    //寄付により、ステージを　0→1　もしくは、2→3に変更する
    function donation( uint256 _tokenId ) public payable{
        require(!pausedDonation, "the contract is paused");
        require( cost == msg.value, "insufficient funds");

        require( msg.sender == nftOwnerOf(_tokenId) , "Owner is different");
        uint256 stage = nftGetStageByTokenId( _tokenId );
        require( stage == 0 || stage == 2 , "You have already made a donation." );

        if( stage == 0){
            NFTCollection.setStageByTokenId( _tokenId , 1);
        }
        if( stage == 2){
            NFTCollection.setStageByTokenId( _tokenId , 3);
        }

        NFTCollection.DonationEvent( _tokenId , msg.sender );

    }


    //寄付によるイベント発行
    function donationEvent( uint256 _tokenId ) public payable{
        require(!pausedDonation, "the contract is paused");
        require( cost == msg.value, "insufficient funds");

        require( msg.sender == nftOwnerOf(_tokenId) , "Owner is different");
        uint256 stage = nftGetStageByTokenId( _tokenId );
        require( stage == 0 || stage == 2 , "You have already made a donation." );

        NFTCollection.DonationEvent( _tokenId , msg.sender );

    }


    //寄付により、ステージを　0→1　もしくは、2→3に変更する
    function donationTokens( uint256[] memory _tokenIds ) public payable{
        require(!pausedDonation, "the contract is paused");
        require( cost * _tokenIds.length == msg.value, "insufficient funds");

        for (uint256 i = 0; i < _tokenIds.length; i++) {

            require( msg.sender == nftOwnerOf( _tokenIds[i] ) , "Owner is different");
            uint256 stage = nftGetStageByTokenId( _tokenIds[i] );
            require( stage == 0 || stage == 2 , "You have already made a donation." );

            if( stage == 0){
                NFTCollection.setStageByTokenId(  _tokenIds[i]  , 1);
            }
            if( stage == 2){
                NFTCollection.setStageByTokenId(  _tokenIds[i]  , 3);
            }
    
            NFTCollection.DonationEvent( _tokenIds[i] , msg.sender );

        }

    }

    //寄付によるイベント発行
    function donationTokensEvent( uint256[] memory _tokenIds ) public payable{
        require(!pausedDonation, "the contract is paused");
        require( cost * _tokenIds.length == msg.value, "insufficient funds");

        for (uint256 i = 0; i < _tokenIds.length; i++) {

            require( msg.sender == nftOwnerOf( _tokenIds[i] ) , "Owner is different");
            uint256 stage = nftGetStageByTokenId( _tokenIds[i] );
            require( stage == 0 || stage == 2 , "You have already made a donation." );
    
            NFTCollection.DonationEvent( _tokenIds[i] , msg.sender );

        }

    }



    bytes32 public constant STAGECHANGER_ROLE  = keccak256("STAGECHANGER_ROLE");
    bool public pausedVisit = true;

    function setPauseVisit(bool _state) public onlyRole(ADMIN) {
        pausedVisit = _state;
    }

    //訪問により、ステージを　0→2　もしくは　1→3に変更する
    function visit( uint256 _tokenId ) public onlyRole(STAGECHANGER_ROLE){
        require(!pausedVisit, "the contract is paused");
        uint256 stage = nftGetStageByTokenId( _tokenId );
        require( stage == 0 || stage == 1 , "You have already visited the castle." );

        if( stage == 0){
            NFTCollection.setStageByTokenId( _tokenId , 2);
        }
        if( stage == 1){
            NFTCollection.setStageByTokenId( _tokenId , 3);
        }

    }

    //訪問により、ステージを　0→2　もしくは　1→3に変更する
    function visitTokens( uint256[] memory _tokenIds ) public onlyRole(STAGECHANGER_ROLE){
        require(!pausedVisit, "the contract is paused");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 stage = nftGetStageByTokenId( _tokenIds[i] );

            if( stage == 0){
                NFTCollection.setStageByTokenId( _tokenIds[i] , 2);
            }
            if( stage == 1){
                NFTCollection.setStageByTokenId( _tokenIds[i] , 3);
            }

        }

    }


}