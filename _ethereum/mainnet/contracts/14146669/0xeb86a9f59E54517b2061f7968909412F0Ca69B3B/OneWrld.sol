// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract OneWrld is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct Payable {
        address addr;
        uint256 share;
    }

    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply;
    uint256 public mintPrice;
    string internal baseURI;
    string internal baseExtension;
    Payable[] private payables;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _baseExtension,
        uint256 _maxSupply,
        uint256 _mintPrice,
        address[] memory _migrateOwners,
        Payable[] memory _payables
    ) ERC721(_name, _symbol) {
        setBaseURI(_baseURI);
        setBaseExtension(_baseExtension);
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;

        for (uint256 i; i < _payables.length; i++) {
            payables.push(_payables[i]);
        }

        for (uint256 i; i < _migrateOwners.length; i++) {
            address itemOwner = _migrateOwners[i];
            mint(itemOwner, 1);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        for (uint256 i; i < payables.length; i++) {
            Payable memory _payable = payables[i];
            payable(_payable.addr).transfer((amount * _payable.share) / 100);
        }
    }

    function airdrop(address[] memory _addresses) public onlyOwner {
        for (uint256 index = 0; index < _addresses.length; index++) {
            mint(_addresses[index], 1);
        }
    }

    function mint(address _to, uint256 _amount) public payable {
        if (msg.sender != owner()) {
            require(msg.value >= mintPrice * _amount, "INVALID_ETH_AMOUNT");
        }

        require(_tokenIdCounter.current() + _amount <= maxSupply, "SOLD_OUT");

        for (uint256 index = 0; index < _amount; index++) {
            _tokenIdCounter.increment();
            _safeMint(_to, _tokenIdCounter.current());
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "not exist");
        return
            string(
                abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
            );
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}
