// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract UNYKORNZ is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_NFT = 7777;
    uint256 public constant RESERVE_NFT = 2000;
    uint256 public constant PUBLIC_NFT = MAX_NFT - RESERVE_NFT;
    
    uint256 public walletLimit = 2;
    uint256 public walletLimitWL = 2;

    uint256 public publicTotalSupply;

    string private baseURI;
    string private reserveURI;

    bool public isWhitelistActive;
    bool public isSaleActive;

    mapping(address => uint256) public claimed;
    mapping(address => uint256) public claimedWL;
    mapping(address => uint256[]) public giveaway;

    constructor() ERC721("UNYKORNZ", "UNKRN") {}

    function enableWhitelistSale() external onlyOwner {
        isWhitelistActive = true;
        isSaleActive = false;
    }
    function enableMainSale() external onlyOwner {
        isWhitelistActive = false;
        isSaleActive = true;
    }
    function disableSale() external onlyOwner {
        isWhitelistActive = false;
        isSaleActive = false;
    }
    function setWalletLimit(uint256 _walletLimit, uint256 _walletLimitWL) external onlyOwner {
        walletLimit = _walletLimit;
        walletLimitWL = _walletLimitWL;
    }
    function setURIs(string memory _reserveURI, string memory _URI) external onlyOwner {
        reserveURI = _reserveURI;
        baseURI = _URI;
    }
    function airdrop(address[] memory _to, uint256[] memory _tokenIds) external onlyOwner {
        require(_to.length == _tokenIds.length, "array size mismatch");
        
        for(uint256 i = 0; i < _to.length; i++) {
            require(_tokenIds[i] < RESERVE_NFT, "Id Invalid");
            _safeMint(_to[i], _tokenIds[i]);
        }
    }
    function airdrop(address _to, uint256[] memory _tokenIds) external onlyOwner {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] < RESERVE_NFT, "Id Invalid");
            _safeMint(_to, _tokenIds[i]);
        }
    }

    function mint(uint256 _numOfTokens) public whenNotPaused nonReentrant {
        require((publicTotalSupply + _numOfTokens) <= PUBLIC_NFT, "Purchase would exceed max NFTs");
        require(isWhitelistActive || isSaleActive, "Sale not Active");

        if (isWhitelistActive) {
            require((claimedWL[msg.sender] + _numOfTokens) <= walletLimitWL, "Above Purchase Limit");

            for(uint256 i = 0; i < _numOfTokens; i++) {
                _mint(msg.sender, RESERVE_NFT + publicTotalSupply);
                publicTotalSupply += 1;
            }

            claimedWL[msg.sender] = claimedWL[msg.sender] + _numOfTokens;

        } else {
            require(claimed[msg.sender] + _numOfTokens <= walletLimit, "Above Purchase Limit");

            for(uint256 i = 0; i < _numOfTokens; i++) {
                _mint(msg.sender, RESERVE_NFT + publicTotalSupply);
                publicTotalSupply += 1;
            }

            claimed[msg.sender] = claimed[msg.sender] + _numOfTokens; 
        }
    }

    function setGiveawayUsers(address[] memory _to, uint256[] memory _tokenIds) external onlyOwner {
        require(_to.length == _tokenIds.length, "array size mismatch");
        
        for(uint i = 0; i < _to.length; i++) {
            require(_tokenIds[i] < RESERVE_NFT, "Invalid TokenID");
            giveaway[_to[i]].push(_tokenIds[i]);
        }
    }

    function setGiveawayUser(address _to, uint256[] memory _tokenIds) external onlyOwner {
        giveaway[_to] = _tokenIds;

        for(uint i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] < RESERVE_NFT, "Invalid TokenID");
        }
    }

    // Function to claim giveaway
    function claimGiveaway() external {
        for(uint i=0; i < giveaway[msg.sender].length; i++) {
            _safeMint(msg.sender, giveaway[msg.sender][i]);
        }

        uint[] memory myArray;
        giveaway[msg.sender] = myArray;
    }
    
    // Function to get token URI of given token ID
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (_tokenId < RESERVE_NFT) {
            return string(abi.encodePacked(reserveURI, _tokenId.toString()));
        } else {
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
        }
    }

    // Function to pause 
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause 
    function unpause() external onlyOwner {
        _unpause();
    }
}