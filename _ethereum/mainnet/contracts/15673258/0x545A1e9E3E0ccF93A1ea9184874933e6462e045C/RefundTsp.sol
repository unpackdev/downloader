// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Include.sol";
import "./MerkleProofUpgradeable.sol";

contract RefundTsp is Configurable,IERC721ReceiverUpgradeable {

    uint private _entered;
    modifier nonReentrant {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }
   

    mapping(address => uint) public refundedNum; //user address =>refundNum
    mapping(uint =>bool) public tokenIdRefunded; //tokenId =>refuned

    bytes32 public root;
    address public nft;    
    uint public begin;
    uint public end;
    uint public refundPrice;
    uint public refundMax; //2
    address public refundNftTo; //nft to
    address public withdrawTo; //eth to

    uint[] public limitId;

    function initialize(address governor_) initializer public {
        __Governable_init_unchained(governor_);
        nft = 0xD9372167eF419cFBbcD6483603AD15976364e557;
        begin = 1664766000;
        end = 1665198000;
        refundMax = 2;
        refundNftTo =  msg.sender;
        withdrawTo = msg.sender;
        limitId = [500,999,6000,6499];

    }
   
    function setRoot(bytes32 root_) external governance {
        root = root_;
    }

    function setPara(bytes32 root_,address nft_,uint begin_,uint end_,uint refundPrice_,uint refundMax_,address refundNftTo_,address withdrawTo_,uint[] calldata limitId_) external governance {
        root = root_;
        nft = nft_;
        begin = begin_;
        end = end_;
        refundPrice = refundPrice_;
        refundMax = refundMax_;
        refundNftTo = refundNftTo_;
        withdrawTo = withdrawTo_;
        limitId = limitId_;
    }

    receive() external payable{
    }
    
    fallback() external {
    }

    function tokenIdInRange(uint tokenId) private view returns(bool isIn){
           return (limitId[0]<=tokenId &&tokenId<=limitId[1]) || (limitId[2]<=tokenId && tokenId<=limitId[3]);
    }

    function whitelistRefund(uint[] calldata tokenIds,bytes32[] calldata _merkleProof) public nonReentrant {
        require(begin<=block.timestamp,"Not begin");
        require(end>=block.timestamp,"end");
        require(refundedNum[msg.sender]+tokenIds.length<=refundMax,"over refundMax");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, root, leaf),"Invalid Proof." );

        refundedNum[msg.sender] = refundedNum[msg.sender]+tokenIds.length;
        for(uint i=0;i<tokenIds.length;i++){
            uint tokenId = tokenIds[i];
            require(tokenIdInRange(tokenId),"token id disable refund");
            require(!tokenIdRefunded[tokenId],"refunded");
            IERC721(nft).transferFrom(msg.sender,refundNftTo,tokenId);
            tokenIdRefunded[tokenId] = true;
        }
        payable(msg.sender).transfer(refundPrice*tokenIds.length);
    }



    function refund(uint[] calldata tokenIds) public nonReentrant {
        require(begin<=block.timestamp,"Not begin");
        require(end>=block.timestamp,"end");
        //require(refundedNum[msg.sender]+tokenIds.length<=refundMax,"over refundMax");
        //refundedNum[msg.sender] = refundedNum[msg.sender]+tokenIds.length;
        for(uint i=0;i<tokenIds.length;i++){
            uint tokenId = tokenIds[i];
            require(tokenIdInRange(tokenId),"token id disable refund");
            require(!tokenIdRefunded[tokenId],"refunded");
            IERC721(nft).transferFrom(msg.sender,refundNftTo,tokenId);
            tokenIdRefunded[tokenId] = true;
        }
        payable(msg.sender).transfer(refundPrice*tokenIds.length);
    }

    
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) public override pure returns (bytes4){
        operator;
        from;
        tokenId;
        data;
        return this.onERC721Received.selector;
    }
 
    function withdraw() external governance {
        (bool success, ) = withdrawTo.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function canBeRefunded(uint256 tokenId) public view returns (bool) {
        return tokenIdInRange(tokenId) && begin<=block.timestamp && end>=block.timestamp &&!tokenIdRefunded[tokenId] ;
    }



}
