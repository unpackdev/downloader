// SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";


/// @custom:security-contact moo@hashcowsnft.com
contract HashCowsNFT is ERC721, ERC721Enumerable, Pausable, AccessControl, Ownable {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string baseURI;

    bool public revealed = false;
    string public notRevealedUri;

    address public constant WITHDRAW_ADDRESS = 0x7d52683fb78582642963be29E95Dc76A93765810;

    uint256 public MAX_SUPPLY = 10000;

    uint public constant MAX_PER_TX = 4;

    Counters.Counter private _tokenIdCounter;

    bool public preSaleState = false;
    bool public publicSaleState = false;

    uint256 public constant PRESALE_PRICE = 0.08 ether;
    uint256 public constant PUBLIC_PRICE = 0.08 ether;
    uint256 public price;
    // ERC721 First is the contract name second is contract symbol

    constructor(string memory _initNotRevealedUri) ERC721("HashCowsNFT", "HCNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        setNotRevealedURI(_initNotRevealedUri);
    }

    function safeMint(uint numberOfTokens) external payable whenNotPaused {
        require(preSaleState == true, "presale not started");
        require(numberOfTokens > 0, "zero tokens");
        require(numberOfTokens <= MAX_PER_TX, "would exceed tx limit");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "would exceed max supply");
        require(price * numberOfTokens == msg.value, "wrong value");

        if (publicSaleState == false) {
            require(hasRole(MINTER_ROLE, msg.sender), "address not whitelisted");
            renounceRole(MINTER_ROLE, msg.sender);
        }

        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function whitelistAddresses(address[] memory addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _grantRole(MINTER_ROLE, addresses[i]);
        }
    }

    function isAddressWhitelisted(address _address) external view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    function startPreSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = PRESALE_PRICE;
        publicSaleState = false;
        preSaleState = true;
    }

    function startPublicSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = PUBLIC_PRICE;
        preSaleState = true;
        publicSaleState = true;
    }

    function stopSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        preSaleState = false;
        publicSaleState = false;
    }

    function stopSupply() external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_SUPPLY = totalSupply();
    }

    function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
        revealed = true;
    }

    function walletOf(address _address)
    external
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_address, i);
        }

        return tokenIds;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = address(this).balance;
        payable(WITHDRAW_ADDRESS).transfer(balance);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(tokenId < totalSupply(), "token not exists");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0
        ? string(
            abi.encodePacked(
                currentBaseURI,
                Strings.toString(tokenId)
            )
        )
        : "";
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}