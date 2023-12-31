//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC2981.sol";
import "./OperatorFilter.sol";

uint96 constant ROYALTY_FEE = 600;
string constant NAME = "FACES by LARRYDIDITT";
string constant SYMBOL = "FACES";
uint256 constant ID_OFFSET = 51287; // number in which to offset tokenIds by
address constant WEMINTART_GNOSIS = 0x3c3A52FcE8e9634dCF34BEE8f4146A175eB76D05;

/// @author tae-jin.eth
/// @title BaseNFT - Base ERC721A NFT contract for We Mint Art

contract BaseNFT is ERC721A, ERC2981, Ownable, OperatorFilter {
    using ECDSA for bytes32;

    bool public presale = true;

    uint256 public presalePrice;
    uint256 public publicPrice;

    uint256 public maxPerWalletPresale;
    uint256 public maxPerWalletPublic;

    uint256 public presaleSupply;
    uint256 public presaleMinted;
    uint256 public maxSupply; // total supply of tokens

    mapping(uint256 => bool) public claimed;
    mapping(address => bool) public admins;

    string private baseURI;
    string private claimedBaseURI;
    address private signerAddress;

    constructor(
        uint256 _publicPrice,
        uint256 _presalePrice,
        uint256 _maxPerWalletPresale,
        uint256 _maxPerWalletPublic,
        uint256 _internalSupply,
        uint256 _presaleSupply,
        uint256 _maxSupply,
        address _signerAddress,
        string memory _metadataBaseURI,
        string memory _claimedBaseURI
    ) ERC721A(NAME, SYMBOL) OperatorFilter() {
        publicPrice = _publicPrice;
        presalePrice = _presalePrice;
        maxPerWalletPresale = _maxPerWalletPresale;
        maxPerWalletPublic = _maxPerWalletPublic;

        presaleSupply = _presaleSupply;
        presaleMinted = 0;

        maxSupply = _maxSupply;
        signerAddress = _signerAddress;
        baseURI = _metadataBaseURI;
        claimedBaseURI = _claimedBaseURI;

        // add msgSender to adminAddresses
        addAdmin(_msgSender());

        // add signerAddress to adminAddresses
        addAdmin(_signerAddress);

        // set royalty fee
        _setDefaultRoyalty(address(this), ROYALTY_FEE);

        // Mint out first the `_internalSupply` tokens to the owner
        _mint(WEMINTART_GNOSIS, _internalSupply);
    }

    function presaleMint(
        uint256 _amount,
        bytes calldata _signature
    ) external payable {
        require(presale, "Presale is not active");

        // ensure valid signature
        require(validatePresaleSignature(_signature), "Invalid signature");
        require(msg.value == presalePrice * _amount, "Insufficient funds");

        // ensure user isn't trying to mint more than max per wallet
        require(
            balanceOf(msg.sender) + _amount <= maxPerWalletPresale,
            "Max per wallet exceeded"
        );

        require(
            presaleMinted + _amount <= presaleSupply,
            "Presale supply exceeded"
        );

        // ensure user isn't trying to mint more than max supply
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded");

        _mint(msg.sender, _amount);

        // increment presale minted
        presaleMinted += _amount;
    }

    function mint(uint256 _amount) external payable {
        // require price and require not presale

        require(!presale, "Presale is still active");
        require(msg.value == publicPrice * _amount, "Insufficient funds");

        // ensure user isn't trying to mint more than max per wallet
        require(
            balanceOf(msg.sender) + _amount <= maxPerWalletPublic,
            "Max per wallet exceeded"
        );

        // ensure user isn't trying to mint more than max supply
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded");

        _mint(msg.sender, _amount);
    }

    function fiatMint(uint256 _amount, address _to) public payable {
        require(
            !presale,
            "Presale is still active.  Create a wallet to mint during the presale"
        );
        require(msg.value == publicPrice * _amount, "Insufficient funds");

        // ensure user isn't trying to mint more than max per wallet
        require(
            balanceOf(_to) + _amount <= maxPerWalletPublic,
            "Max per wallet exceeded"
        );

        // ensure user isn't trying to mint more than max supply
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded");

        _mint(_to, _amount);
    }

    function togglePresale(bool _presale) external onlyOwner {
        presale = _presale;
    }

    function setClaimed(uint256 _tokenId) public onlyAdmin {
        claimed[_tokenId] = true;
    }

    function setClaimedBulk(uint256[] calldata _tokenIds) public onlyAdmin {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            setClaimed(_tokenIds[i]);
        }
    }

    function withdraw(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (claimed[tokenId]) {
            return
                bytes(claimedBaseURI).length != 0
                    ? string(
                        abi.encodePacked(claimedBaseURI, _toString(tokenId))
                    )
                    : "";
        } else {
            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                    : "";
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return ID_OFFSET + 1;
    }

    function validatePresaleSignature(
        bytes memory signature
    ) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(msg.sender));
        return
            msgHash.toEthSignedMessageHash().recover(signature) ==
            signerAddress;
    }

    function addAdmin(address _newAdmin) public onlyOwner {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _adminToRemove) public onlyOwner {
        admins[_adminToRemove] = false;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "sender is not an admin");
        _;
    }

    // Internal Operator Filter Protected Transfer Functions
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
