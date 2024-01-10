pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CripToApeClub is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxTokens = 10000;
    uint256 public _price = 69000000000000000; // 0.069 ETH
    uint256 public _presale_price = 60000000000000000; // 0.06 ETH
    bool private _presaleActive = false;
    bool private _saleActive = false;

    string public _prefixURI = "ipfs://QmUfnqaJWmuVjBZxyC8yYxNUuh1eT8SJ1PCPYmEi7iorWr/";

    mapping(address => bool) private _freelist;
    mapping(address => bool) private _whitelist;

    constructor() ERC721("CripToApeClub", "CRIP") {}

    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function Sale() public view returns (bool) {
        return _saleActive;
    }

    function numSold() public view returns (uint256) {
        return _tokenIds.current();
    }

    function displayMax() public view returns (uint256) {
        return _maxTokens;
    }
    
    function changePrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function changeMax(uint256 _newMax) public onlyOwner {
        _maxTokens = _newMax;
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function preSale() public view returns (bool) {
        return _presaleActive;
    }    

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
        _presaleActive = false;
    }

    function freeListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _freelist[accounts[i]] = true;
        }
    }

    function whiteListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
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
        require(_saleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
            if (_tokenIds.current() % 5 == 0) {
                _mintItem(msg.sender);
            }
        }
    }

    function presaleMintItems(uint256 amount) public payable {
        require(_presaleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _presale_price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
            if (_tokenIds.current() % 5 == 0) {
                _mintItem(msg.sender);
            }
        }
    }

    function freeMint() public {
        require(_freelist[_msgSender()], "Mint: Unauthorized Access");
        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + 1 <= _maxTokens);
        _mintItem(msg.sender);
        if (_tokenIds.current() % 5 == 0) {
            _mintItem(msg.sender);
        }
        _freelist[_msgSender()] = false;

    }

    function reserve(uint256 quantity) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mintItem(msg.sender);
        }
    }

    function _mintItem(address to) internal returns (uint256) {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(to, id);

        return id;
    }

    function withdraw(address payee) public payable onlyOwner {
        require(payable(payee).send(address(this).balance));
    }

    function withdrawAmount(address payee, uint256 amount) public payable onlyOwner {
        require(payable(payee).send(amount));
    }
}
