// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract CryptoPoP is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant MAX_PUBLIC_SUPPLY = 4000;
    uint256 public constant MAX_SUPPLY = 5555;

    string public baseTokenURI;
    uint256 public mintPrice;

    Counters.Counter private _tokenIds;

    constructor() ERC721("crypto PoP", "PoP") {
        baseTokenURI = "https://api.cryptopopnft.com/";
        mintPrice = 0.04 ether;
    }

    function mintToSender() public payable returns (uint256) {
        require(_tokenIds.current() < MAX_PUBLIC_SUPPLY, "Public minting has been finished");
        require(msg.value == mintPrice, "Transaction value does not equal the mint price");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        return newTokenId;
    }

    function mintToOwner(uint256 numberOfTokens) public onlyOwner whenEnoughTokens(numberOfTokens) {
        require(!msg.sender.isContract(), "Owner cannot be a contract");

        uint256 currentId = _tokenIds.current();
        uint256 lastId = currentId.add(numberOfTokens);
        for (uint256 id = currentId.add(1); id <= lastId; id++) {
            _tokenIds.increment();
            _mint(msg.sender, id);
        }
    }

    function mintTo(address[] memory recipients) public onlyOwner whenEnoughTokens(recipients.length) {
        uint256 numberOfRecipients = recipients.length;
        for (uint256 i = 0; i < numberOfRecipients; i++) {
            _tokenIds.increment();
            _safeMint(recipients[i], _tokenIds.current());
        }
    }

    modifier whenEnoughTokens(uint256 numberOfTokens) {
        uint256 lastTokenId = _tokenIds.current().add(numberOfTokens);
        require(lastTokenId <= MAX_SUPPLY, "Not enough tokens to mint");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, "contract"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(bytes(uri).length > 0, "Cannot set empty URI");
        baseTokenURI = uri;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function withdrawPayments(address payable payee) public onlyOwner {
        require(payee != address(0), "Cannot withdraw payments to the zero address");

        uint256 balance = address(this).balance;
        payee.transfer(balance);
    }
}
