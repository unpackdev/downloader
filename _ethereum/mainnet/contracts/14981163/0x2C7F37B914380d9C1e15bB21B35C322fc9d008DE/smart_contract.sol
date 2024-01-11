//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract CosmoGang is ERC721A, Ownable {
    address public constant MAIN_ADDRESS = 0x9C21c877B44eBac7F0E8Ee99dB4ebFD4A9Ac5000;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_WALLET = 5;
    // string public constant PLACEHOLDER_URI = "https://infura-ipfs.io/ipfs/QmZ4oaUmJqXuVCZJAPQCfmkKyjv4muC1DS7d8hFu1meDEn";
    // string public constant PLACEHOLDER_URI = "ipfs://infura-ipfs.io/ipfs/QmP1c2YSBYPmLNGSeC7S91u9isPi1RUt3PP4QVjphaEpJX";
    string public constant PLACEHOLDER_URI = "https://bafybeih6b2d4aqvcsw6sv3cu2pi3doldwa4lq42w34ismwvfrictsod5nu.ipfs.infura-ipfs.io/";

    enum Faction {None, Jahjahrion, Breedorok, Foodrak, Pimpmyridian,
        Muskarion, Lamborgardoz, Schumarian, Creatron}

    uint256 public price = 0 ether;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public current_supply = 2000;
    uint256[] public _tokenIdsList;
    mapping (uint256 => string) public tokenURIs;
    mapping (uint256 => address) private _tokenOwners;
    mapping (uint256 => Faction) public tokenFactions;
    address[] public holders;
    address[] public whitelist;
    mapping(string => uint8) public hashes;
    bool public isMinting = false;
    mapping(address => uint) private balance;
    mapping(address => uint) private presaleAmount;

    constructor() ERC721A("TheCosmoGang", "CG")
    {
        // Minting for availability on OpenSea beofre any mint
        _safeMint(address(this), 1);
        _burn(0);
    }

    function startMinting()
        public onlyOwner
    {
        require(!isMinting, "Minting already started");
        if (!isMinting)
        {
            isMinting = true;
        }
    }

    function stopMinting()
        public onlyOwner
    {
        require(isMinting, "Minting hasn't start yet");
        if (isMinting)
        {
            isMinting = false;
        }
    }

    // Mint Logic
    function _mintNFT(uint256 nMint, address recipient)
        private
        returns (uint256[] memory)
    {
        require(_tokenIds.current() + nMint <= MAX_SUPPLY, "No more NFT to mint");
        require(_tokenIds.current() + nMint <= current_supply, "No more NFT to mint currently");
        require(balanceOf(recipient) + nMint <= MAX_PER_WALLET, "Too much NFT minted");
        
        current_supply -= nMint;
        uint256[] memory newItemIds = new uint256[](nMint);

        for (uint256 i = 0; i < nMint; i++)
        {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(recipient, 1);
            _tokenOwners[newItemId] = recipient;
            _tokenIdsList.push(newItemId);
            setTokenURI(newItemId, PLACEHOLDER_URI, Faction.None);
            addHolder(recipient);

            newItemIds[i] = newItemId;
        }

        return newItemIds;
    }

    // Normal Mint
    function mintNFT(uint256 nMint, address recipient)
        public payable
        returns (uint256[] memory)
    {
        require(isMinting, "Mint period have not started yet");
        require(msg.value >= price * nMint, "Not enough ETH to mint");

        return _mintNFT(nMint, recipient);
    }

    // Free Mint
    function giveaway(uint256 nMint, address recipient)
        public onlyOwner
        returns (uint256[] memory)
    {
        return _mintNFT(nMint, recipient);
    }

    function burnNFT(uint256 tokenId)
        public onlyOwner
    {
        address owner = _tokenOwners[tokenId];
        _burn(tokenId);
        delete tokenURIs[tokenId];
        delete _tokenOwners[tokenId];
        delete _tokenIdsList[tokenId];

        uint256 remainingBalance = balanceOf(owner);
        if (remainingBalance <= 0)
        {
            removeHolder(owner);
        }
    }

    function setCurrentSupply(uint256 supply)
        public onlyOwner
    {
        require(getCurrentSupply() + supply <= MAX_SUPPLY, "Too much supply");
        current_supply = supply;
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
    {
        require(balanceOf(from) > 1, "Not enough NFT to send one");
        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI, Faction faction)
        public onlyOwner
        // override(ERC721)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
        tokenFactions[tokenId] = faction;
    }

    function updateTokenURI(uint256 tokenId, string memory _tokenURI, Faction faction)
        public onlyOwner
        // override(ERC721A)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
        tokenFactions[tokenId] = faction;
    }

    function setPrice(uint256 priceGwei)
        external onlyOwner
    {
        price = priceGwei * 10**9;
    }

    function getTokenIds()
        public view onlyOwner
        returns (uint256[] memory)
    {
        return _tokenIdsList;
    }
    
    function getTokenIdsOf(address addr)
        public view onlyOwner
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(addr);
        uint256[] memory tokenIds = new uint256[](count);
        uint256 foundTokens = 0;
        for (uint256 i; i < _tokenIdsList.length; i++)
        {
            uint256 tokenId = _tokenIdsList[i];
            if (_tokenOwners[tokenId] == addr)
            {
                tokenIds[foundTokens] = tokenId;
                foundTokens++;
            }
        }
    
        return tokenIds;
    }

    function getCurrentSupply()
        public view
        returns (uint256)
    {
        // return _tokenIds.current();
        return _tokenIdsList.length;
    }

    function addHolder(address addr)
        private
    {
        bool add_to_holders = true;
        for (uint256 i = 0; i < holders.length; i++)
        {
            if (holders[i] == addr)
            {
                add_to_holders = false;
            }
        }
        if (add_to_holders)
        {
            holders.push(addr);
        }
    }

    function removeHolder(address addr)
        private
    {
        uint256 balance_of_owner = balanceOf(addr);
        require(balance_of_owner != 0, "Can't remove holder since he still got some NFTs");

        uint256 idx_to_delete;
        for (uint256 i = 0; i < holders.length; i++)
        {
            if (holders[i] == addr)
            {
                idx_to_delete = i;
            }
        }
        delete holders[idx_to_delete];
    }

    function isHolder(address addr)
        public view
        returns (bool)
    {
        for (uint256 i = 0; i < holders.length; i++)
        {
            if (holders[i] == addr)
            {
                return true;
            }
        }
        return false;
    }

    function withdraw()
        public 
        payable
    {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        bool success = payable(MAIN_ADDRESS).send(amount);
        require(success, "Failed to withdraw");
    }

    function getETHBalance(address addr)
        public view
        returns (uint)
    {
        return addr.balance;
    }

    function random()
        public view
        returns (uint)
    {
        string memory difficulty = Strings.toString(block.difficulty);
        string memory timestamp = Strings.toString(block.timestamp);
        // string memory holdersstr = "";
        // for (uint i = 0; i < holders.length; i++)
        // {
        //     string memory stringAddr = string(abi.encodePacked(holders[i]));
        //     holdersstr = string(abi.encodePacked(holdersstr, stringAddr));
        // }

        // abi.encodePacked is used to concatenate strings and get the result in bytes
        // bytes memory key = abi.encodePacked(difficulty, timestamp, holdersstr);
        bytes memory key = abi.encodePacked(difficulty, timestamp);
        return uint(keccak256(key));
    }

    function getRandomHolder()
        public view
        returns (address)
    {
        uint idx = random() % holders.length;
        return holders[idx];
    }

    function getContractBalance()
        public view
        returns (uint256)
    {
        return address(this).balance;
    }

    receive()
        external payable
    {
        balance[msg.sender] += msg.value;
    }

    fallback()
        external
    {

    }
}