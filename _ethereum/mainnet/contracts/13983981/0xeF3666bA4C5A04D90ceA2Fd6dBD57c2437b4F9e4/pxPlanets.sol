// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract pxPlanets is ERC721Enumerable, Ownable {
    string  public              baseURI;

    address public              proxyRegistryAddress;

    uint256 public              MAX_SUPPLY;

    uint256 public constant     MAX_PER_ADDRESS     = 10;
    uint256 public constant     RESERVES            = 21;

    bool    public              reservesCollected   = false;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress
    )
        ERC721("pxPlanets", "pxPlanets")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function collectReserves() external onlyOwner {
        require(!reservesCollected, "Reserves already taken.");

        uint256 totalSupply = _owners.length;
        for(uint i; i < RESERVES; i++) {
            _mint(_msgSender(), totalSupply + i);
        }

        reservesCollected = true;
    }

    function startSale(uint256 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function mint(uint256 count) public {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY - RESERVES, "Exceeds max supply.");
        require(addressToMinted[_msgSender()] + count <= MAX_PER_ADDRESS, "Exceeds address limit");

        addressToMinted[_msgSender()] += count;
        for(uint i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
