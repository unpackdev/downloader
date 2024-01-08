// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Address.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// █▄░█ █ █▀▀ ▀█▀ █▄█ █▄▀ █ ▀█▀
// █░▀█ █ █▀░ ░█░ ░█░ █░█ █ ░█░
contract DropKitCollection is ERC721, ERC721Enumerable, Ownable {
    using Address for address;
    using SafeMath for uint256;

    uint256 public _maxAmount;
    uint256 public _maxPerMint;
    uint256 public _maxPerWallet;
    uint256 public _price;

    string internal _tokenBaseURI;
    mapping(address => uint256) internal _mintCount;

    bool public started = false;

    uint256 private constant _commission = 500; // parts per 10,000
    address private constant _niftyKit =
        0xb27EB5fB526b542DCfBa2438888d2a1519D7b9A8;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxAmount,
        uint256 maxPerMint,
        uint256 maxPerWallet,
        uint256 price,
        string memory tokenBaseURI
    ) ERC721(name, symbol) {
        _maxAmount = maxAmount;
        _maxPerMint = maxPerMint;
        _maxPerWallet = maxPerWallet;
        _price = price;
        _tokenBaseURI = tokenBaseURI;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(started == true, "Sale must be active");
        require(numberOfTokens <= _maxPerMint, "Exceeded maximum per mint");
        require(numberOfTokens > 0, "Must mint greater than 0");
        require(
            _mintCount[_msgSender()] <= _maxPerWallet,
            "Exceeded maximum per wallet"
        );
        require(
            totalSupply().add(numberOfTokens) <= _maxAmount,
            "Exceeded max supply"
        );
        require(
            _price.mul(numberOfTokens) == msg.value,
            "Value sent is not correct"
        );

        _mintCount[_msgSender()].add(numberOfTokens);
        _mint(numberOfTokens, _msgSender());
    }

    function adminMint(uint256 numberOfTokens) public payable onlyOwner {
        require(
            totalSupply().add(numberOfTokens) <= _maxAmount,
            "Exceeded max supply"
        );
        require(
            _price.mul(numberOfTokens) == msg.value,
            "Value sent is not correct"
        );

        _mint(numberOfTokens, _msgSender());
    }

    function start() public onlyOwner {
        require(started == false, "Sale is already started");

        started = true;
    }

    function pause() public onlyOwner {
        require(started == true, "Sale is already paused");

        started = false;
    }

    function withdraw() public {
        require(address(this).balance > 0, "Nothing to withdraw");

        uint256 balance = address(this).balance;
        uint256 commission = ((_commission * balance) / 10000);
        Address.sendValue(payable(_niftyKit), commission);
        Address.sendValue(payable(owner()), balance - commission);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _mint(uint256 numberOfTokens, address sender) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(sender, mintIndex);
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
