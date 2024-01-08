// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BadGifts is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public max_supply = 4200;
    uint256 public reserve_supply = 69;
    uint256 public maxPerTx = 10;
    uint256 public reserve_minted = 0;
    uint256 public mint_price = 66600000000000000;
    string public preRevealURI = "";
    string public baseTokenURI = "";

    bool public publicSale;
    bool public greenlistSale;
    bytes32 public greenlistRoot;

    string private _contractURI;
    ProxyRegistry private _proxyRegistry;
    Counters.Counter private _tokenIds;

    mapping(address => bool) greenlistMinted;

    constructor(address openseaProxyRegistry_) ERC721("BadGifts", "BG") {
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }

    function greenListMint(bytes32[] memory _proofs)
        public
        payable
        nonReentrant
    {
        require(!publicSale && greenlistSale, "Greenlist sale has ended");
        bool canMint = canGreenlistMint(msg.sender, _proofs);
        require(canMint, "Address cannot greenlist mint!");
        greenlistMinted[msg.sender] = true;
        mint(1, true, msg.sender);
    }

    function publicMint(address _to, uint256 _amount) public payable nonReentrant {
        mint(_amount, false, _to);
    }

    function reserveMint(address _to, uint256 _amount) public onlyOwner {
        require(
            (reserve_minted + _amount) <= reserve_supply,
            "Mint would exceed reserve supply"
        );
        reserve_minted += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current();
            _safeMint(_to, newNftTokenId);
        }
    }

    function mint(
        uint256 _amount,
        bool _isGreenList,
        address _to
    ) private {
        if (!_isGreenList) {
            require(publicSale, "Sale has not started");
        }
        require(_amount <= maxPerTx, "Amount too large");
        require((mint_price * _amount) == msg.value, "Value too low");
        require(
            (totalSupply() + _amount) <= (max_supply - reserve_supply),
            "Mint would exceed total supply"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current();
            _safeMint(_to, newNftTokenId);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId));
        if (bytes(baseTokenURI).length == 0) {
            return string(abi.encodePacked(preRevealURI, _tokenId.toString()));
        }
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }

    function canGreenlistMint(address _addr, bytes32[] memory _proofs)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_addr));
        bool canMint = MerkleProof.verify(_proofs, greenlistRoot, leaf);
        if (!canMint || greenlistMinted[_addr]) {
            return false;
        }
        return true;
    }

    function setPreRevealURI(string memory _uri) public onlyOwner {
        preRevealURI = _uri;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }

    function setGreenList(bytes32 _rootHash) public onlyOwner {
        greenlistRoot = _rootHash;
    }

    function toggleGreenListSale() public onlyOwner {
        greenlistSale = !greenlistSale;
    }

    function togglePublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function withdraw() external payable onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            address(proxyRegistry) != address(0) &&
            address(proxyRegistry.proxies(owner)) == operator;
    }

    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setOpenSeaRegistry(address proxyRegistryAddress)
        external
        onlyOwner
    {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}