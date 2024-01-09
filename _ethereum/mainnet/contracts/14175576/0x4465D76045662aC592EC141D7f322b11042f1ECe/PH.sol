// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Strings.sol";

contract PHOwnableDelegateProxy {}

contract PHProxyRegistry {
    mapping(address => PHOwnableDelegateProxy) public proxies;
}

contract PH is ERC721Enumerable, Ownable {
    using SafeMath for uint256; 
    using Strings for uint256;

    address proxyRegistryAddress;

    mapping(uint256 => bool) private mintedTokens;
    mapping(uint256 => string) private customTokenToURI;

    uint256 public mintStartTimestamp;
    uint256 public mintStartFees = 1 ether; 
    uint256 public intervalToIncrement = 60 * 60 * 24 * 7 * 3; //3 weeks   
    uint256 public amountToIncrement = 1 ether;
    
    uint256 private currentSupply;

    string private baseURI;
    string private contractDetailsURI = "https://cihkmod465ikvvo4jh6ag73vr4bygar2xudq63w2snx7ipau35rq.arweave.net/Eg6mOHz3UKrV3En8A391jwODAjq9Bw9u2pNv9DwU32M";

    address private dev = 0x72D397736aEf7BA70aaE89d567c2a2D5736eBC48;
    address private wallet1 = 0xDe710057d90B7Bec42B3296480F5ff834a6e3de5;
    address private wallet2 = 0xacBD1ceEd8B0daa732F270B247e17C4045075454;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        uint256 _mintStartTimestamp
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        mintStartTimestamp = _mintStartTimestamp;
    }

    function setMintStartTimestamp(uint256 _timestamp) public onlyOwner {
        mintStartTimestamp = _timestamp;
    }

    function setMintStartFees(uint256 _fees) public onlyOwner {
        mintStartFees = _fees;
    }

    function isMintEnabled() public view returns (bool) {
        return block.timestamp >= mintStartTimestamp;
    }

    function isMintedAlready(uint256 _tokenId) public view returns (bool) {
        return mintedTokens[_tokenId] == true;
    }

    function isAvailableToMint(uint256 _tokenId) public view returns (bool) {
        return isMintEnabled() && !isMintedAlready(_tokenId) && _tokenId > 0 && _tokenId <= currentSupply;
    }

    function setIncrementDetails(uint256 _interval, uint256 _amount) public onlyOwner {
        intervalToIncrement = _interval;
        amountToIncrement = _amount;
    }

    function increaseSupply(uint256 _supply, string memory _uri) public onlyOwner {
        require(_supply > currentSupply, "Incorrect input");
        currentSupply = _supply;
        setBaseURI(_uri);
    }

    function addTokens(string[] memory _uris) public onlyOwner {
        uint256 supply = currentSupply;
        for (uint256 i = 0; i < _uris.length; i++) {
            customTokenToURI[supply + i + 1] = _uris[i];
        }
        currentSupply += _uris.length;  
    }

    function setCustomURIForToken(uint256 _tokenId, string memory _uri) public onlyOwner {
        customTokenToURI[_tokenId] = _uri;
    }

    function currentMintFees() public view returns (uint256) {
        return isMintEnabled() 
        ? mintStartFees.add(Math.ceilDiv(block.timestamp.sub(mintStartTimestamp), intervalToIncrement).sub(1).mul(amountToIncrement)) 
        : mintStartFees;
    }

    function mint(uint256 _tokenId) public payable {
        require(
            isAvailableToMint(_tokenId),
            "Minting not allowed currently"
        );
        require(
            msg.value >= currentMintFees(),
            "Incorrect value sent"
        );
        mintNoChecks(_tokenId, msg.sender);
    }

    function mintNoChecks(uint256 _tokenId, address _to) private {
        _mint(_to, _tokenId);
        mintedTokens[_tokenId] = true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(dev).transfer(balance.mul(15).div(100));
        payable(wallet1).transfer(balance.mul(425).div(1000));
        payable(wallet2).transfer(balance.mul(425).div(1000));
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return bytes(customTokenToURI[_tokenId]).length > 0 ? customTokenToURI[_tokenId] : string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        PHProxyRegistry proxyRegistry = PHProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

     function setContractURI(string memory _uri) public onlyOwner {
        contractDetailsURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return contractDetailsURI;
    }
}
