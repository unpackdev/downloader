// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract Fate is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public fateGiftSupply = 66;
    uint256 public fateSaleSupply = 5940;
    uint256 public fateMaxSupply = fateGiftSupply + fateSaleSupply;

    uint256 public fatePrice = 0.06006 ether;
    uint256 public constant fatePresaleLimit = 2;
    uint256 public constant fatePublicLimit = 10;

    address private _SIGNER_ADDRESS;
    string private _contractURI;
    string private _tokenBaseURI;

    bool public presaleLive = false;
    bool public publicLive = false;

    uint256 public giftedAmount;
    uint256 public mintedPublicAmount;
    
    mapping(address => uint256) addressPurchases;
    mapping(string => uint256) noncePurchases;

    constructor() ERC721("Project Fate", "FATE") {}

    function publicMint(uint256 tokenQuantity) external payable {
        require(publicLive, "Public not live");
        require(!presaleLive, "Presale live");
        require(tokenQuantity <= fatePublicLimit,"Quantity exceeds limit");
        require(mintedPublicAmount + tokenQuantity <= fateSaleSupply,"Quantity exceeds supply");
        require(fatePrice * tokenQuantity <= msg.value,"Value below price");
        require(mintedPublicAmount < fateSaleSupply, "Out of stock");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            mintedPublicAmount++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function presaleMint(bytes32 hash,bytes memory signature,string memory nonce,uint256 tokenQuantity) external payable {
        require(!publicLive, "Public live");
        require(presaleLive, "Presale not live");
        require(hashTransaction(msg.sender, nonce) == hash,"Hash not match");
        require(matchSignerAddress(hash, signature), "Not authorized");
        require(tokenQuantity <= fatePresaleLimit,"Quantity exceeds limit");
        require(addressPurchases[msg.sender] + tokenQuantity <= fatePresaleLimit, "Address exceeds limit");
        require(noncePurchases[nonce] + tokenQuantity <= fatePresaleLimit, "Nonce exceeds limit");
        require(mintedPublicAmount + tokenQuantity <= fateSaleSupply,"Quantity exceeds supply");
        require(fatePrice * tokenQuantity <= msg.value,"Value below price");
        require(mintedPublicAmount < fateSaleSupply, "Out of stock");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            mintedPublicAmount++;
            addressPurchases[msg.sender]++;
            noncePurchases[nonce]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function gift(address[] calldata addresses) external onlyOwner {
        require(totalSupply() + addresses.length <= fateMaxSupply,"Quantity exceeds total supply");
        require(giftedAmount + addresses.length <= fateGiftSupply,"Quantity exceeds gift supply");
        for (uint256 i = 0; i < addresses.length; i++) {
            giftedAmount++;
            _safeMint(addresses[i], totalSupply() + 1);
        }
    }

    function matchSignerAddress(bytes32 hash, bytes memory signature) private view returns (bool){
        return _SIGNER_ADDRESS == hash.recover(signature);
    }

    function hashTransaction(address sender,string memory nonce) private pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",keccak256(abi.encodePacked(sender, nonce))));
        return hash;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setPresaleStatus(bool status) external onlyOwner {
        presaleLive = status;
    }

    function setPublicStatus(bool status) external onlyOwner {
        publicLive = status;
    }

    function setSignerAddress(address _address) external onlyOwner {
        _SIGNER_ADDRESS = _address;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}