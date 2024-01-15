// contracts/NinetyNineLives.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NinetyNineLives is ERC721A, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 500;
    uint256 public tigerlistMintCost = 0.06 ether;
    uint256 public publicMintCost = 0.065 ether;
    bool public paused = false;
    bool public startTigerlistMinting = false;
    bool public startPublicMinting = false;
    bool public revealed = false;
    string private notRevealedUri;

    mapping(address => bool) private proxyRegistryAddress;
    mapping(address => bool) private tigerlistedAddresses;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // Modifier
    modifier maxWallet(uint256 _mintAmount) {
        require(balanceOf(msg.sender) + _mintAmount <= 10, "Maximum 10 NFTs per Wallet");
        _;
    }

    modifier isTigerlisted(address _address) {
        require(tigerlistedAddresses[_address], "You need to be tigerlisted");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function reserveMint(address[] calldata _toAddresses)
    external
    onlyOwner
    {
        uint256 supply = totalSupply();
        require(!paused, "Minting Paused");
        require(supply + _toAddresses.length <= maxSupply, "Finished Supply");

        for (uint256 i = 0; i < _toAddresses.length; i++) {
            _safeMint(_toAddresses[i], 1);
        }
    }

    function tigerlistMint(address _to, uint256 _mintAmount)
    external
    payable
    maxWallet(_mintAmount)
    isTigerlisted(_to)
    {
        uint256 supply = totalSupply();
        require(!paused, "Minting Paused");
        require(startTigerlistMinting, "Tigerlist Minting not start yet.");
        require(supply + _mintAmount <= maxSupply, "Finished Supply");
        require(msg.value >= tigerlistMintCost * _mintAmount, "Insufficient funds");

        _safeMint(_to, _mintAmount);
    }

    function publicMint(address _to, uint256 _mintAmount)
    external
    payable
    maxWallet(_mintAmount)
    {
        uint256 supply = totalSupply();
        require(!paused, "Minting Paused");
        require(startPublicMinting, "Public Minting not start yet.");
        require(supply + _mintAmount <= maxSupply, "Finished Supply");
        require(msg.value >= publicMintCost * _mintAmount, "Insufficient funds");

        _safeMint(_to, _mintAmount);
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    // Override Original Function
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    /**
     * Override isApprovedForAll to whitelisted marketplaces to enable
    gas-free listings.
     *
     */
    function isApprovedForAll(address owner, address operator) public
    view override returns (bool) {
        // check if this is an approved marketplace
        if (proxyRegistryAddress[operator]) {
            return true;
        }
        // otherwise, use the default ERC721 isApprovedForAll()
        return super.isApprovedForAll(owner, operator);
    }

    // Only Owner
    function setTigerlist(address[] calldata addresses, bool _isTigerlist) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            tigerlistedAddresses[addresses[i]] = _isTigerlist;
        }
    }

    // 99LIVES release 2299 NFT in multiple drop
    // Max Supply will update by drop, but wont exceed 2299 max supply
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply <= 2299, "Max Supply cannot exceed 2299");
        require(newMaxSupply > maxSupply, "New Amount must be higher than existing amount");

        maxSupply = newMaxSupply;
    }

    function revealCollection() public onlyOwner {
        revealed = true;
    }

    function setStartPublicMinting(bool _value) external onlyOwner {
        startPublicMinting = _value;
    }

    function setStartTigerlistMinting(bool _value) external onlyOwner {
        startTigerlistMinting = _value;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // Function to set status of proxy contracts addresses
    // https://github.com/ProjectOpenSea/opensea-creatures/blob/74e24b99471380d148057d5c93115dfaf9a1fa9e/migrations/2_deploy_contracts.js#L29
    // rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
    // mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    function setProxy(address[] calldata proxyAddresses, bool value) external onlyOwner {
        for (uint256 i = 0; i < proxyAddresses.length; i++) {
            proxyRegistryAddress[proxyAddresses[i]] = value;
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw(address _to) public onlyOwner {
        require(address(this).balance > 0, "No amount to withdraw");
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        require(success, "Withdraw Failed");
    }
}