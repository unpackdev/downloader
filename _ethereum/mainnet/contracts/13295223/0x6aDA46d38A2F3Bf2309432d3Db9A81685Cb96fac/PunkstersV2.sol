// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ERC721.sol";
import "./IERC721.sol";

import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PunkstersV2 is ERC721, Ownable {
    using Strings for uint256;

    address immutable public proxyRegistryAddress;
    address immutable public punkBodiesV2;
    address public constant punkBodiesV1 = 0x837779Ed98209C38b9bF77804a4f0105B9eb2E02;

    address payable public ownerWallet = payable(0x4dB3ce00D5F784733d3e1F7E8bE19631fAA57958);

    uint public mintingPrice;
    uint public whitelistPrice;
    uint public nextId = 1;
   

    mapping(uint256 => uint256) public hashToId;
    mapping(uint256 => uint256) public idToHash;

    mapping(address => bool) public whitelisted;
 
    

    string baseURI_ = "https://api.punkbodies.com/get-images/v2/metadata/";

    constructor(address pb, address _proxyRegistryAddress)  ERC721("Punksters V2", "Punkster V2") {
        punkBodiesV2 = pb;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setMintingPrice(uint256 newPrice) external onlyOwner {
        mintingPrice = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) external onlyOwner {
        whitelistPrice = newPrice;
    }
    
    function setBaseUri(string calldata newURI) external onlyOwner {
        baseURI_ = newURI;
    }

    function setOwnerWallet(address payable newWallet) external onlyOwner {
        ownerWallet = newWallet;
    }

    function setWhitelist(address[] calldata _adds, bool[] calldata _values) external onlyOwner {
        require(_adds.length == _values.length, "mismatched length");
        for(uint i = 0; i < _adds.length; i++) {
            whitelisted[_adds[i]] = _values[i];
        }
    }


    function withdraw() external onlyOwner {
        require(ownerWallet != address(0));
        ownerWallet.transfer(address(this).balance);
    }


    function mint(uint256 tokenId0, uint256 tokenId1, address otherToken) external payable{
        require(IERC721(tokenId0 < 10000 ? punkBodiesV1 : punkBodiesV2).ownerOf(tokenId0) == msg.sender, "not owner of token");
        require(IERC721(otherToken).ownerOf(tokenId1) == msg.sender, "not owner of token");


        uint256 price = getPriceFor(msg.sender);
        require(msg.value == price, "wrong value sent");

        uint256 hashed = uint256(keccak256(abi.encodePacked(tokenId0, tokenId1, otherToken)));

        require(hashToId[hashed] == 0, "combination already minted");

        uint256 id = nextId;

        hashToId[hashed] = id;
        idToHash[id] = hashed;

        nextId++;

        _mint(msg.sender, id);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "PairedNFT: caller is not owner nor approved");
        
        hashToId[idToHash[tokenId]] = 0;
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uint256(idToHash[tokenId]).toString())) : "";
    }

    function isApprovedForAll(address owner_, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner_)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    function getPriceFor(address buyer) public view returns(uint){
        if (whitelisted[buyer]) return whitelistPrice;
        return mintingPrice;
    }
}
