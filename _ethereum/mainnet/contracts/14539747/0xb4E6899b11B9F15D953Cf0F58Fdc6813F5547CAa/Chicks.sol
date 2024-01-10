// SPDX-License-Identifier: GPL-3.0
///@consensys SWC-103
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Chicks is ERC721Enumerable, Ownable {
    //For nft staking.
    mapping(uint256 => address) public _ownedTokens;

    // Optional mapping for token URIs  
    mapping (uint256 => string) private _tokenURIs;
    string private baseURI;
    string public baseExtension     = ".json";
    string public metaDataFolder    = "";
    string public notRevealedUri    =  "";
    string public _name;
    string public _symbol;

    uint256 public cost             =   0.0499 ether;    
    uint256 public maxSupply        =   10000;
    uint256 public remainTokenAmount=   10000;
    uint256 public maxMintAmount    =   100;   
    uint256 public nftPerAddressLimit=  100;
    uint256 public onlyWhitelisted     = 0;
    uint256 public revealed            = 1;
    uint256 public paused              = 0;

    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // internal
    // convenience function to return the baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(paused == 0, "Mint is paused");
        require(msg.sender != address(0x0), "Recipient should be present");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(remainTokenAmount > 0, "Max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (onlyWhitelisted == 1) {
                require(isWhitelisted(msg.sender), "User is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                    "Max NFT per address exceeded"
                );
            }
            //if owner change cost then frontend must be changed
            require(msg.value != 0, "Royalty value should be positive" );
            require(msg.value >= cost * _mintAmount, "Insufficient funds");
            require(_mintAmount <= maxMintAmount, "Max mint amount per session exceeded");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            addressMintedBalance[msg.sender]++;
            remainTokenAmount--;
        }
        if(remainTokenAmount % 1000 == 0){
            paused = 1;
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    // return all NFTs for a particular owner
    function walletOfOwner(address _owner)
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
        return string(abi.encodePacked(base, Strings.toString(tokenId), baseExtension));
    }


    //to be seen how many collections are minted and remained in frontend 
    function setRareTokenURL(uint256 tokenId, string memory _rareURI)  public onlyOwner {
        _tokenURIs[tokenId] = _rareURI;
    }

    //to be seen how many collections are minted and remained in frontend 
    function getRemainCollections() public view returns (uint256) {
        return remainTokenAmount;
    }

    function setRemainCollections(uint256 remainNFT) public onlyOwner{
        remainTokenAmount = remainNFT;
    }
    //to be seen how many nfts user minted and can mint
    function getRemainNFTforUser() public view returns (uint256) {
        uint256 amount;
        if (msg.sender != owner()) {
            amount = nftPerAddressLimit - addressMintedBalance[msg.sender];
        }else {
            amount = 200;
        }
        return amount;
    }       

    //only owner
    function reveal() public onlyOwner {
        revealed = 1;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
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

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        if(_state) paused = 1;
        else paused = 0;
    }

    function isPaused() public view returns (uint256) {
        return paused;
    }

    function setOnlyWhitelisted(uint256 _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
        } else if (from != to) {
            delete _ownedTokens[tokenId] ;
        }

        if (to == address(0)) {
        } else if (to != from) {
            _ownedTokens[tokenId] = to;
        }
    }

    function getNFTUser (uint256 tokenId) public view returns (address) {
        if(_ownedTokens[tokenId] == address(0)) return owner();
        return _ownedTokens[tokenId];
    }

    function withdraw() public payable onlyOwner {
        // This will pay operater 10% of the initial sale.
        // You can remove this if you want, or keep it in to operater and his channel.
        // =============================================================================
        (bool op, ) = payable(0x9660C846fA92C99B420770d4Ae1d1b6354203354).call{
            value: (address(this).balance * 10) / 100
        }("");
        require(op);
        // =============================================================================

        // This will payout the owner 90% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}
 