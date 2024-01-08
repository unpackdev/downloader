// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721B.sol";
import "./Ownable.sol";
import "./Strings.sol";
/**
 * @title CryptoSea Friends contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

interface IFreeFromUpTo {
    function freeUpTo(uint256 value) external returns (uint256);
    function freeFrom(address from, uint256 value) external returns (uint256);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}


contract CryptoSeaFriends is Ownable, ERC721B {
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    using Strings for uint256;

    string private _tokenBaseURI;

    uint256 public mintPrice;
    uint256 public maxMintAmountPerTX;
    uint256 public MAX_CSF_SUPPLY;

    bool public isPresale = true;
    bool public isSale;

    mapping (address => bool) public whitelist;
    address private wallet1 = 0xB6EF1661d0bBD987AAab23bAa1752A236d8Ab785;
    address private wallet2 = 0xC0f501636659b483aA0f00FEBD933d1fb3c8CeBE;

    modifier discountCHI(uint256 chiAmount) {
        if (chiAmount > 0) {
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            uint256 minAmount = Math.min((gasSpent + 14154) / 41947, chiAmount);
            // TokenInterface(address(chi)).approve(address(this), minAmount);
            // chi.freeFromUpTo(_msgSender(), Math.min((gasSpent + 14154) / 41947, chiAmount));
            chi.freeUpTo(minAmount);
        } else {
            _;
        }
    }

    constructor() ERC721B("CryptoSea Friends", "CSF") {
        MAX_CSF_SUPPLY = 5555;
        mintPrice = 0.05 ether;
        maxMintAmountPerTX = 7;
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Set mint price for a CryptoSea Friend.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * Set maximum count to mint per one tx.
     */
    function setMaxToMintPerTX(uint256 _maxMintAmountPerTX) external onlyOwner {
        maxMintAmountPerTX = _maxMintAmountPerTX;
    }

    /*
    * Set base URI
    */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    /*
    * Set sale status
    */
    function setSaleStatus(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    /*
    * Set presale status
    */
    function changePresaleStatus(bool _isPresale) external onlyOwner {
        isPresale = _isPresale;
    }

    /*
    * Whitelist wallets
    */
    function addWhitelist(address[] memory walletList) external onlyOwner {
        for (uint i=0; i<walletList.length; i++) {
            whitelist[walletList[i]] = true;
        }
    }

    /**
     * Reserve CryptoSea Friend by owner
     */
    function reserveCSF(address to, uint256 count)
        external
        onlyOwner
        discountCHI(count * 5)
    {
        require(to != address(0), "Invalid address to reserve.");

        uint256 supply = _owners.length;
        require(supply + count <= MAX_CSF_SUPPLY, "Reserve would exceed max supply");
        
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, supply++ );
        }
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    } 

    /**
    * Mint CryptoSea Friend
    */
    function mintCSF(uint256 count)
        external
        payable
        discountCHI(count * 5)
    {
        require(isSale, "Sale must be active to mint");
        require(count <= maxMintAmountPerTX, "Invalid amount to mint per tx");
        require(mintPrice * count <= msg.value, "Ether value sent is not correct");
        require(isPresale || whitelist[_msgSender()], "You are not in whitelist.");
        
        uint256 supply = _owners.length;
        require(supply + count <= MAX_CSF_SUPPLY, "Purchase would exceed max supply");
        for(uint256 i = 0; i < count; i++) {
           _mint( msg.sender, supply++);
        }
    }

    function withdraw() external onlyOwner {
        payable(wallet1).transfer(address(this).balance * 30 / 100);
        payable(wallet2).transfer(address(this).balance);
    }
}