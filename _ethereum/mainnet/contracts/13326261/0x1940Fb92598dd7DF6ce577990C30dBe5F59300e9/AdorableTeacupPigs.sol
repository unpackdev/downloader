// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
               AAA         TTTTTTTTTTTTTTTTTTTTTTTPPPPPPPPPPPPPPPPP   
              A:::A        T:::::::::::::::::::::TP::::::::::::::::P  
             A:::::A       T:::::::::::::::::::::TP::::::PPPPPP:::::P 
            A:::::::A      T:::::TT:::::::TT:::::TPP:::::P     P:::::P
           A:::::::::A     TTTTTT  T:::::T  TTTTTT  P::::P     P:::::P
          A:::::A:::::A            T:::::T          P::::P     P:::::P
         A:::::A A:::::A           T:::::T          P::::PPPPPP:::::P 
        A:::::A   A:::::A          T:::::T          P:::::::::::::PP  
       A:::::A     A:::::A         T:::::T          P::::PPPPPPPPP    
      A:::::AAAAAAAAA:::::A        T:::::T          P::::P            
     A:::::::::::::::::::::A       T:::::T          P::::P            
    A:::::AAAAAAAAAAAAA:::::A      T:::::T          P::::P            
   A:::::A             A:::::A   TT:::::::TT      PP::::::PP          
  A:::::A               A:::::A  T:::::::::T      P::::::::P          
 A:::::A                 A:::::A T:::::::::T      P::::::::P          
AAAAAAA                   AAAAAAATTTTTTTTTTT      PPPPPPPPPP  
    
    Adorable Teacup Pigs / 2021 / V2.0
*/

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract AdorableTeacupPigs is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant ATP_MAX = 9999;
    uint256 public constant ATP_PRICE = 0.06 ether;
    uint256 public ATP_PER_MINT = 6;
    
    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    
    string private _contractURI;
    string private _tokenBaseURI = "https://kreative.art/atp/metadata/";

    string public proof;
    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public presalePurchaseLimit = 3;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public saleLive;
    bool public locked;
    
    constructor(uint256 _presaleStartTime, uint256 _presaleEndTiem, uint256 _saleLive) ERC721("Adorable Teacup Pigs", "ATP") {
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTiem;
        saleLive = _saleLive;
    }
    
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    
    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            presalerList[entry] = false;
        }
    }

    function gift(address[] memory _recipients) external onlyOwner {
        require(totalSupply() + _recipients.length <= ATP_MAX, "MAX_MINT");
        for (uint256 i = 0; i < _recipients.length; i++) {
            giftedAmount++;
            _safeMint(_recipients[i], totalSupply() + 1);
        }
    }

    function presaleBuy(uint256 tokenQuantity) external payable {
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "PRESALE_CLOSED");
        require(presalerList[msg.sender], "NOT_QUALIFIED");
        require(totalSupply() < ATP_MAX, "OUT_OF_STOCK");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "EXCEED_ALLOC");
        require(ATP_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() +1);
        }
    }
    
        
    function buy(uint256 tokenQuantity) external payable {
        require(block.timestamp >= presaleEndTime, "ONLY_PRESALE");
        require(block.timestamp >= saleLive, "SALE_CLOSED");
        require(totalSupply() < ATP_MAX, "OUT_OF_STOCK");
        require(privateAmountMinted + publicAmountMinted + tokenQuantity <= ATP_MAX, "EXCEED_PUBLIC");
        require(tokenQuantity <= ATP_PER_MINT, "EXCEED_ATP_PER_MINT");
        require(ATP_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            uint256 newTokenId = totalSupply() +1;
            _safeMint(msg.sender, newTokenId);
            if (newTokenId % 100 == 0) {
                uint256 randomTokenId = random() % 100;
                uint256 winnerTokenId = newTokenId - randomTokenId;
                address luckyWinner = ownerOf(winnerTokenId);
                payable(luckyWinner).transfer(6e17);
            }
        }
    }

    function withdrawSome(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }
    
    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }

    function setPurchaseLimit(uint256 _presaleLimit, uint256 _publicLimit) external onlyOwner {
        presalePurchaseLimit = _presaleLimit;
        ATP_PER_MINT = _publicLimit;
    }
    
    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function setAllTime(
        uint256 _preSaleTime,
        uint256 _preSaleEndTime,
        uint256 _salelive
    ) external onlyOwner {
        presaleStartTime = _preSaleTime;
        presaleEndTime = _preSaleEndTime;
        saleLive = _salelive;
    }
    
    function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        proof = hash;
    }
    
    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }
    
    // aWYgeW91IHJlYWQgdGhpcywgc2VuZCBGcmVkZXJpayMwMDAxLCAiZnJlZGR5IGlzIGJpZyI=
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function random() private view returns (uint256) {
        bytes32 randomHash = keccak256(
            abi.encode(
                block.timestamp,
                block.difficulty,
                block.coinbase,
                msg.sender
            )
        );
        return uint256(randomHash);
    }
}