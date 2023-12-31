// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Strings.sol";
import "./Initializable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Whitelist.sol";

contract WizardryERC721 is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    error TransferNotAllowed();

    using Strings for uint256;

    Whitelist public whitelist;
    uint256 public maxSupply;

    string private baseURI;

    function __init(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _startAt,
        uint256 _endAt
    ) public initializer {
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721_init(_name, _symbol);
        whitelist = new Whitelist();
        whitelist.setPrice(_price);
        whitelist.setPeriod(_startAt, _endAt);
        baseURI = _baseURI;
        maxSupply = _maxSupply;
    }

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "amount is zero");
        require(supply + _mintAmount <= maxSupply, "exceed maxSupply");
        whitelist.beforeTransfer(msg.sender, _mintAmount, msg.value);
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721EnumerableUpgradeable) {
        if (from != address(0)) {
            revert TransferNotAllowed();
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: token not exists");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // ----- only owner

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPeriod(uint256 startAt, uint256 endAt) public onlyOwner {
        whitelist.setPeriod(startAt, endAt);
    }

    function setPrice(uint256 price) public onlyOwner {
        whitelist.setPrice(price);
    }

    function ownerMint(address _to, uint256 count) public onlyOwner {
        uint256 supply = totalSupply();

        for (uint256 i = 1; i <= count; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function setWL(
        address[] memory addresses,
        uint256 maxMint
    ) public onlyOwner {
        whitelist.addWhiteList(addresses, maxMint);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
