//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
// Creator : TheV

//  _______ __   __ _______    _______ _______ _______ __   __ _______    _______ _______ __    _ _______ 
// |       |  | |  |       |  |       |       |       |  |_|  |       |  |       |       |  |  | |       |
// |_     _|  |_|  |    ___|  |       |   _   |  _____|       |   _   |  |    ___|   _   |   |_| |    ___|
//   |   | |       |   |___   |      _|  | |  | |_____|       |  | |  |  |   | __|  |_|  |       |   | __ 
//   |   | |       |    ___|  |     | |  |_|  |_____  |       |  |_|  |  |   ||  |       |  _    |   ||  |
//   |   | |   _   |   |___   |     |_|       |_____| | ||_|| |       |  |   |_| |   _   | | |   |   |_| |
//   |___| |__| |__|_______|  |_______|_______|_______|_|   |_|_______|  |_______|__| |__|_|  |__|_______|

pragma solidity >=0.7.0;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract CosmoGang is ERC721A, Ownable {
    enum Faction {None, Jahjahrion, Breedorok, Foodrak, Pimpmyridian,
        Muskarion, Lamborgardoz, Schumarian, Creatron}
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 10000;
    mapping (uint256 => string) public tokenURIs;
    mapping (uint256 => Faction) public tokenFactions;
    uint256 public max_per_walet = 5;
    address public main_address = 0x9C21c877B44eBac7F0E8Ee99dB4ebFD4A9Ac5000;
    string public placeholder_uri = "https://bafybeih6b2d4aqvcsw6sv3cu2pi3doldwa4lq42w34ismwvfrictsod5nu.ipfs.infura-ipfs.io/";
    string public base_uri;
    bool public isMinting = false;
    bool public isRevealed = false;
    bool public isBaseUri = false;
    uint256 public price = 0 ether;
    uint256 public current_supply = 2000;

    constructor() ERC721A("TheCosmoGang", "CG")
    {
        // Minting for availability on OpenSea before any mint
        _safeMint(address(this), 1);
        _burn(0);
    }

    function toggleMintState()
        public onlyOwner
    {
        if (isMinting)
        {
            isMinting = false;
        }
        else
        {
            isMinting = true;
        }
    }

    function toggleRevealState()
        public onlyOwner
    {
        if (isRevealed)
        {
            isRevealed = false;
        }
        else
        {
            isRevealed = true;
        }
    }

    function toggleBaseUriState()
        public onlyOwner
    {
        if (isBaseUri)
        {
            isBaseUri = false;
        }
        else
        {
            isBaseUri = true;
        }
    }

    // Mint Logic
    function _mintNFT(uint256 nMint, address recipient)
        private
        returns (uint256[] memory)
    {
        require(_tokenIds.current() + nMint <= MAX_SUPPLY, "No more NFT to mint");
        require(_tokenIds.current() + nMint <= current_supply, "No more NFT to mint currently");
        require(balanceOf(recipient) + nMint <= max_per_walet, "Too much NFT minted");
        
        current_supply -= nMint;
        uint256[] memory newItemIds = new uint256[](nMint);

        for (uint256 i = 0; i < nMint; i++)
        {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            newItemIds[i] = newItemId;
        }
        _safeMint(recipient, nMint);
        // _mint(recipient, nMint);

        return newItemIds;
    }

    // Normal Mint
    function mintNFT(uint256 nMint, address recipient)
        external payable
        returns (uint256[] memory)
    {
        require(isMinting, "Mint period have not started yet");
        require(msg.value >= price * nMint, "Not enough ETH to mint");

        return _mintNFT(nMint, recipient);
    }

    // Free Mint
    function giveaway(uint256 nMint, address recipient)
        external onlyOwner
        returns (uint256[] memory)
    {
        return _mintNFT(nMint, recipient);
    }

    function burnNFT(uint256 tokenId)
        external onlyOwner
    {
        _burn(tokenId);
        delete tokenURIs[tokenId];
    }

    function setCurrentSupply(uint256 supply)
        external onlyOwner
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
        if (isRevealed)
        {
            if (isBaseUri)
            {
                return string(abi.encodePacked(abi.encodePacked(abi.encodePacked(base_uri, "/"), Strings.toString(tokenId)), ".json"));
            }
            else
            {
                return tokenURIs[tokenId];
            }
            
        }
        else
        {
            return placeholder_uri;
        }
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI, Faction faction)
        private
        // override(ERC721)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
        tokenFactions[tokenId] = faction;
    }

    function updateTokenURI(uint256 tokenId, string memory _tokenURI, Faction faction)
        external onlyOwner
        // override(ERC721A)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
        tokenFactions[tokenId] = faction;
    }

    function updateAllTokenURIs(uint256[] memory tokenIds, string[] memory _tokenURIs, Faction[] memory factions)
        external onlyOwner
        // override(ERC721A)
    {
        mapping(uint256 => string) storage tempTokenURIs = tokenURIs;
        mapping(uint256 => Faction) storage tempTokenFactions = tokenFactions;
        for (uint256 idx = 0; idx <= tokenIds.length; idx++)
        {
            uint256 tokenId = tokenIds[idx];
            string memory _tokenURI = _tokenURIs[idx];
            Faction tokenFaction = factions[idx];
            require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
            tempTokenURIs[tokenId] = _tokenURI;
            tempTokenFactions[tokenId] = tokenFaction;
        }
    }

    function setFaction(uint256 tokenId, Faction _faction)
        external onlyOwner
    {
        tokenFactions[tokenId] = _faction;
    }
    
    function setPrice(uint256 priceGwei)
        external onlyOwner
    {
        price = priceGwei * 10**9;
    }

    function setPlaceholderUri(string memory _placeholder_uri)
        external onlyOwner
    {
        placeholder_uri = _placeholder_uri;
    }

    function setBaseUri(string memory _base_uri)
        external onlyOwner
    {
        base_uri = _base_uri;
    }

    function setMaxPerWallet(uint256 _max_per_wallet)
        external onlyOwner
    {
        max_per_walet = _max_per_wallet;
    }

    function setMainAddress(address _main_address)
        external onlyOwner
    {
        main_address = _main_address;
    }

    function getTokenIds()
        external view onlyOwner
        returns (uint256[] memory)
    {   
        uint256 idx = 0;
        uint256 totalSupply = totalSupply();
        uint256[] memory tokenIds = new uint256[](totalSupply);
        for (uint256 i; i <= _tokenIds.current(); i++)
        {
            if (_exists(i))
            {
                tokenIds[idx] = i;
                idx++;
            }
        }
        return tokenIds;
    }
    
    function getTokenIdsOf(address addr)
        external view onlyOwner
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(addr);
        uint256[] memory tokenIds = new uint256[](count);
        uint256 foundTokens = 0;
        for (uint256 i; i <= _tokenIds.current(); i++)
        {
            if (_exists(i))
            {
                if (ownerOf(i) == addr)
                {
                    tokenIds[foundTokens] = i;
                    foundTokens++;
                }
            }
        }
    
        return tokenIds;
    }

    function getHolders()
        external view onlyOwner
        returns (address[] memory)
    {
        uint256 supply = getCurrentSupply();
        address[] memory holders = new address[](supply);
        uint256 idx = 0;
        for (uint256 i; i <= _tokenIds.current(); i++)
        {
            if (_exists(i))
            {
                address holder = ownerOf(i);
                bool alreadyAdded = false;
                for (uint256 j; j < holders.length; j++)
                {
                    if (holders[j] == holder)
                    {
                        alreadyAdded = true;
                    }
                }
                if (!alreadyAdded)
                {
                    holders[idx] = holder;
                    idx++;
                }
            }
        }

        return holders;
    }

    function getCurrentSupply()
        public view
        returns (uint256)
    {
        return totalSupply();
    }

    function isHolder(address addr)
        public view
        returns (bool)
    {
        return balanceOf(addr) > 0;
    }

    function withdraw()
        public 
        payable
    {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        bool success = payable(main_address).send(amount);
        require(success, "Failed to withdraw");
    }

    function getETHBalance(address addr)
        public view
        returns (uint)
    {
        return addr.balance;
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
        // balance[msg.sender] += msg.value;
    }

    fallback()
        external
    {

    }
}