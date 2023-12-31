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
import "./MerkleProof.sol";


interface iNFTCollection {
    function externalMintWithPhaseId(address _address , uint256 _amount , uint256 _phaseId ) external payable;
}

contract RandomMinter is Ownable {

    constructor(){
        setNFTCollection(0x2895509D9FB161577b58cEB76D71EF9fb85E0cd6);
        setMerkleRoot(0xf9c5c95af0e9994a16a694d94351f56d292ca815d4e55a3063fe7b3e7748f38c);
    }


    //////////////////////////////////////////////////
    //      withdraw section
    //////////////////////////////////////////////////

    address public withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //////////////////////////////////////////////////
    //      mint section section
    //////////////////////////////////////////////////


    uint256 public cost = 0; 
    uint256 public maxAmount0 = 240;
    uint256 public maxAmount1 = 240;
    uint256 public maxAmount2 = 240;
    uint256 public mintedAmount0 = 0;
    uint256 public mintedAmount1 = 0;
    uint256 public mintedAmount2 = 0;

    bool public paused = true;
    bytes32 public merkleRoot;

    mapping(address => uint256) public userMintedAmount;
    mapping(address => uint256) public allowlistUserAmount;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function mint( uint256 _maxMintAmount , bytes32[] calldata _merkleProof ) public payable callerIsUser{

        require(!paused, "the contract is paused");
        require( totalMinted() + 1 <= maxSupply() , "max NFT limit exceeded");
        require( cost <= msg.value, "insufficient funds");

        uint256 maxMintAmountPerAddress;

        bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not allowlisted");
        maxMintAmountPerAddress = _maxMintAmount;
 
        require(1 <= maxMintAmountPerAddress - userMintedAmount[msg.sender] , "max NFT per address exceeded");
        userMintedAmount[msg.sender] += 1;

        uint256 remaining = maxSupply() - totalMinted();
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % remaining;

        if ( 0 <= random && random < (maxAmount0 - mintedAmount0) ) {
            mintedAmount0 += 1;
            NFTCollection.externalMintWithPhaseId( msg.sender , 1 ,3);
        } else if ( (maxAmount0 - mintedAmount0) <= random && random < ((maxAmount0 - mintedAmount0) + (maxAmount1 - mintedAmount1)) ) {
            mintedAmount1 += 1;
            NFTCollection.externalMintWithPhaseId( msg.sender , 1 ,4);
        } else {
            mintedAmount2 += 1;
            NFTCollection.externalMintWithPhaseId( msg.sender , 1 ,5);
        }

    }

    function totalMinted()public view returns(uint256){
        return mintedAmount0 + mintedAmount1 + mintedAmount2;
    }
    function maxSupply()public view returns(uint256){
        return maxAmount0 + maxAmount1 + maxAmount2;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }    
    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }    

    function setMaxMintAmount(uint256 _maxAmount0 , uint256 _maxAmount1 , uint256 _maxAmount2) public onlyOwner {
        maxAmount0 = _maxAmount0;
        maxAmount1 = _maxAmount1;
        maxAmount2 = _maxAmount2;
    }    

    //////////////////////////////////////////////////
    //      interface section
    //////////////////////////////////////////////////

    iNFTCollection public NFTCollection;

    //onlyowner
    function setNFTCollection(address _address) public onlyOwner() {
        NFTCollection = iNFTCollection(_address);
    }

}