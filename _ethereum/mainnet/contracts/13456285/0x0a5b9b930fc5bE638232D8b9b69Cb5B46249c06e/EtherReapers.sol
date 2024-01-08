// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";

pragma solidity ^0.8.0;

contract EtherReapers is ERC721URIStorage, ERC721Enumerable, Ownable {
    event MintReapers(address indexed minter, uint256 startWith, uint256 times);
    using Strings for uint256;
    uint256 public totalReapers;
    uint256 public totalCount = 10000; //bruhTotal
    uint256 public maxBatch = 50; // bruhBatch
    uint256 public price = 0.08 ether; // 0.08 eth
    string public baseURI;
    string public URIPost = ".json";
    bool public started;
    bool public revealed;
    uint256 addressRegistryCount;

    constructor() ERC721("Ether Reapers", "ERX") {
        baseURI = "ipfs://bafkreien3lilb72xmybkjtn3xw4lqwyy2plhswp57n5vkzyj3puvegehhu";
    }

    modifier mintEnabled() {
        require(started, "not started");
        _;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return totalReapers;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
        revealed = true;
    }

    function setURIPost(bool _asJson) public onlyOwner {
        URIPost = _asJson ? ".json" : "";
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        return
            revealed
                ? string(abi.encodePacked(baseURI, tokenId.toString(), URIPost))
                : string(abi.encodePacked(baseURI));
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setNormalStart(bool _start) public onlyOwner {
        started = _start;
    }

    function mintReaper(uint256 _times) public payable mintEnabled {
        require(_times > 0 && _times <= maxBatch, "mint wrong number");
        require(totalReapers + _times <= totalCount, "too much");
        require(msg.value == _times * price, "value error");
        payable(owner()).transfer(msg.value);
        emit MintReapers(_msgSender(), totalReapers + 1, _times);
        for (uint256 i = 0; i < _times; i++) {
            _mint(_msgSender(), 1 + totalReapers++);
        }
    }

    function adminMint(uint256 _times) public payable onlyOwner {
        require(_times > 0 && _times <= maxBatch, "mint wrong number");
        require(totalReapers + _times <= totalCount, "too much");
        require(msg.value == _times * price, "value error");
        payable(owner()).transfer(msg.value);
        emit MintReapers(_msgSender(), totalReapers + 1, _times);
        for (uint256 i = 0; i < _times; i++) {
            _mint(_msgSender(), 1 + totalReapers++);
        }
    }

    function adminMintGiveaways(address _addr) public onlyOwner {
        require(
            totalReapers + 1 <= totalCount,
            "Mint amount will exceed total collection amount."
        );
        emit MintReapers(_addr, totalReapers + 1, 1);
        _mint(_addr, 1 + totalReapers++);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

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
