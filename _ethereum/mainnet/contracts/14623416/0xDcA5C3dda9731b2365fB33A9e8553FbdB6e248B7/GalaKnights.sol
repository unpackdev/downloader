// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract GalaKnights is ERC721, ERC721Royalty, Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;

    // Constants

    uint128 public constant MAX_PURCHASE_AMOUNT = 10;
    uint128 public constant MAX_SUPPLY = 5000;
    string public constant PROVENANCE_HASH = "b5df6f6d2763ca8444168bb863612e11714af14ba8f085ed047562b06dee473a";
    uint256 public constant TOKEN_PRICE = 0.05 ether;

    // Public variables

    bool public isOnSale = false;
    string public baseTokenURI;
    uint256 public revealTimestamp;
    uint256 public startingIndex;
    uint256 public startingIndexBlock;
    address public withdrawalAddress;
    
    // Private variables

    string private _contractURI;
    Counters.Counter private _currentTokenId;

    // Constructor

    constructor(address _withdrawalAddress,
                uint96 royaltyFee,
                uint256 _revealTimestamp,
                string memory _baseTokenURI,
                string memory _initialContractURI) ERC721("GalaKnights", "KNIGHT") {
        withdrawalAddress = _withdrawalAddress;
        baseTokenURI = _baseTokenURI;
        _contractURI = _initialContractURI;
        _setDefaultRoyalty(_withdrawalAddress, royaltyFee);
        revealTimestamp = _revealTimestamp;
    }

    // Accessors

    function setIsOnSale(bool _isOnSale) public onlyOwner {
        isOnSale = _isOnSale;
    }

    function setWithdrawalAddress(address _withdrawalAddress) public onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    function setRevealTimestamp(uint256 _revealTimestamp) public onlyOwner {
        revealTimestamp = _revealTimestamp;
    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId.current();
    }

    // Metadata

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    // Minting

    function mintToken(uint256 tokenCount) public payable nonReentrant {
        address sender = _msgSender();

        require(isOnSale, "Not on sale");
        uint256 senderBalance = balanceOf(sender);
        require(tokenCount <= MAX_PURCHASE_AMOUNT - senderBalance, "No mints remaining");
        uint256 totalCost = TOKEN_PRICE * tokenCount;
        require(totalCost == msg.value, "Not the right amount of ether");

        _finalMint(sender, tokenCount);
    }

	function ownerMintToken(uint256 tokenCount) public onlyOwner {
    	_finalMint(_msgSender(), tokenCount);
  	}

    function _finalMint(address to, uint256 tokenCount) private {
        require(_currentTokenId.current() + tokenCount <= MAX_SUPPLY, "Will exceed maximum supply");

        for (uint256 i = 1; i <= tokenCount; i++) {
            _currentTokenId.increment();
            _safeMint(to, _currentTokenId.current());
        }

		if (startingIndexBlock == 0 && (_currentTokenId.current() == MAX_SUPPLY || block.timestamp >= revealTimestamp)) {
            startingIndexBlock = block.number;
        }
    }

    // Starting Index

    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        // Just in case this function is called late (EVM only stores last 256 block hashes)
        if ((block.number - startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_SUPPLY;
        }
        else {
            startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0 || startingIndex == 1) {
            startingIndex = startingIndex + 2;
        }
    }

    // In case startingIndex was not set automatically
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    // Withdraw

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(withdrawalAddress).transfer(balance);
	}

    // Royalties

    function setRoyalties(address recipient, uint96 fraction) external onlyOwner {
        _setDefaultRoyalty(recipient, fraction);
    }

    // ERC721Royalty overrides

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}
