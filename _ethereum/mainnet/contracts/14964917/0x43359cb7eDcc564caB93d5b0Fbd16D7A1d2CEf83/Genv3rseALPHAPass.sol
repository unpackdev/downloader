//SPDX-License-Identifier: MIT

/*
  ____ _____ _   ___     _______ ____  ____  _____
 / ___| ____| \ | \ \   / |___ /|  _ \/ ___|| ____|
| |  _|  _| |  \| |\ \ / /  |_ \| |_) \___ \|  _|
| |_| | |___| |\  | \ V /  ___) |  _ < ___) | |___
 \____|_____|_| \_|  \_/  |____/|_| \_|____/|_____|
 BY GENFLOW
*/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Genv3rseALPHAPass is ERC721A, ERC2981, ERC721ABurnable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    uint256 public maxSupply = 1000;
    uint256 public reservedSupply = 200; // Giveaways (therefore public allocation = 1000 - 200 = 800)
    uint256 public reservedSupplyUsed = 0;
    uint256 public maxMintAmount = 1;

    mapping(address => bool) public alphaList;

    bool public alphaListActive = true;
    bool public publicSaleActive = false;

    string public baseTokenURI = "https://genverse.mypinata.cloud/ipfs/QmZ7zY1csQ2NFRkFxbHdKeovN7pbE5xuFwDiGAus6qigJD";

    bool private isOpenSeaProxyActive = false;
    address internal openSeaProxyRegistryAddress;

    constructor() ERC721A("Genv3rse ALPHA Pass", "G3ALPHA") {
        _setDefaultRoyalty(0xe77fDcb06a70ABE3Cf404D55d7F51D71E7891949, 1000);
    }

    // Modifiers
    modifier isAlphaListed() {
        require(alphaListActive && alphaList[msg.sender], "You need to be ALPHA listed to mint.");
        _;
    }

    modifier isPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active at the moment.");
        _;
    }

    // Alpha List Management
    function addToAlphaList (address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            alphaList[_addresses[i]] = true;
        }
    }

    function removeFromAlphaList(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            alphaList[_addresses[i]] = false;
        }
    }

    // Minters
    function _walletMint(uint256 amount) private {
        require((totalSupply() - reservedSupplyUsed + amount) <= (maxSupply - reservedSupply), "You cannot mint more than (maxSupply - reservedSupply)  tokens.");
        require(amount <= maxMintAmount, "You may only mint maxMintAmount tokens at one time.");

        _safeMint(msg.sender, amount);
    }

    function alphaListMint(uint256 amount) external nonReentrant whenNotPaused isAlphaListed {
        _walletMint(amount);
    }

    function publicMint(uint256 amount) external nonReentrant whenNotPaused isPublicSaleActive {
        _walletMint(amount);
    }

    // Giveaways
    function ownerMint(uint256 amount) external nonReentrant onlyOwner {
        require(amount <= (reservedSupply - reservedSupplyUsed), "You cannot mint more than reservedSupply tokens.");
        require(totalSupply() + amount <= maxSupply, "You cannot mint more than maxSupply tokens.");
        _safeMint(msg.sender, amount);
        reservedSupplyUsed += amount;
    }

    // Setters
    function setMaxSupply (uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setReservedSupply (uint256 _reservedSupply) external onlyOwner {
        // Giveaways
        reservedSupply = _reservedSupply;
    }

    function setMaxMintAmount (uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setAlphaListActive (bool _alphaListActive) external onlyOwner {
        alphaListActive = _alphaListActive;
    }

    function setPublicSaleActive (bool _publicSaleActive) external onlyOwner {
        publicSaleActive = _publicSaleActive;
    }

    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) external onlyOwner {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setOpenSeaProxyRegistryAddress(address _openSeaProxyRegistryAddress) external onlyOwner {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Misc
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseTokenURI));
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyRegistryAddress);

        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}