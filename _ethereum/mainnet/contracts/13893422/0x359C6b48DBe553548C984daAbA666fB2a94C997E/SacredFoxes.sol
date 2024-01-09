// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

contract SacredFoxes is ERC721Enumerable, ReentrancyGuard, Ownable 
{
    using Strings for uint256;
    using ECDSA for bytes32;
    using SafeMath for uint256;

    // Constant variables
    // *******************************************************************

    uint256 public constant FOX_TOTAL_SUPPLY = 2000;   // Total fox supply : 2000    
    uint256 public constant PRICE = 0.06 ether; //0.05 ETH
    uint256 public constant OG_PRICE = 0.05 ether; //0.06 ETH

    // Team addresses
    // *******************************************************************

    address private constant _oAddress  = 0x3b568991cFeED9CD7591e6caB8Dafc717d3b79FC;
    address private constant _hAddress  = 0xb409603dFb712C6e6025ec7Da216E8871B5D9E90;
    address private constant _mAddress  = 0x7F17fA42D9ae6E4dC1a10ce70798b3aFb7cc4D84;
    
    // Signer address
    // *******************************************************************

    address private _signerAddress = 0x4633519d554d9819cf4Edd82Edb60CBF859d0e07;

    // State variables
    // *******************************************************************

    bool public isPresaleLive;
    bool public isPublicSaleLive;
    bool public freezed;
    string public FOXS_PROVENANCE;
    uint256 public reservationAmount;
    
    // Presale arrays
    // *******************************************************************

    mapping(address => uint256) public _presalerQuantity; // Amount of foxs get for pre-sales

    // URI variables
    // *******************************************************************

    string private _osContractURI;
    string private _baseTokenURI;

    // Constructor
    // *******************************************************************

    constructor(string memory osURI, string memory baseURI) ERC721("Sacred Foxes", "SF") 
    {
        _osContractURI = osURI;
        _baseTokenURI = baseURI;
    }


    // Modifiers
    // *******************************************************************

    modifier onlyPresale() 
    {
        require(!isPublicSaleLive && isPresaleLive, "PRESALE_NOT_LIVE");
        _;
    }

    modifier onlyPublicSale() 
    {
        require(isPublicSaleLive, "PUBLIC_SALE_NOT_LIVE");
        _;
    }
    
    modifier notFreezed 
    {
        require(!freezed, "CONTRACT_METADATA_METHODS_FREEZED");
        _;
    }

    function togglePresaleStatus() external onlyOwner 
    {
        isPresaleLive = !isPresaleLive;
    }

    function togglePublicSaleStatus() external onlyOwner 
    {
        isPublicSaleLive = !isPublicSaleLive;
    }

    // Mint functions
    // *******************************************************************

    function sendGift(address[] calldata addr) external onlyOwner 
    {
        require(totalSupply() < FOX_TOTAL_SUPPLY, "ALL_FOXS_SOLD_OUT");

        for (uint256 i = 0; i < addr.length; i++) 
        {
            reservationAmount++;
            _safeMint(addr[i], totalSupply() + 1);
        }
    }

    function presalesMint(bytes32 hash, bytes memory signature, uint256 quantity, bool isOG) external payable nonReentrant onlyPresale 
    {
       require(matchAddresSigner(hash, signature), "INVALID_SIGNER_ADDRESS");
       require(hashTransaction(msg.sender, quantity, isOG) == hash, "INVALID_HASH");
       
       require(_presalerQuantity[msg.sender] < 3, "EXCEED_PRESALES_MINT");
       require(quantity > 0 && quantity <= 3, "INVALID_QUANTITY");
       require(totalSupply() < FOX_TOTAL_SUPPLY, "ALL_FOXS_SOLD_OUT");
       require(totalSupply() + quantity <= FOX_TOTAL_SUPPLY, "EXCEED_PUBLIC_SUPPLY");

       if (isOG)
           require(OG_PRICE * quantity == msg.value, "INVALID_ETH_AMOUNT");
       else
           require(PRICE * quantity == msg.value, "INVALID_ETH_AMOUNT");
       

       for (uint256 i = 0; i < quantity; i++) 
       {
           _presalerQuantity[msg.sender]++;
           _safeMint(msg.sender, totalSupply() + 1);
       }
    }

    function publicMint(uint256 quantity) external payable nonReentrant onlyPublicSale 
    {
        require(tx.origin == msg.sender, "NO_CONTRACT_MINTING");
        require(quantity > 0 && quantity <= 3, "INVALID_QUANTITY");
        require(totalSupply() < FOX_TOTAL_SUPPLY, "ALL_FOXS_SOLD_OUT");
        require(totalSupply() + quantity <= FOX_TOTAL_SUPPLY, "EXCEED_PUBLIC_SUPPLY");
        require(PRICE * quantity == msg.value, "INVALID_ETH_AMOUNT");
    
        for (uint256 i = 0; i < quantity; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
     
    // Hash Functions
    // *******************************************************************

    function setSignerAddress(address addr) external onlyOwner 
    {
        _signerAddress = addr;
    }
    
    function hashTransaction(address sender, uint256 quantity, bool isOG) private pure returns(bytes32) 
    {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, quantity, isOG)))
          );
          
        return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) 
    {
        return _signerAddress == hash.recover(signature);
    }
    

    // Base URI Functions
    // *******************************************************************
    
    function setContractURI(string calldata URI) external onlyOwner notFreezed 
    {
        _osContractURI = URI;
    }

    function contractURI() public view returns (string memory) 
    {
        return _osContractURI;
    }
    
    function setBaseTokenURI(string calldata URI) external onlyOwner notFreezed
    {
        _baseTokenURI = URI;
    }

    function baseTokenURI() public view returns (string memory) 
    {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) 
    {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }
    
    // Freeze metadata
    // *******************************************************************

    function freezedMetadata() external onlyOwner 
    {
        freezed = true;
    }
    
    function setProvenanceHash(string calldata hash) external onlyOwner notFreezed 
    {
        FOXS_PROVENANCE = hash;
    }
    

    // Withdrawal function
    // *******************************************************************

    function withdrawAll() external onlyOwner 
    {
        uint256 _a1 = address(this).balance.div(100).mul(30);
        uint256 _a2 = address(this).balance.div(100).mul(30);
        uint256 _a3 = address(this).balance.div(100).mul(30);
        require(payable(_oAddress).send(_a1), "SEND_FAIL_TO_A1");
        require(payable(_hAddress).send(_a2), "SEND_FAIL_TO_A2");
        require(payable(_mAddress).send(_a3), "SEND_FAIL_TO_A3");
        require(payable(owner()).send(address(this).balance), "SEND_FAIL_TO_A4");
    }

    // Call function
    // *******************************************************************

    function callData() external view returns (bool, bool, uint256) 
    {
        return (isPresaleLive, isPublicSaleLive, totalSupply());
    }
}