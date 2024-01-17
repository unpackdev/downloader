// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Nghbhd is ERC721A, Ownable {
    
    string public constant BASE_EXTENSION = ".json";
    uint256 public constant MAX_PUBLIC = 3;
    uint256 public constant MAX_PRESALE = 5;
    uint256 public constant MAX_ADMIN = 100;

    string public baseURI;
    uint256 public maxSupply = 7777;
    bytes32 public merkleRoot;
    uint256 public price = 0.02 ether;
    bool public presaleActive = false;
    bool public saleActive = false;
    bool public adminMinted = false;

    mapping (address => uint256) public presaleList;
    mapping (address => uint256) public publicList;
    
    constructor() ERC721A("NGHBHD", "NGBD") {}

    function adminMint() public onlyOwner {
        require(!adminMinted,                                                  "Admin has minted");
        adminMinted = true;
        _safeMint(msg.sender, MAX_ADMIN);    
    }

    function presaleMint(bytes32[] calldata _merkleProof, uint256 _numberOfMints) private {
        uint256 total = presaleList[msg.sender] + _numberOfMints;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_numberOfMints > 0 && total <= MAX_PRESALE,                    "Invalid purchase amount");
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),            "Invalid proof");

        presaleList[msg.sender] = total;
        _safeMint(msg.sender, _numberOfMints);    
    }
    
    function publicMint(uint256 _numberOfMints) private {
        uint256 total = publicList[msg.sender] + _numberOfMints;
        require(_numberOfMints > 0 && total <= MAX_PUBLIC,                      "Invalid purchase amount");

        publicList[msg.sender] = total;
        _safeMint(msg.sender, _numberOfMints);
    }

    function mint(bytes32[] calldata _merkleProof, uint256 _numberOfMints) public payable {
        require(presaleActive || saleActive,                                    "Not started");
        require(tx.origin == msg.sender,                                        "What ya doing?");
        require(price * _numberOfMints == msg.value,                            "Ether value sent is not correct");
        require(totalSupply() + _numberOfMints <= maxSupply,                    "Purchase would exceed max supply of tokens");
        if(presaleActive){
            presaleMint(_merkleProof, _numberOfMints);
        } else {
            publicMint(_numberOfMints);
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
         require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _toString(_id), BASE_EXTENSION))
            : "";
    }

    function withdraw(address _address) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_address).transfer(balance);
    }
}