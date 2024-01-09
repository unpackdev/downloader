// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

//              _____
//     ___..--""      `.
//_..-'               ,'
//                  ,'
//   (|\          ,'
//      ________,'
//   ,.`/`./\/`/
//  /-'
//   `',^/\/\
//_________,'
//

// SSS


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";


contract SSS is ERC721Enumerable, Ownable{
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant SSS_GIFT = 250;
    uint256 public constant SSS_PRIVATE = 1000;
    uint256 public constant SSS_PUBLIC = 8750;
    uint256 public constant SSS_MAX = SSS_GIFT + SSS_PRIVATE + SSS_PUBLIC;
    uint256 public constant SSS_PRICE = 0.077 ether;
    uint256 public constant SSS_PER_MINT = 10;


    constructor() ERC721("The Sacred Shark Syndicate","SSS"){}

    mapping(address => uint256) public presalerListPurchases;
    mapping(string => bool) private _usedNonces;

    string private _contractURI = "https://api.sacredsharksyndicate.com/data/sss/collection";
    string private _tokenBaseURI = "https://api.sacredsharksyndicate.com/data/sss/";
    address private _devAddress = 0x7E0923B2547ce81E73036bfe8E3d461c44064351;
    address private _signerAddress = 0x05550Da5b8825c922a4613Caa88983e4d3eE9DB6;

    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public presalePurchaseLimit = 5;
    bool public presaleLive;
    bool public saleLive;
    bool public locked;

    modifier notLocked {
        require(!locked, "Contract metadata methods are locked forever");
        _;
    }

    function hashTransaction(address sender, uint256 qty, string memory nonce) public pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce)))
          );

          return hash;
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature) public view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }

    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
        require(saleLive, "Sale is not live");
        require(!presaleLive, "Presale is live");
        require(matchAddresSigner(hash, signature), "Can't mint");
        require(!_usedNonces[nonce], "Hash already used");
        require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "Hash failed");
        require(totalSupply() < SSS_MAX, "Out of stock");
        require(publicAmountMinted + tokenQuantity <= SSS_PUBLIC, "Public sale limit exceeded");
        require(tokenQuantity <= SSS_PER_MINT, "Token quantity per mint exceeded");
        require(SSS_PRICE * tokenQuantity <= msg.value, "Not enough ether");

        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }

        _usedNonces[nonce] = true;
    }

    function presaleBuy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "Presale is closed");
        require(matchAddresSigner(hash, signature), "Can't mint");
        require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "Hash failed");
        require(totalSupply() < SSS_MAX, "Out of stock");
        require(privateAmountMinted + tokenQuantity <= SSS_PRIVATE, "Private sale limit exceeded");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "Token allocation exceeded");
        require(SSS_PRICE * tokenQuantity <= msg.value, "Not enough ether");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function giftList(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= SSS_MAX, "Out of stock");
        require(giftedAmount + receivers.length <= SSS_GIFT, "No more gifts");

        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function giftBatch(address receiver, uint256 tokenQuantity) external onlyOwner {
        require(totalSupply() + tokenQuantity <= SSS_MAX, "Out of stock");
        require(giftedAmount + tokenQuantity <= SSS_GIFT, "No more gifts");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            giftedAmount++;
            _safeMint(receiver, totalSupply() + 1);
        }
    }

    function withdraw() external payable onlyOwner {
        payable(_devAddress).transfer(address(this).balance / 10);
        payable(msg.sender).transfer(address(this).balance);
    }

    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }

    // Owner functions for enabling presale, sale and revealing
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

}