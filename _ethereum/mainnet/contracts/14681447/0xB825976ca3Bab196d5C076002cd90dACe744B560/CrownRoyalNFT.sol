// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CasinoRoyal is ERC721, ERC721URIStorage, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint public mintPrice; 
    uint public totalSupply;
    uint public maxSupply;
    uint public maxPerWallet;
    bool public isPublicMintEnabled;
    string public baseTokenUri;
    address payable internal withdrawWallet;
    mapping (address => uint256[]) internal accountMints;
    bool public useHiddenBaseURL;
    string public hiddenBaseTokenUri;

    constructor() payable ERC721("CasinoRoyal", "CR52") {
        totalSupply = 0;
        withdrawWallet = payable(msg.sender);
        useHiddenBaseURL = true;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // **
    // These functions can be execured only by the owner.
    // **

    function setMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerWallet(uint _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        require(mintPrice > 0, "Mint price required");
        require(maxSupply > 0, "Max Supply required");
        require(maxPerWallet > 0, "Max Per Wallet required");
        require(bytes(baseTokenUri).length > 0, "Set a base token URI");
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function setHiddenBaseTokenUri(string calldata _hiddenBaseTokenUri) external onlyOwner {
        hiddenBaseTokenUri = _hiddenBaseTokenUri;
    }

    function setRevealImages(bool _useHiddenBaseURL) external onlyOwner {
        useHiddenBaseURL = _useHiddenBaseURL;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{ value:address(this).balance }('');
        require(success, 'withdraw failed');
    }    
    
    function contractBalance() external view onlyOwner returns(uint)  {
        return address(this).balance;
    }

    // **
    // Anyone can read these functions.
    // **

    function tokenURI(uint256 tokenId_) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId_), 'TokenID Required');
        if(useHiddenBaseURL) {
            return string(abi.encodePacked(getBaseURI()));
        }else{
            return string(abi.encodePacked(getBaseURI(), Strings.toString(tokenId_), ".json"));
        }
    }

    function getBaseURI() internal view returns(string memory)  {
        if(useHiddenBaseURL) {
            return hiddenTokenURI();
        }else{
            return baseTokenURI();
        }
    }
    
    function baseTokenURI() public view returns (string memory) {
        return string(abi.encodePacked(baseTokenUri));
    }

    function hiddenTokenURI() public view returns (string memory) {
        return string(abi.encodePacked(hiddenBaseTokenUri));
    }

    function getMyTokenIDs() public view returns(uint[] memory) {
        return accountMints[msg.sender];
    }

    function myMintCount() public view returns(uint) {
        return accountMints[msg.sender].length;
    }

    // **
    // These are public payable functions.
    // **

    function mint(uint256 quantity_) public payable {
        require(mintPrice > 0, "Mint price need to be set by owner");
        require(maxSupply > 0, "Max supply need to be set by owner");
        require(maxPerWallet > 0, "Max Per Wallet need to be set by owner");
        require(isPublicMintEnabled, 'Minting not enabled');
        require(msg.value == quantity_ * mintPrice, 'Wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'Sold out');
        require(myMintCount() + quantity_ <= maxPerWallet, 'exceed max per wallet');
        
        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            accountMints[msg.sender].push(newTokenId);
            _safeMint(msg.sender, newTokenId);
        }
    }

}