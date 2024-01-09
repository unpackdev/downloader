// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";

/**
 * @title Mythology Apes Club contract
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

contract MAC is ERC721Burnable {
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    using SafeMath for uint256;

    uint256 public mintPrice;
    uint16 public MAX_MAC_SUPPLY;
    uint16 public currentMintCount;
    uint16 public PRE_MINT_MAX_COUNT = 5;
    uint16 public PUBLIC_MINT_MAX_COUNT = 10;

    bool public isSale;
    bool public isPublicSale = false;

    mapping (address => uint16) public whitelistMintCount;
    mapping (address => uint16) public publicMintCount;

    address private wallet1 = 0x9F12a303B2036F866b477c0Af5065CD867c89D4F;
    address private wallet2 = 0xB6EF1661d0bBD987AAab23bAa1752A236d8Ab785;
    address private wallet3 = 0x03AC925F26dB253be752b8f4AE55EFeBA036fF8b;
    address private admin = 0x536054D3E91BaE0b09aabAF28AbaBC0b6eF685B7;

    string public constant CONTRACT_NAME = "Mythology Apes Club Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant PREMINT_TYPEHASH = keccak256("PreMint(address user,uint16 count)");

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

    constructor() ERC721("Mythology Apes Club", "MAC") {
        MAX_MAC_SUPPLY = 7777;
        mintPrice = 0.0666 ether;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Set mint price for a Mythology Apes Club.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /*
    * Set base URI
    */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Set sale status
    */
    function setSaleStatus(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    /*
    * Set public sale status
    */
    function setPublicSaleStatus(bool _isPublicSale) external onlyOwner {
        isPublicSale = _isPublicSale;
    }

    /*
    * Set pre mint max count
    */
    function setPreMintLimit(uint16 _preMintMaxCount) external onlyOwner {
        PRE_MINT_MAX_COUNT = _preMintMaxCount;
    }

    /*
    * Set public mint max count
    */
    function setPublicMintLimit(uint16 _publicMintMaxCount) external onlyOwner {
        PUBLIC_MINT_MAX_COUNT = _publicMintMaxCount;
    }

    /**
     * Reserve Mythology Apes Club by owner
     */
    function reserveMAC(address to, uint16 count)
        external
        onlyOwner
        discountCHI(count * 5)
    {
        require(to != address(0), "Invalid address to reserve.");
        require(currentMintCount + count <= MAX_MAC_SUPPLY, "Reserve would exceed max supply");
        
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, currentMintCount + i);
        }

        currentMintCount = currentMintCount + count;
    }

    /**
    * Mint Mythology Apes Club
    */
    function mintMAC(uint16 count)
        external
        payable
        discountCHI(count * 5)
    {
        require(isSale, "Sale must be active to mint");
        require(isPublicSale, "Presale is not over yet.");
        require(publicMintCount[msg.sender] + count <= PUBLIC_MINT_MAX_COUNT, "Exceed max mintable count");
        require(currentMintCount + count <= MAX_MAC_SUPPLY, "Purchase would exceed max supply");        
        require(mintPrice.mul(count) <= msg.value, "Ether value sent is not correct");
        
        for(uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, currentMintCount + i);
        }

        currentMintCount = currentMintCount + count;
        publicMintCount[msg.sender] = publicMintCount[msg.sender] + count;
    }

    /**
    * Pre Mint for whitelist user
    */
    function preMintMAC(uint16 count, uint8 v, bytes32 r, bytes32 s)
        external
        payable
        discountCHI(count * 5)
    {
        require(isSale, "Sale must be active to mint");
        require(!isPublicSale, "Presale is over.");
        require(tx.origin == msg.sender, "Only EOA");
        require(currentMintCount + count <= MAX_MAC_SUPPLY, "Exceed max supply");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PREMINT_TYPEHASH, msg.sender, count));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        require(whitelistMintCount[msg.sender] + count <= PRE_MINT_MAX_COUNT, "Exceed max premintable count");
        require(mintPrice.mul(count) <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, currentMintCount + i);
        }

        currentMintCount = currentMintCount + count;
        whitelistMintCount[msg.sender] = whitelistMintCount[msg.sender] + count;
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function withdraw() external onlyOwner {
        uint256 balance1 = address(this).balance * 70 / 100;
        uint256 balance2 = address(this).balance * 23 / 100;
        payable(wallet1).transfer(balance1);
        payable(wallet2).transfer(balance2);
        payable(wallet3).transfer(address(this).balance);
    }
}