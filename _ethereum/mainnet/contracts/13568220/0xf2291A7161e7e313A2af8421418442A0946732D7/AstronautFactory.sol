// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IFactory.sol";
import "./HappyAstronauts.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract AstronautFactory is FactoryERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    address public proxyRegistryAddress;
    address public nftAddress;
    string internal baseURI;

    uint256 internal numberofOptions = 10000;

      event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );


    constructor(
        string memory _uri,
        address _proxyRegistryAddress,
        address _nftAddress
    ) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        baseURI = _uri;
    }

    function name() override external pure returns (string memory){
        return "Happy Astronauts Factory";
    }

    function symbol() override external pure returns (string memory){
        return "HATSF";
    }

    function supportsFactoryInterface() override external view returns (bool) {
        return true;
    }

    function numOptions() override external view returns (uint256) {
        return numberofOptions;
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
       return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _optionId.toString())): "";
    }

    function canMint(uint256 _optionId)
        override
        external
        view
        returns (bool)
    {
        return true;
    }

    function mint(
        uint256 _optionId,
        address _toAddress
    ) override external nonReentrant {
        _mint(_optionId, _toAddress, 1, "");
    }

    function _mint(
        uint256 _option,
        address _toAddress,
        uint256 _amount,
        bytes memory _data
    ) internal {
        require(_isOwnerOrProxy(_msgSender()), "Caller cannot mint");
        HappyAstronauts astros = HappyAstronauts(nftAddress);

        astros.mintToken{value:0x0}(_toAddress, 1);
            
    }

    function setOptions(
        address to, uint256 from, uint256 upto) public onlyOwner {

        for(uint256 i = from; i < upto; i++)
        {
        emit Transfer(address(0), to, i);
        }
    }

    function burnOptions(
        address from_addr, uint256 from, uint256 upto) public onlyOwner {

        for(uint256 i = from; i < upto; i++)
        {
        emit Transfer(from_addr,address(0), i);
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public nonReentrant {
        _mint(_tokenId, _to, 1, "");
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }

    function _isOwnerOrProxy(address _address) internal view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return
            owner() == _address ||
            address(proxyRegistry.proxies(owner())) == _address;
    }

    function setOptionURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}