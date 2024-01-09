// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";

import "./signature-control.sol";
import "./role-control.sol";
import "./nonce-control.sol";

contract RealApesClub is
    ERC721URIStorage,
    NonceControl,
    RoleControl,
    SignatureControl
{
    using Strings for uint256;

    uint256 public maxSupply;
    string baseURI;
    string baseExtension = ".json";
    uint256 supply;
    uint256 singlePrice = 0.22 ether;
    uint256 maxPublicMint = 3;
    bool public paused = true;
    bool public isPublicSale;

    mapping(address => uint256) public mintedLimited;
    mapping(address => uint256) public mintedPublic;

    event Mint(address minter, uint256 indexed tokenId, string metadata);

    modifier isUnpaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onPublicSale() {
        require(isPublicSale, "Public sale is not open");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        string memory baseUri_
    ) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR, msg.sender);
        maxSupply = maxSupply_;
        setBaseUri(baseUri_);
    }

    function changePauseStatus() public onlyAdmin {
        paused = !paused;
    }

    function setBaseUri(string memory uri) public onlyAdmin {
        baseURI = uri;
    }

    function openPublicSale() public onlyAdmin {
        isPublicSale = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
            );
    }

    function _mint(uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            supply++;
            _safeMint(msg.sender, supply);
            _setTokenURI(supply, supply.toString());
            emit Mint(msg.sender, supply, supply.toString());
        }
    }

    function mintPublic(uint256 amount) public payable isUnpaused onPublicSale {
        mintedPublic[msg.sender] += amount;
        require(mintedPublic[msg.sender] <= 3,"Can only mint up to 3 tokens from single wallet");
        uint256 price = singlePrice * amount;
        require(msg.value >= price, "Message value too low");
        require(supply + amount <= maxSupply, "Mint exceeds maximum supply");
        _mint(amount);
    }

    function mintLimited(
        bytes memory signature,
        uint256 nonce,
        uint256 amount
    ) public payable isUnpaused {
        mintedLimited[msg.sender] += amount;
        require(mintedLimited[msg.sender] <= 3,"Can only mint up to 3 tokens from single wallet");
        require(isValidMint(signature, nonce));
        uint256 price = singlePrice * amount;
        require(msg.value >= price, "Message value too low");
        require(supply + amount <= maxSupply, "Mint exceeds maximum supply");
        _mint(amount);
    }

    function isValidMint(bytes memory signature, uint256 nonce)
        internal
        onlyValidNonce(nonce)
        returns (bool)
    {
        bytes memory data = abi.encodePacked(
            _toAsciiString(msg.sender),
            " is authorized to mint token with nonce ",
            nonce.toString()
        );
        bytes32 hash = _toEthSignedMessage(data);
        address signer = ECDSA.recover(hash, signature);
        require(isOperator(signer), "Mint not verified by operator");
        return true;
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function withdraw(uint256 amount, address payable to) public onlyAdmin {
        (bool success, ) = to.call{value: amount}("");
        require(success);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, RoleControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
