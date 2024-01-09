// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";

import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC721.sol";

import "./Whitelist.sol";

contract MetaCollar is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    PaymentSplitter,
    ReentrancyGuard,
    WhiteList
{
    string private _baseTokenURI;

    bool public presaleLive = true;
    bool public paused = true;

    uint256 public constant PRESALE_PRICE = 0.05 ether;
    uint256 public constant FULL_PRICE = 0.08 ether;
    uint256 public SUPPLY = 8000;
    uint256 public currentTokenId = 801; // Starting at 801 because 800 are being held back
    uint256 public currentAirdropId = 1;

    address[] public WLContracts; 

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address[] memory payees, 
        uint256[] memory shares
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) Ownable() {
        _baseTokenURI = baseTokenURI;
    }

    modifier whenNotSoldOut() {
        require(currentTokenId <= SUPPLY, "Sold Out");
        _;
    }

     modifier checkMax(uint256 quantity) {
        require(quantity < 51, ">50");
        _;
    }

    function setVars(string memory baseTokenURI, uint256 supply) public onlyOwner {
        _baseTokenURI = baseTokenURI;
        SUPPLY = supply;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString((tokenId)), '.json'));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}