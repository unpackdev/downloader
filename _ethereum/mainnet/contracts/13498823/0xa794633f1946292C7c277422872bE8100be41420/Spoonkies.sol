// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract Spoonkies is ERC721, ReentrancyGuard, Ownable {
    using Strings for uint256;

    ERC721 public nProject;

    uint256 public constant PRICE = 10000000000000000; // 0.01 ETH
    uint256 public constant MAX_SUPPLY = 888;

    enum MintingState {
        Pre,
        Public,
        Closed
    }
    MintingState public mintingState = MintingState.Closed;

    string private customBaseURI;
    string private customUniqueBaseURI;

    uint256[] private _uniqueTokens;
    uint256[] private _allTokens;

    constructor(
        string memory name,
        string memory symbol,
        address nProjectAddress,
        string memory baseUri,
        string memory uniqueBaseUri
    ) ERC721(name, symbol) {
        nProject = ERC721(nProjectAddress);
        customBaseURI = baseUri;
        customUniqueBaseURI = uniqueBaseUri;
    }

    function multiMint(uint256[] calldata tokenIds) public payable nonReentrant {
        address minter = msg.sender;

        require(mintingState != MintingState.Closed, "Spoonkies:MINT_DISABLED");

        uint256 tokenCount = tokenIds.length;
        require(_allTokens.length + tokenCount <= MAX_SUPPLY, "Spoonkies:MAX_SUPPLY_REACHED");

        require(msg.value >= tokenCount * PRICE, "Spoonkies:INVALID_PRICE");

        for (uint256 i = 0; i < tokenCount; i++) {
            require(tokenIds[i] > 0 && tokenIds[i] <= 8888, "Spoonkies:INVALID_TOKEN");
            require(
                mintingState != MintingState.Pre || nProject.ownerOf(tokenIds[i]) == minter,
                "Spoonkies:INVALID_OWNER"
            );
            require(!_exists(tokenIds[i]), "Spoonkies:ALREADY_MINTED");
            if (_uniqueTokens.length < 5 && random() < 2) {
                _uniqueTokens.push(tokenIds[i]);
            }
            _allTokens.push(tokenIds[i]);
            _safeMint(minter, tokenIds[i]);
        }
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        address minter = msg.sender;
        require(mintingState != MintingState.Closed, "Spoonkies:MINT_DISABLED");
        require(_allTokens.length + 1 <= MAX_SUPPLY, "Spoonkies:MAX_SUPPLY_REACHED");
        require(msg.value >= PRICE, "Spoonkies:INVALID_PRICE");
        require(tokenId > 0 && tokenId <= 8888, "Spoonkies:INVALID_TOKEN");
        require(
            mintingState != MintingState.Pre || nProject.ownerOf(tokenId) == minter,
            "Spoonkies:INVALID_OWNER"
        );
        require(!_exists(tokenId), "Spoonkies:ALREADY_MINTED");
        if (_uniqueTokens.length < 5 && random() < 2) {
            _uniqueTokens.push(tokenId);
        }
        _allTokens.push(tokenId);
        _safeMint(minter, tokenId);
    }

    function ownerMint(uint256[] calldata tokenIds) public onlyOwner nonReentrant {
        address minter = msg.sender;

        uint256 tokenCount = tokenIds.length;
        require(_allTokens.length + tokenCount <= MAX_SUPPLY, "Spoonkies:MAX_SUPPLY_REACHED");

        for (uint256 i = 0; i < tokenCount; i++) {
            require(tokenIds[i] >= 0 && tokenIds[i] <= 8888, "Spoonkies:INVALID_TOKEN");
            require(!_exists(tokenIds[i]), "Spoonkies:ALREADY_MINTED");
            _allTokens.push(tokenIds[i]);
            _safeMint(minter, tokenIds[i]);
        }
    }

    function setMintingState(bool active, bool pre) public onlyOwner {
        if (!active) {
            mintingState = MintingState.Closed;
        } else {
            if (pre) {
                mintingState = MintingState.Pre;
            } else {
                mintingState = MintingState.Public;
            }
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        customBaseURI = baseURI;
    }

    function setUniqueBaseURI(string memory uniqueBaseURI) external onlyOwner {
        customUniqueBaseURI = uniqueBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function setNProjectAddress(address _address) public onlyOwner {
        nProject = ERC721(_address);
    }

    function random() private view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 100;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        for (uint i = 0; i < _uniqueTokens.length; i++) {
            if (tokenId == _uniqueTokens[i]) {
                return bytes(customUniqueBaseURI).length > 0 ? string(abi.encodePacked(customUniqueBaseURI, (i + 1).toString())) : "";
            }
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function isTokenUnique(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        for (uint i = 0; i < _uniqueTokens.length; i++) {
            if (tokenId == _uniqueTokens[i]) {
                return true;
            }
        }

        return false;
    }
}
