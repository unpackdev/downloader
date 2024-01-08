pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CryptoPizzaParty is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private constant _maxTokens = 10000;
    uint256 private constant _maxMint = 25;
    uint256 public constant _price = 30000000000000000; // 0.03 ETH

    string public _prefixURI;

    constructor() ERC721("Crypto Pizza Party", "PIZZAPARTY") {}

    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function mintItems(uint256 amount) public payable {
        require(amount <= _maxMint);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function _mintItem(address to) internal returns (uint256) {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(to, id);

        return id;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
