//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
// import "./ERC721PresetMinterPauserAutoId.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Context.sol";
import "./Counters.sol";

contract IndustrialRevolution is Context, ERC721Enumerable, ERC721Burnable, ERC721Pausable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public ownerMinted;
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    uint256 public constant MAX_ELEMENTS = 1250;
    uint256 public constant MAX_PURCHASE = 20;
    uint256 public constant MAX_OWNER_MINT = 250;
    uint256 public constant price = 0.1 ether;
    address public creator = 0x3EB29482944ab2e8861BA02AC8C127Ff48545580;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
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

    function buy(uint256 numberOfTokens) public payable {
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_ELEMENTS, "Purchase would exceed max supply of NFTs");
        require(price.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_ELEMENTS) {
                _mint(creator, mintIndex);
                _safeTransfer(creator, msg.sender, mintIndex, "");
                _tokenIdTracker.increment();
            }
        }
    }

    function mint(uint256 numberOfTokens, address to) public onlyOwner {
        require(totalSupply().add(numberOfTokens) <= MAX_ELEMENTS, "Mint would exceed max supply of NFTs");
        require(ownerMinted.current().add(numberOfTokens) <= MAX_OWNER_MINT, "Mint would exceed max ownerMinted");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_ELEMENTS) {
                _mint(creator, mintIndex);
                if (creator != to) {
                    _safeTransfer(creator, to, mintIndex, "");
                }
                _tokenIdTracker.increment();
                ownerMinted.increment();
            }
        }
    }

    function withdraw(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    function updateBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function updateCreator(address _creator) public onlyOwner {
        creator = _creator;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 num = (block.number % 9) + 1;
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "-", num.toString())) : "";
    }
}
