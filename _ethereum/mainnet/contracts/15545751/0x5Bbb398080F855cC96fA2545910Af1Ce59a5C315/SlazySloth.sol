// SPDX-License-Identifier: UNLICENSED
/*
******************************************************************
                 
                 Contract Sleazy Sloths Adventure Club

******************************************************************  
                    Developed by Mishzal Zahra
*/
       
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";



contract Sleazy_Sloths is ERC721A, Ownable {
    using Strings for uint256;

  //Max Suppply
    uint256 public maxSupply = 8888;

  //URI uriPrefix is the BaseURI
  string public uriPrefix = "ipfs://QmV2q7zbGgFDGAsBzyAiXdHEyo7oM4uV2WKr2nmwfnweXH/";
  string public uriSuffix = ".json";

  // For Whitelist only
    uint256 public Max_Free_Supply = 4444;
    uint256 FREE_MINT_LIMIT_PER_WALLET = 2;
    uint256 public WLcost = 0.0044 ether;
  
  //Cost For Public Mint
   uint256 public Public_cost = 0.0088 ether;

  // To Pause Mint
  bool public MintPaused = false;

  //To start Public Mint
  bool public PublicMintStarted = false;

  //Merkle Root of Whitelisted Addresses
  bytes32 public merkleRoot = 0x20f0e463b7369e49ef51a5169bbd95069e8aa25efa5bd9f5b81fa2d445a9ad6c ;
  
  //To keep Record of Free Mints of Each Address
  mapping(address => uint256) private freeMintCountMap;

    
    constructor() ERC721A("Sleazy Sloths", "SS") {}

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!MintPaused, "The Mint is paused!");
    _;
  }

    function Whitelist_Mint(uint256 _mintAmount, bytes32[] memory _merkleProof) public payable mintCompliance(_mintAmount) {
          bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
          require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid Merkle Proof." );
          uint256 price = WLcost * _mintAmount;

        if(totalSupply()+ _mintAmount <=  Max_Free_Supply){
            uint256 remainingFreeMint = FREE_MINT_LIMIT_PER_WALLET -freeMintCountMap[msg.sender];
            if(remainingFreeMint > 0){
                if(_mintAmount >= remainingFreeMint){
                    price -= remainingFreeMint * WLcost;
                    updateFreeMintCount(msg.sender,remainingFreeMint);
                }
                else{
                    price-= _mintAmount * WLcost;
                    updateFreeMintCount(msg.sender,_mintAmount);
                }
            }
        }
        require(msg.value >= price,"Not enough ether sent.");
 
        _safeMint(msg.sender, _mintAmount);
    }
  

  function Public_Mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(msg.value >= Public_cost * _mintAmount, "Insufficient funds!");
    require(PublicMintStarted, "Public mint is not active");

    _safeMint(msg.sender, _mintAmount);
  }


  function Airdrop(uint256 _mintAmount, address[] memory _receiver) public onlyOwner {
    for (uint256 i = 0; i < _receiver.length; i++) {
      _safeMint(_receiver[i], _mintAmount);
    }
  }

    function Owner_Mint(uint256 _mintAmount) external onlyOwner {
        _safeMint(msg.sender, _mintAmount);
    }


    function updateFreeMintCount(address minter, uint256 count) private {
        freeMintCountMap[minter] += count;
    } 

    function getFMC( address minter) public view returns(uint256){
        return freeMintCountMap[minter];
    }
    function changeFMC(uint256 NEWFMC) public onlyOwner {
        FREE_MINT_LIMIT_PER_WALLET = NEWFMC;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
  return uriPrefix;
  }

  function StartPublicSale(bool _state) public onlyOwner {
    PublicMintStarted = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setPublicCost(uint256 _Public_cost) public onlyOwner {
   Public_cost  = _Public_cost;
  }

  function setWLcost(uint256 _WLcost) public onlyOwner {
    WLcost = _WLcost;
  }

  function SetBaseURI(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function UpdateMAxFreeSupply(uint256 _Max_Free_Supply) public onlyOwner {
    Max_Free_Supply = _Max_Free_Supply;
  }

  function Pause_Mint(bool _state) public onlyOwner {
    MintPaused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}