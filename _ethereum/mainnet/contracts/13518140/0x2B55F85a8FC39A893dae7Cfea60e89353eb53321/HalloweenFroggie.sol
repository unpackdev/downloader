// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract HalloweenFroggie is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // Where funds should be sent to
    address payable public payoutAddress;

    // ID Counters
    Counters.Counter private _premintIdCounter;
    Counters.Counter private _airdropIdCounter;
    Counters.Counter private _tokenIdCounter;

    // Maximum supply of the NFT
    uint256 public premintMaxSupply;
    uint256 public airdropMaxSupply;
    uint256 public maxSupply;

    // Maximum mints per transaction
    uint256 public maxPerTx;

    // Sale price
    uint256 public pricePer;

    // Is the sale enabled
    bool public airdrop = false;
    bool public sale = false;
    bool public presale = false;

    // baseURI for the metadata, eg ipfs://<cid>/
    string public baseURI;

    // Presale settings
    uint256 public presaleAllowedPer;
    mapping(address => uint256) private _presales;

    // Airdrop
    mapping(address => bool) private _airdrops;

    // Address used for signing
    address private signerAddress;

    constructor(address payable _payoutAddress, uint256 _premintMaxSupply, uint256 _airdropMaxSupply, uint256 _maxSupply, uint256 _maxPerTx, uint256 _pricePer, uint256 _presaleAllowedPer, string memory _uri, address _signerAddress) ERC721("Froggies Halloween", "FROGGIEHALLOWEEN") {
        payoutAddress = _payoutAddress;

        premintMaxSupply = _premintMaxSupply;
        airdropMaxSupply = _airdropMaxSupply;
        maxSupply = _maxSupply;

        maxPerTx = _maxPerTx;
        pricePer = _pricePer;
        baseURI = _uri;

        presaleAllowedPer = _presaleAllowedPer;

        signerAddress = _signerAddress;

        for (uint256 i = 0; i < premintMaxSupply; i++) {
            _airdropIdCounter.increment();
        }

        for (uint256 i = 0; i < airdropMaxSupply; i++) {
            _tokenIdCounter.increment();
        }
    }

    // Admin operations
    function updatePayoutAddress(address payable newPayoutAddress) external onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    function updateSale(bool _sale, bool _presale, bool _airdrop) external onlyOwner {
        sale = _sale;
        presale = _presale;
        airdrop = _airdrop;
    }

    function updatePresaleAllowedPer(uint256 _presaleAllowedPer) external onlyOwner {
        presaleAllowedPer = _presaleAllowedPer;
    }

    function updatePrice(uint256 _pricePer) external onlyOwner {
        pricePer = _pricePer;
    }

    function updateSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function updateBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function claimBalance() external onlyOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function preMint(address[] calldata to) external onlyOwner {
        require(to.length != 0, "Requested quantity cannot be zero");
        require(_premintIdCounter.current() + to.length <= premintMaxSupply, "Total supply will exceed limit");

        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], _premintIdCounter.current());
            _premintIdCounter.increment();
        }
    }

    function adminMintAirdrop(address[] calldata to) external onlyOwner {
        require(to.length != 0, "Requested quantity cannot be zero");
        require(_airdropIdCounter.current() + to.length <= airdropMaxSupply, "Total supply will exceed limit");

        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], _airdropIdCounter.current());
            _airdropIdCounter.increment();
        }
    }
    // End Admin operations

    // Presale operations
    function canMintPresale(address to, uint256 quantity, bytes32 _hash, bytes memory _signature) public view returns (bool) {
        require(presale, "Presale disabled");
        require(quantity != 0, "Requested quantity cannot be zero");
        require(_verifyHash(to, "halloween_presale", _hash), "Invalid hash");
        require(_verifySignature(_hash, _signature), "Invalid signature");
        require(_presales[to] + quantity <= presaleAllowedPer, "Presale limit reached");
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        return true;
    }

    function presaleMint(address to, uint256 quantity, bytes32 _hash, bytes memory _signature) payable external {
        require(canMintPresale(to, quantity, _hash, _signature), "cannot mint presale");
        // Transaction must have at least quantity * price (any more is considered a tip)
        require(quantity * pricePer <= msg.value, "Not enough ether sent");
        // Cannot mint more than maximum supply
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        for (uint256 i = 0; i < quantity; i++) {
            _presales[to] += 1;
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function presaleMinted(address owner) external view returns (uint256) {
        return _presales[owner];
    }
    // End Presale operations

    // Airdrop operations
    function canMintAirdrop(address to, bytes32 _hash, bytes memory _signature) public view returns (bool) {
        require(airdrop, "Airdrop disabled");
        require(_verifyHash(to, "halloween_airdrop", _hash), "Invalid hash");
        require(_verifySignature(_hash, _signature), "Invalid signature");
        require(!_airdrops[to], "Airdrop limit reached");
        require(_airdropIdCounter.current() + 1 <= airdropMaxSupply, "Total supply will exceed limit");

        return true;
    }

    function airdropMint(address to, bytes32 _hash, bytes memory _signature) external {
        require(canMintAirdrop(to, _hash, _signature), "cannot mint airdrop");
        // Cannot mint more than maximum supply
        require(_airdropIdCounter.current() + 1 <= airdropMaxSupply, "Total supply will exceed limit");

        _airdrops[to] = true;
        _safeMint(to, _airdropIdCounter.current());
        _airdropIdCounter.increment();
    }

    function airdropMinted(address owner) external view returns (bool) {
        return _airdrops[owner];
    }
    // End airdrop operations

    // Regular minting
    function safeMint(address to, uint256 quantity) payable external {
        // Sale must be enabled
        require(sale, "Sale disabled");
        // Cannot mint zero quantity
        require(quantity != 0, "Requested quantity cannot be zero");
        // Cannot mint more than maximum per operation
        require(quantity <= maxPerTx, "Requested quantity more than maximum");
        // Transaction must have at least quantity * price (any more is considered a tip)
        require(quantity * pricePer <= msg.value, "Not enough ether sent");
        // Cannot mint more than maximum supply
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    // End Regular minting

    // Utility functions
    function _verifySignature(bytes32 data, bytes memory signature) private view returns (bool) {
        return data
            .toEthSignedMessageHash()
            .recover(signature) == signerAddress;
    }

    function _verifyHash(address to, string memory prefix, bytes32 _hash) private pure returns(bool) {
        bytes32 h = keccak256(abi.encodePacked(prefix, to));
        return h == _hash;
    }
    // End Utility functions

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
