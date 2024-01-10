// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/* 

 dP""b8  dP"Yb  888888    db    8b    d8 
dP   `" dP   Yb   88     dPYb   88b  d88 
Yb  "88 Yb   dP   88    dP__Yb  88YbdP88 
 YboodP  YbodP    88   dP""""Yb 88 YY 88 

Hurrying up Satoshi Nakamoto's plan.
Ragnar Danneskjold

Many thanks to everyone who made this possible.
This project is gas efficient.
 */

/// @custom:security-contact security@gotaminute.art
import "Ownable.sol";
import "ERC721Enumerable.sol";


contract GotaMinute is ERC721Enumerable, Ownable {
    string  public              baseURI;
    
    address public              proxyRegistryAddress;
    address public              accountDept;
    uint256 public              priceInWei;

    uint256 public constant    PUB_SUPPLY          = 474337;
    uint256 public constant    MAX_SUPPLY          = 527041;

    uint256 public constant     MAX_PER_TX          = 100;
    uint256 public constant     RESERVES            = 52704;

    mapping(address => bool) public projectProxy;

    constructor(
        string memory _baseURI, 
        address _proxyRegistryAddress, 
        address _accountDept,
        uint256 _priceInWei
    )
        ERC721("GotaMinute", "GOTAM")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        accountDept = _accountDept;
        priceInWei = _priceInWei;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function upPrice(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Minute does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function collectReserves(uint256 count) external onlyOwner {
        require(_owners.length + count< MAX_SUPPLY, 'All Minutes Exceeded.');
        for(uint256 i; i < count; i++)
            _mint(_msgSender(), i);
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < PUB_SUPPLY, "Exceeds max supply");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        require(count * priceInWei == msg.value, "Wrong Amount paid.");
    
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool success, ) = accountDept.call{value: address(this).balance}("");
        require(success, "Failed to send to accountDept.");
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
        _owners.push(to)
        ; emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}