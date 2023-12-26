// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*
▀█▀ █░█ █▀▀   ░░█ █▀█ █▀▀ █▀
░█░ █▀█ ██▄   █▄█ █▄█ ██▄ ▄█

Twitter: https://twitter.com/TheCryptoJoes
Mint Website: https://thejoes.xyz/
*/

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheJoes is ERC721A, Ownable{


    uint256 public maxSupply = 3333;
    uint256 public mintPrice = 0.003 ether;
    uint256 public maxPerTxn = 11;
    uint256 public maxFree = 1;
    string public baseExtension = ".json";
    string public baseURI;
    bool public mintEnabled;

    constructor (
    string memory _initBaseURI) 
    ERC721A("The Joes", "JOES") {
        setBaseURI(_initBaseURI);
        _safeMint(msg.sender, 10);
    }

    function teamMint(address[] calldata _address, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Max supply reached");
        for (uint i = 0; i < _address.length; i++) {
            _safeMint(_address[i], _amount);
        }
    }

    function mint(uint256 _quantity) external payable {
        uint256 previous = _getAux(_msgSender());  
        require(_quantity <= maxPerTxn, "Cannot mint more than max per txn");
        require(mintEnabled, "Mint is not live");
        require(tx.origin == msg.sender, "No contracts");
        require(totalSupply() + _quantity <= maxSupply, "Max supply reached");
        
        uint256 freeNFT = previous >= maxFree
        ? 0
        : maxFree - previous;
        uint256 paidNFT = _quantity > freeNFT
        ? _quantity - freeNFT
        : 0;
        
        require(msg.value >= mintPrice * paidNFT, "Not enough ether sent");

        _setAux(_msgSender(), uint64(previous += _quantity));
        _safeMint(msg.sender, _quantity);
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // override _statTokenId() from erc721a to start tokenId at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // return tokenUri given the tokenId
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
        
    }


    function amountMinted(address wallet) external view returns (uint256) {
        return _getAux(wallet);
    }

    function toggleMint() external onlyOwner{
        mintEnabled = !mintEnabled;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner{
        mintPrice = _mintPrice;
    }

    function setMaxFree(uint256 _maxFree) external onlyOwner{
        maxFree = _maxFree;
    }

    function setMaxPerTxn(uint256 _maxPerTxn) external onlyOwner{
        maxPerTxn = _maxPerTxn;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newURI) public onlyOwner{
        baseURI = _newURI;
    }


    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed !");
    }
}