//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


contract GREYAPES is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxSupply = 700;
    uint256 public pubCost = 0.01 ether;
    bytes32 private merkleRoot;
    bool public wlActive;
    bool public pubActive;
    string private baseURI;
    bool public revealed;
    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public pubPaidMintAmount;

    constructor() ERC721A("LIVES OF LALISA", "LIVESOFLALISA") {
    }

    function mintWL(uint256 _quantity) public payable {
        require(_quantity > 0);
        require(wlActive, "PUBLICSALE_INACTIVE");
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(whitelistClaimed[msg.sender] + _quantity <= 2, "WLPAID_MAXED");
        unchecked {
            whitelistClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }


    function mintPublic(uint256 _quantity) external payable {
        require(_quantity > 0);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(pubActive, "PUBLIC_INACTIVE");
        require(msg.value >= pubCost * _quantity, "INCORRECT_ETH");
        require(pubPaidMintAmount[msg.sender] + _quantity <= 2, "PUBLICPAID_MAXED");
        unchecked {
            pubPaidMintAmount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }

    function ownerMint(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Over Supply");
        require(_quantity > 0, "QUANTITY_INVALID");
        _safeMint(_account, _quantity);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPubCost(uint256 _newCost) public onlyOwner {
        pubCost = _newCost;
    }

    function activateWLSale() external onlyOwner {
        !wlActive ? wlActive = true : wlActive = false;
    }

    function activatePublicSale() external onlyOwner {
        !pubActive ? pubActive = true : pubActive = false;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata _baseURI, bool reveal) external onlyOwner {
        if (!revealed && reveal) revealed = reveal; 
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        if (revealed) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawAny(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }
}