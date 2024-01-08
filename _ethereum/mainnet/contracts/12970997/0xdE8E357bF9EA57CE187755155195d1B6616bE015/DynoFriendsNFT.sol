// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./DynoFriendsBase.sol";
import "./ERC721Enumerable.sol";

contract DynoFriendsNFT is ERC721Enumerable, DynoFriendsBase {

    // Receive the ETH collected
    address payable public _beneficiary;

    string public _baseTokenURI;

    uint256 public _burnCount = 0; // count the number of burnt tokens
    
    uint256 public _tokenPrice = 0.04 ether;

    uint256 public _maxSupply = 4400;

    event EventMint(address _to, uint256 _num, uint256 _ethAmount);
    
    constructor(string memory baseURI_, address beneficiary_) ERC721("Dyno Friends", "DYFR")  {
        _baseTokenURI = baseURI_;
        _beneficiary = payable(beneficiary_);
    }

    // Apply pausable for token transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "DynoFriendsNFT: token transfer while paused");
    }

    function tokenExists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }

    function burn(uint256 tokenId_) external whenNotPaused() {
        require(ownerOf(tokenId_) == _msgSender(), "DynoFriendsNFT: Not token owner");
        _burn(tokenId_);
        _burnCount += 1;
    }

    function adminBurn(uint256 tokenId_)
        external
        whenNotPaused()
        isAuthorized()
    {
        _burn(tokenId_);
        _burnCount += 1;
    }

    function mint(uint256 num) external payable whenNotPaused()  {
        uint256 supply = totalSupply();
        require(supply + num <= _maxSupply, "DynoFriendsNFT: Exceeds maximum supply");
        require(msg.value >= _tokenPrice * num, "DynoFriendsNFT: Sent ETH is not enough");

        // mint
        for (uint256 i = 0; i < num; i++) {
            _safeMint( msg.sender, supply + i );
        }

        // transfer ETH to the beneficiary
        _beneficiary.transfer(msg.value);

        emit EventMint(msg.sender, num, msg.value);
    }

    function adminMintBatch(address[] calldata addrList) external isOwner()  {
        uint256 num =  addrList.length;
        uint256 supply = totalSupply();
        require(supply + num <= _maxSupply, "DynoFriendsNFT: Exceeds maximum supply");

        // mint
        for (uint256 i = 0; i < num; i++) {
            _safeMint( addrList[i], supply + i );
        }
    }

    // Return the tokenIds owned by a given user wallet address
    function getTokenIdsOfUserAddress(address _userAddr) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_userAddr);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for(uint256 i = 0; i < tokenCount; i++){
            tokenIds[i] = tokenOfOwnerByIndex(_userAddr, i);
        }
        return tokenIds;
    }

    function setPrice(uint256 _newPrice) external isOwner() {
        _tokenPrice = _newPrice;
    }

    function setMaxSupply(uint256 _newMaxSupply) external isOwner() {
        _maxSupply = _newMaxSupply;
    }

    function getPrice() external view returns (uint256){
        return _tokenPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external isOwner() {
        _baseTokenURI = baseURI;
    }

    function setBeneficiary(address beneficiary_) external isOwner() {
        _beneficiary = payable(beneficiary_);
    }
}