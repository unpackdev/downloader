// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


contract BeetsDAOFoundersPass is ERC721A, Ownable{
    bytes32 private merkleRoot;

    string private baseURI;
    uint256 public price = 0.185 ether;
    uint256 public privateMint = 100;

    struct Allowed {
        address user;
        uint256 allowedAmount;
        uint256 maxAllowed;
    }

    mapping(address => Allowed) public allowList;
    
    constructor(string memory _baseUri, bytes32 _merkleRoot) ERC721A("BeetsDAO Founders Pass", "BEETSPASS") {
        merkleRoot = _merkleRoot;
        baseURI = _baseUri;
    }

    function beetslistMint(bytes32[] calldata _merkelProof, uint256 quantity) external payable {
        //checking if user(s) claimed their nft
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkelProof, merkleRoot, leaf), "Not allowed!");
        require(balanceOf(msg.sender) + quantity <= 10 + allowList[msg.sender].maxAllowed, "Quantity exceeds max mint!");

        if(quantity > allowList[msg.sender].allowedAmount) {
            require(totalSupply() + (quantity - allowList[msg.sender].allowedAmount) <= 900, "Public sale sold out! Allow list only.");
            require(msg.value >= price*(quantity - allowList[msg.sender].allowedAmount), "Not enough eth!");
            privateMint -= allowList[msg.sender].allowedAmount;
            allowList[msg.sender].allowedAmount = 0;
        }
        else {
            privateMint -= quantity;
            allowList[msg.sender].allowedAmount -= quantity;
        }

        _mint(msg.sender, quantity);
    }
    
    function mint(uint256 quantity) external payable returns(bool){
        require(msg.value >= price*quantity, "Not enough eth!");
        require(balanceOf(msg.sender) + quantity <= 10 + allowList[msg.sender].maxAllowed, "Quantity exceeds max mint!");
        require(totalSupply() + privateMint + quantity <= 1000, "Public sale sold out! Allow list only.");

        _mint(msg.sender, quantity);
        return true;
    }

    function initBeetslist(Allowed[] memory allowedList) external onlyOwner{
        for(uint256 i = 0; i < allowedList.length; i++){
            allowList[allowedList[i].user].allowedAmount = allowedList[i].allowedAmount;
            allowList[allowedList[i].user].maxAllowed = allowedList[i].maxAllowed;
        }
    }

    function setPriceInWei(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw(address payable receiverAddress, uint _withdrawAmount) external onlyOwner {
        require(address(this).balance >= _withdrawAmount, "Low balance!");
        
        receiverAddress.transfer(_withdrawAmount); 
    }
}   