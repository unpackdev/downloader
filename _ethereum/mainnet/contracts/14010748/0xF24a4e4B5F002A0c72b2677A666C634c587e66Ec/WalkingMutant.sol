// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

interface IWalkingApe {
     function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract WalkingMutant is ERC721Enumerable, Ownable {
    string  public              baseURI             ;
    
    address public              proxyRegistryAddress;
    uint256 public              MAX_SUPPLY          ;
    uint256 public              MAX_PUBLIC_SUPPLY   ;
    uint256 public              MAX_PER_TX          = 11;
    uint256 public              priceInWei          = 0.04 ether;
    uint256 public              priceClaim          = 0 ether;
    address public              wa_Address          ;
    bool    public              claimPause          = true;

    mapping(address => bool) public projectProxy;
    mapping(uint256 => bool) public claimed;

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress
    )
        ERC721("Walking Mutant", "Walking Mutant")
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


    function mint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_PUBLIC_SUPPLY, "Excedes max supply.");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
    
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function claim() public payable {
        require( !claimPause, "Claim session is not live!");
        uint256 totalSupply = _owners.length;
        uint256[] memory tokensList = IWalkingApe(wa_Address).walletOfOwner(_msgSender());
        uint256 count = tokensList.length;
        for(uint i; i < tokensList.length; i++) { 
            if ( claimed[tokensList[i]] ) 
                {
                    count = count - 1 ;
                }
            else 
                {
                    claimed[tokensList[i]] = true;
                }
        }
        require( count > 0, "You don't have any unclaimed Walking Ape tokens.");
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        require(count * priceClaim == msg.value, "Invalid funds provided.");
    
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function collectReserves() external onlyOwner {
        for(uint256 i; i < 10; i++)
            _mint(_msgSender(), i);
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }
    function claimStatus(uint256 _tokenID) public view returns (bool) {
        return claimed[_tokenID];
    }   
    
    function setmaxSupply(uint256 _newMax) public onlyOwner {
        MAX_SUPPLY = _newMax;
    }

    function setmaxPublicSupply(uint256 _newPublicMax) public onlyOwner {
        MAX_PUBLIC_SUPPLY = _newPublicMax;
    }

    function setWAaddress(address _wa) public onlyOwner {
        wa_Address = _wa;
    }

    function setPause(bool _state) public onlyOwner {
        claimPause = _state;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        priceInWei = _newPrice;
    }

    function setPriceClaim(uint256 _newClaim) public onlyOwner {
        priceClaim = _newClaim;
    }

    function setTX(uint256 _newTX) public onlyOwner {
        MAX_PER_TX = _newTX;
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }
    
    
    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
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