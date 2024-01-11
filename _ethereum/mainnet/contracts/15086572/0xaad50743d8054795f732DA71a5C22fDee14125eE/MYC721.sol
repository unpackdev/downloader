// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract MonolithYachtClub is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
   
    uint256 private mintPrice = 160000000000000000 wei;
    uint256 private publicCounter = 10000;
    uint256 private privateCounter;
    string private URL;
    bool private frozen;
    bool private mintOpen;
    bool private privateClosed;

    constructor() ERC721("Monolith Yacht Club", "YAHT") {
        setURI("https://monolith.mypinata.cloud/ipfs/QmRsUPhwoLQwDMNjymefAzrWDB6mAQapgiGv81XEuMzPfY/");
        uint256 x = 1;
        uint256 y = 100;
        uint256 localCounter = privateCounter;
        for (uint256 i = x; i <= y; i++) {
            _mint(msg.sender, ++localCounter);
            string memory uri = _createTokenURI(localCounter);
            _setTokenURI(localCounter, uri);
        }
        privateCounter = localCounter;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function publicMint(uint256 nTokens) external payable{
        if (mintOpen == false){
            revert('Public Mint not open');
        }
        require(msg.value <= msg.sender.balance, "Not enough ETH in wallet");
        require(mintPrice*nTokens <= msg.value, "Not enough ETH sent; Price is 0.16 eth per NFT, Maximum 100 per request");
        uint256 localCounter = publicCounter;
        if (nTokens > 100){
            revert('Maximum 100 per request');
        }
        if (localCounter + nTokens > 60000) {
            revert('Supply Not Available, Try Less');
        }
        for (uint256 i = 1; i <= nTokens; i++) {
            _mint(msg.sender, ++localCounter);
            string memory uri = _createTokenURI(localCounter);
            _setTokenURI(localCounter, uri);
        }
        publicCounter = localCounter;   
    }

    function privateMint(uint256 nTokens, address wallet, uint256 whichCounter) external onlyOwner{
        if (privateClosed == true) {
            revert("Private Mint Closed");
        }
        uint256 localCounter;
        if (whichCounter == 1) {
            localCounter = privateCounter;
            if (localCounter + nTokens > 10000) {
                revert('Supply Not Available, Try Less');
            }
        }
        if (whichCounter == 2) {
            localCounter = publicCounter;
            if (localCounter + nTokens > 60000) {
                revert('Supply Not Available, Try Less');
            }
        }
        for (uint256 i = 1; i <= nTokens; i++) {
            _mint(wallet, ++localCounter);
            string memory uri = _createTokenURI(localCounter);
            _setTokenURI(localCounter, uri);
        } 
        if(whichCounter == 1) {
            privateCounter = localCounter;
        }  
        if(whichCounter == 2) {
            publicCounter = localCounter;
        }      
    }

    function _burn(uint256 tokenId) internal onlyOwner override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function mintInfo() public pure returns (string memory){
        return("0.16 ether per NFT, Maximum 100 per Mint request. Mint ends at 60k supply. www.monolithyachtclub.com");
    }

    function price() public view returns (uint256) {
        return(mintPrice);
    }

    function maxSupply() public pure returns (uint256) {
        uint256 max = 60000;
        return(max);
    }

    function freezeMetadata() external onlyOwner {
        if (publicCounter == 60000) {
            frozen = true;
        }
        else{
            revert("Supply has not reached 60000");
        }
    }

    function openPublicMint() external onlyOwner {
        if (publicCounter == 60000) {
            revert('Cannot Open Mint, Supply Sold Out');
        }
        mintOpen = true;
    }

    function closePublicMint() external onlyOwner {
        mintOpen = false;
    }

    function closePrivateMint() external onlyOwner {
        if (privateCounter == 10000) {
            privateClosed = true;
        }
        else{
            revert("Private Mint cannot be closed yet");
        }
    }

    function setURI(string memory newURI) public onlyOwner {
        if (frozen == true){
            revert('Token URI Frozen');
        }
        URL = newURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _createTokenURI(uint256 id) private view returns (string memory) {
        string memory url = string(abi.encodePacked(URL, Strings.toString(id), ".json"));
        return(url);
    }

    //enter uri as above ex. "https://.../CID_HERE/" "ipfs://.../CID_HERE/"      "/" at the end is important
    function setTokenURI(uint256 startId, uint256 endId, string memory Newuri) external onlyOwner {
        if (frozen == true){
            revert('Token URI Frozen');
        }
        for (uint256 i = startId; i <= endId; i++) {
            string memory pointer = string(abi.encodePacked(Newuri, Strings.toString(i), ".json"));
            _setTokenURI(i, pointer);
        }
    }

    function getBalance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    function withdraw(address payable _to) external onlyOwner{
        _to.transfer(getBalance());
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}