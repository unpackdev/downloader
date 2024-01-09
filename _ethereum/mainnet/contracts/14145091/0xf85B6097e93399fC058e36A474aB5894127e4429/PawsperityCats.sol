// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./PawsperityCatsTypes.sol";

contract PawsperityCats is ERC721, Ownable {
    mapping(uint256 => PawsperityCatsTypes.PawsperityCat) cats;

    using Counters for Counters.Counter;
    Counters.Counter private _tokensMinted;

    uint256 public price = 0.036 ether;
    uint256 public freeMints = 888;
    bool public claimIsActive;
    bool public saleIsActive;

    string _baseTokenURI;
    address _proxyRegistryAddress;

    event NFTMinted(address sender, uint256 quantity);

    constructor(address proxyRegistryAddress)
        ERC721("Pawsperity Cats", "PAWS")
    {
        _proxyRegistryAddress = proxyRegistryAddress;
        _safeMint(msg.sender, 0);
    }

    function getSupply() external view returns (uint256) {
        return _tokensMinted.current();
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setFreeMints(uint256 amount) external onlyOwner {
        require(amount < 5001, "Free mint amount too large");
        freeMints = amount;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipClaimState() external onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function teamClaim(uint256 quantity) external onlyOwner {
        require(claimIsActive, "Claim is not active");

        for (uint256 i = 0; i < quantity; i++) {
            _tokensMinted.increment();
            _safeMint(msg.sender, _tokensMinted.current());
        }
    }

    function freeMint(uint256 quantity) external {
        require(saleIsActive, "Sale is not active");
        require(quantity < 6, "Mint quantity too large");
        require(
            _tokensMinted.current() + quantity <= freeMints,
            "No more free mints"
        );
        require(
            _tokensMinted.current() + quantity < 5001,
            "Not enough tokens remaining"
        );

        for (uint256 i = 0; i < quantity; i++) {
            _tokensMinted.increment();
            _safeMint(msg.sender, _tokensMinted.current());
        }
        emit NFTMinted(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(saleIsActive, "Sale is not active");
        require(quantity < 11, "Mint quantity too large");
        require(
            _tokensMinted.current() + quantity < 5001,
            "Not enough tokens remaining"
        );
        require(msg.value >= (price * quantity), "Not enough ether sent");

        for (uint256 i = 0; i < quantity; i++) {
            _tokensMinted.increment();
            _safeMint(msg.sender, _tokensMinted.current());
        }

        emit NFTMinted(msg.sender, quantity);
    }

    function setDna(uint256 tokenId, uint256 dna) external onlyOwner {
        PawsperityCatsTypes.PawsperityCat memory cat;
        cat.dna = dna;
        cats[tokenId] = cat;
    }

    function getDna(uint256 tokenId) public view returns (uint256) {
        return cats[tokenId].dna;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setProxyRegistryAddress(address proxyRegistryAddress)
        external
        onlyOwner
    {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    receive() external payable {}
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
