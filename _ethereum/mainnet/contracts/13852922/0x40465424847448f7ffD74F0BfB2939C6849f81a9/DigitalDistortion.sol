// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract DigitalDistortion is ERC721, Ownable {
    event NewTokenHash(uint256 indexed tokenId, bytes32 indexed tokenHash);

    using ECDSA for bytes32;
    using Strings for uint256;

    bool public earlyMintIsActive = false;
    bool public mintIsActive = false;

    uint256 constant public MAX_SUPPLY = 156;
    uint256 constant public DIGITAL_DISTORTION_PRICE = 0.07 ether;

    uint256 private _totalSupply = 0;
    string private _tokenBaseURI;
    address private _signatureVerifier = 0x805c057A31B31c84F7759698298aD4dC6F8fA622;
    address private _naufalsAddress = 0x037D807f600bb57E7a17506D9419783Be61c365D;
    
    constructor() ERC721("DigitalDistortion", "DIGITALDISTORTION") {
        // for Naufals team
        for (uint256 i = 0; i < 4; i++) {
            _totalSupply += 1;
            _safeMint(_naufalsAddress, _totalSupply);
        }
    }

    // onlyOwner functions

    function flipEarlyMintState() public onlyOwner {
        earlyMintIsActive = !earlyMintIsActive;
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _tokenBaseURI = baseURI_;
    }

    // public functions

    function earlyMint(bytes memory signature) public payable {
        uint256 walletBalance = ERC721.balanceOf(msg.sender);
        require(earlyMintIsActive, "Early minting not active");
        require(_totalSupply + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(walletBalance + 1 <= 1, "Mint would exceed max mint");
        require(DIGITAL_DISTORTION_PRICE == msg.value, "Sent ether value is incorrect");
        require(keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(signature) == _signatureVerifier, "Unrecognizable Hash");

        _totalSupply += 1;
        _safeMint(msg.sender, _totalSupply);
    }

    function mint() public payable {
        uint256 walletBalance = ERC721.balanceOf(msg.sender);
        require(mintIsActive, "Minting is not active");
        require(_totalSupply + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(walletBalance + 1 <= 5, "Mint would exceed max mint");
        require(DIGITAL_DISTORTION_PRICE == msg.value, "Sent ether value is incorrect");
        
        _totalSupply += 1;
        _safeMint(msg.sender, _totalSupply);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // internal functions

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }
}
