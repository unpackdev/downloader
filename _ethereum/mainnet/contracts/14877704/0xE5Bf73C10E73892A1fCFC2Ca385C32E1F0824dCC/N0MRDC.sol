// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract N0MRDC is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    string public baseExtension = "";
    address public proxyRegistryAddress;

    mapping(address => bool) public projectProxy;

    uint256 public constant maxN0MRDCSupply = 8814;
    uint256 public constant maxN0MRDCPerMint = 25;
    uint256 public cost = 0.005 ether;
    bool public mintLive = true;

    constructor(string memory _BaseURI, address _proxyRegistryAddress)
        ERC721A(
            "Not 0kay Mutant Rektguy DAO Club",
            "N0MRDC",
            maxN0MRDCPerMint,
            maxN0MRDCSupply
        )
    {
        setBaseURI(_BaseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setLiveMint(bool _state) public onlyOwner {
        mintLive = _state;
    }

    function mint(uint256 _mintAmount) public payable {
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }
        require(mintLive, "Minting is not Live");
        require(_mintAmount <= maxN0MRDCPerMint, "max mint exceeded");
        require(
            totalSupply() + _mintAmount <= maxN0MRDCSupply,
            "Max has already been minted"
        );
        _safeMint(msg.sender, _mintAmount);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function withdraw() public payable onlyOwner {
        (bool hs, ) = payable(0x15C61a6eCE98A8e32595FFC640B404A4A913Eddc).call{
            value: (address(this).balance * 50) / 100
        }("");
        require(hs);
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
