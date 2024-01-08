// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CabuCats is ERC721Enumerable, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant MAX_CATS = 8888;
    uint256 public RESERVED_CATS_AVAILABLE = 88;
    uint256 public constant PRESALE_CATS_PER_WALLET = 3;
    uint256 public constant MAX_PER_MINT = 7;
    uint256 public constant mintPrice = 0.04 ether;

    string private _tokenBaseURI;

    bool public presaleIsOpen = false;
    bool public saleIsOpen = false;
    bool public revealed = false;

    mapping (address => uint256) private _userPresaleMints;
    mapping(address => bool) private _isFreeMinted;

    address private _signer;

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        string memory initBaseURI,
        address signerAddress
    ) ERC721("Cabu Cats", "CABU") PaymentSplitter(payees, shares) {
        _tokenBaseURI = initBaseURI;
        _signer = signerAddress;
    }

    function preSale(uint256 numberOfTokens, bytes32 hash, bytes memory signature) external payable {
        require(presaleIsOpen && !saleIsOpen, "Presale is not active");
        require(numberOfTokens > 0, "Minimum minting amount is 1");
        require(_userPresaleMints[msg.sender] + numberOfTokens <= PRESALE_CATS_PER_WALLET, "Max cats per wallet limit exceeded");

        require(isValidSign(hash, signature), "Invalid signer");
        require(hashTransaction(msg.sender, numberOfTokens) == hash, "Invalid hash");

        if (_isFreeMinted[msg.sender]) {
            require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        } else {
            require(mintPrice * (numberOfTokens - 1) <= msg.value, "Ether value sent is not correct");
        }

        for(uint256 i = 0;  i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
            _userPresaleMints[msg.sender]++;
        }

        if (!_isFreeMinted[msg.sender]) {
            _isFreeMinted[msg.sender] = true;
        }
    }

    function mintCats(uint256 numberOfTokens) external payable {
        require(saleIsOpen, "Public mint is not active");
        require(numberOfTokens <= MAX_PER_MINT, "Max cats per mint exceeded");
        require(totalSupply() + numberOfTokens <= MAX_CATS - RESERVED_CATS_AVAILABLE, "Purchase would exceed max available cats");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0;  i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function hashTransaction(address sender, uint256 qty) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty)))
        );

        return hash;
    }

    function isValidSign(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signer == hash.recover(signature);
    }

    function gift(address to, uint256 numberOfTokens) external onlyOwner {
        require(RESERVED_CATS_AVAILABLE >= numberOfTokens, "Purchase would exceed reserved cats");

        for(uint256 i = 0;  i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(to, mintIndex);
            RESERVED_CATS_AVAILABLE--;
        }
    }

    function flipPresaleState() external onlyOwner {
        presaleIsOpen = !presaleIsOpen;
    }

    function flipSaleState() external onlyOwner {
        saleIsOpen = !saleIsOpen;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    function setSigner(address _newSigner) external onlyOwner {
        _signer = _newSigner;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) {
            return _tokenBaseURI;
        } else {
            return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ""));
        }
    }
}
