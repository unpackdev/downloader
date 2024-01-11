// SPDX-License-Identifier: GPL-3.0
///@consensys SWC-103
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract RugRatz is ERC721Enumerable, Ownable {

    using Strings for uint256;
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    string public baseURI;
    string public baseExtension     = ".json";
    string public metaDataFolder    = "";
    string public notRevealedUri    = "https://rugratznft.mypinata.cloud/ipfs/QmW5ip3ypJ4zXnkkEuyEi3bGkNhrtvA8D6TW39hZL4kyzB/1.json";
    string public _name;
    string public _symbol;
    string public _initBaseURI;

    uint256 public cost             =   0.099 ether;    
    uint256 public maxSupply        =   2500;
    uint256 public remainTokenAmount=   2500;

    uint256 public nftPerAddressLimit=  1;
    uint256 public maxMintAmount    =   1;   

    uint256 public revealed            = 0;
    bool public paused              = false;
	address private Owner;   
    mapping(address => uint256) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        Owner = owner();
    }

    // internal
    // convenience function to return the baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Mint is paused");
        require(msg.sender != address(0x0), "Recipient should be present");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(remainTokenAmount > 0, "Max NFT limit exceeded");

        if (msg.sender != owner()) {
            //if owner change cost then frontend must be changed
            require(msg.value != 0, "Royalty value should be positive" );
            require(msg.value >= cost * _mintAmount, "Insufficient funds");
            require(_mintAmount <= maxMintAmount, "Max mint amount per session exceeded");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit,    "Max NFT per address exceeded");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            addressMintedBalance[msg.sender]++;
            remainTokenAmount--;
        }
    }

    // return all NFTs for a particular owner
    function tokenOfwallet(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if(revealed == 0) return notRevealedUri;
    
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, baseExtension));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    //to be seen how many collections are minted and remained in frontend 
    function getRemainCollections() public view returns (uint256) {
        return remainTokenAmount;
    }

    //to be seen how many nfts user minted and can mint
    function getRemainNFTforUser(address user) public view returns (uint256) {
        uint256 amount;
        if (user != owner()) {
            amount = nftPerAddressLimit - addressMintedBalance[user];
        }else {
            amount = 50;
        }
        return amount;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    //only owner
    function reveal(uint256 _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setRevealedURI(string memory _RevealedURI) public onlyOwner {
        reveal(1); setBaseURI(_RevealedURI);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }


    function withdraw() public payable onlyOwner {
        // This will pay operater 7% of the initial sale.
        // You can remove this if you want, or keep it in to operater and his channel.
        // =============================================================================
        (bool op, ) = payable(0x9660C846fA92C99B420770d4Ae1d1b6354203354).call{
            value: (address(this).balance * 7) / 100
        }("");
        require(op);
        // =============================================================================

        // This will payout the owner 93% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(Owner).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}