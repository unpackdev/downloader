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
    function externalMint(address _address , uint256 _amount ) external payable ;
    function externalMintWithStage(address _address , uint256 _amount , uint256 _stage) external payable ;
    function DonationEvent(uint256 _tokenId , address user) external;
    function currentTokenId() external returns(uint256);

}

contract externalMinterPublic is Ownable , AccessControl{

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




    //
    //mint section
    //

    uint256 public mintedAmount = 0;
    function _nextTokenId() internal view returns(uint256){
        return mintedAmount + 1;
    }

    //https://eth-converter.com/
    uint256 public cost = 7000000000000000;
    uint256 public maxSupply = 500;
    uint256 public maxMintAmountPerTransaction = 10;
    uint256 public publicSaleMaxMintAmountPerAddress = 50;
    bool public paused = true;

    bool public onlyAllowlisted = false;
    bool public mintCount = false;

    //0 : Merkle Tree
    //1 : Mapping
    bytes32 public merkleRoot;
    uint256 public saleId = 0;
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
 

    //mint with merkle tree
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof  ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require( _nextTokenId() + _mintAmount -1 <= maxSupply , "max NFT limit exceeded");
        require(cost * _mintAmount == msg.value, "insufficient funds");
        uint256 nextTokenId = NFTCollection.currentTokenId()+1;

        uint256 maxMintAmountPerAddress;
        if(onlyAllowlisted == true) {
            bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
            require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf), "user is not allowlisted");
            maxMintAmountPerAddress = _maxMintAmount;
        }else{
            maxMintAmountPerAddress = publicSaleMaxMintAmountPerAddress;
        }

        if(mintCount == true){
            require(_mintAmount <= maxMintAmountPerAddress - userMintedAmount[saleId][msg.sender] , "max NFT per address exceeded");
            userMintedAmount[saleId][msg.sender] += _mintAmount;
        }

        mintedAmount += _mintAmount;
        NFTCollection.externalMintWithStage( msg.sender, _mintAmount , 1);

        for(uint256 i = 0; i < _mintAmount; i++){
            NFTCollection.DonationEvent( nextTokenId + i , msg.sender);
        }

    }

    function currentTokenId() public view returns(uint256){
        return _nextTokenId() -1;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN) {
        merkleRoot = _merkleRoot;
    }

    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function getUserMintedAmountBySaleId(uint256 _saleId , address _address ) public view returns(uint256){
        return userMintedAmount[_saleId][_address];
    }

    function getUserMintedAmount(address _address ) public view returns(uint256){
        return userMintedAmount[saleId][_address];
    }

    function setSaleId(uint256 _saleId) public onlyRole(ADMIN) {
        saleId = _saleId;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(ADMIN) {
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyRole(ADMIN) {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyRole(ADMIN) {
        cost = _newCost;
    }

    function setOnlyAllowlisted(bool _state) public onlyRole(ADMIN) {
        onlyAllowlisted = _state;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyRole(ADMIN) {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }
  
    function setMintCount(bool _state) public onlyRole(ADMIN) {
        mintCount = _state;
    }

    function setMintedAmount(uint256 _mintedAmount) public onlyRole(ADMIN) {
        mintedAmount = _mintedAmount;
    }

    function setNFTCollection(address _address) public onlyRole(ADMIN) {
        NFTCollection = iNFTCollection(_address);
    }

    function totalSupply() public view returns (uint256) {
        return mintedAmount;
    }

}