// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

 contract MechaARC is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;
    
    string public baseURI;
    bytes32 public merkleRoot;

    uint256 public constant MAX_APE = 8000;
    uint256 public constant TOTAL_WHITELIST = 800;
    uint256 public constant MAX_WHITELIST = 1;
    uint256 public constant MAX_PUBLIC = 20;

    string public constant BASE_EXTENSION = ".json";

    uint256 public constant PRICE = 0.049 ether;

    bool public presaleActive = false;
    bool public saleActive = false;

    mapping (address => uint256) public presaleWhitelist;

    constructor() ERC721A("MechaARC", "MARC", MAX_PUBLIC) { 
    }
    
    function presaleMint(bytes32[] calldata _merkleProof) private {
        uint256 total = presaleWhitelist[msg.sender] + 1;
        if(presaleActive){
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),         "Invalid proof");
        }
        require(total <= MAX_WHITELIST,                                         "Can't mint more than reserved");
        presaleWhitelist[msg.sender] = total;

        _safeMint( msg.sender, 1 );    
    }
    
    function publicMint(uint256 _numberOfMints) private {
        require(_numberOfMints > 0 && _numberOfMints <= MAX_PUBLIC,             "Invalid purchase amount");
        require(totalSupply() + _numberOfMints <= MAX_APE,                      "Purchase would exceed max supply of tokens");
        require(PRICE * _numberOfMints == msg.value,                            "Ether value sent is not correct");
        
        _safeMint( msg.sender, _numberOfMints );
    }

    function mint(bytes32[] calldata _merkleProof, uint256 _numberOfMints) public payable {
        require(presaleActive || saleActive,                                    "Not started");
        require(tx.origin == msg.sender,                                        "What ya doing?");
        if(presaleActive || totalSupply() < TOTAL_WHITELIST){
            presaleMint(_merkleProof);
        } else {
            publicMint(_numberOfMints);
        }
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        presaleActive = false;
        saleActive = !saleActive;
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
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
            ? string(abi.encodePacked(currentBaseURI, _id.toString(), BASE_EXTENSION))
            : "";
    }

    function whitelistRemain(bytes32[] calldata _merkleProof, address _address) external view returns(uint256 count) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        if(MerkleProof.verify(_merkleProof, merkleRoot, leaf) && presaleActive) {
            return MAX_WHITELIST - presaleWhitelist[_address];
        } else {
            return 0;
        }
    }

    function withdraw(address _address) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_address).transfer(balance);
    }    
}