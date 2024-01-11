// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract SMS is ERC721, ERC721Royalty, Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;

    // Constants

    uint128 public constant MAX_PURCHASE_AMOUNT = 1;
    uint128 public constant MAX_SUPPLY = 5000;
    uint256 public constant TOKEN_PRICE = 1 ether;

    // Public variables

    bool public isOnSale = false;
    string public baseTokenURI;
    address public withdrawalAddress;
    
    // Private variables

    string private _contractURI;
    Counters.Counter private _currentTokenId;

    // Constructor

    constructor(address _withdrawalAddress,
                uint96 royaltyFee,
                string memory _baseTokenURI,
                string memory _initialContractURI) ERC721("SuperMegaStudios", "SMS") {
        withdrawalAddress = _withdrawalAddress;
        baseTokenURI = _baseTokenURI;
        _contractURI = _initialContractURI;
        _setDefaultRoyalty(_withdrawalAddress, royaltyFee);
    }

    // Accessors

    function setIsOnSale(bool _isOnSale) public onlyOwner {
        isOnSale = _isOnSale;
    }

    function setWithdrawalAddress(address _withdrawalAddress) public onlyOwner {
        withdrawalAddress = _withdrawalAddress;
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

	function airdrop(address to, uint256 tokenCount) public onlyOwner {
    	_finalMint(to, tokenCount);
  	}

    function _finalMint(address to, uint256 tokenCount) private {
        require(_currentTokenId.current() + tokenCount <= MAX_SUPPLY, "Will exceed maximum supply");

        for (uint256 i = 1; i <= tokenCount; i++) {
            _currentTokenId.increment();
            _safeMint(to, _currentTokenId.current());
        }
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
