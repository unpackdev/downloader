// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";
import "./console.sol";

contract HashWorldCharacter is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
   
    uint256 public constant MAX_BUY_PER_ADDRESS = 5;
    uint256 public constant MAX_SUPPLY = 5000;

    string private _baseTokenURI;
    uint256 public thisRoundSupply;
    
    uint256 public price_per_token = 0.035 ether;
    bool public useNewTokenURI = false;

    mapping(uint256 => uint8) public types;
    mapping(uint256 => uint8) public attributes;
    mapping(uint256 => uint8) public names;

    event MintSuccess(
      address indexed to, 
      uint256 indexed tokenId,
      uint8 _type,
      uint8 _attribute,
      uint8 _name
    );

    constructor(uint256 _thisRoundSupply) ERC721("HashWorldCharacter", "HASHC") {
        thisRoundSupply = _thisRoundSupply;
        _pause();
    }

    function setThisRoundSupply(uint256 _thisRoundSupply) public onlyOwner{
        require(_thisRoundSupply>thisRoundSupply,"Wrong supply.");
        require(_thisRoundSupply<=MAX_SUPPLY,"Large than max supply.");
        thisRoundSupply = _thisRoundSupply;
    }

    modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }

    modifier tokenUrlExist(uint256 tokenId){
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      _;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // get type by random distrubution, 1 girl=26%,2 boy=26%,3 mech=15%, 4 mega=6%, 5 angel=4%,6 orc=15%,7 robot 8%
    function calculateType(uint256 seed) private pure returns (uint8) {
        uint256 result = seed % 100;
        if (result < 26) {
            return 1;
        } else if (result < 52) {
            return 2;
        } else if (result < 67) {
            return 3;
        } else if (result < 73) {
            return 4;
        } else if (result < 77) {
            return 5;
        } else if (result < 92){
            return 6;
        }else{
            return 7;
        }
    }

    // get attribute by random distrubution, 1 Normal=60%,2 Excellent=30%,3 Immortal=10%
    function calculateAttribute(uint256 seed) private pure returns (uint8) {
        uint256 result = seed % 10;
        if (result < 6) {
            return 1;
        } else if (result < 9) {
            return 2;
        } else {
            return 3;
        }
    }

    function setPrice(uint256 price) public onlyOwner{
        price_per_token = price;
    }

    function mint(uint256 amount) external payable callerIsUser {
        require(balanceOf(msg.sender) + amount <= MAX_BUY_PER_ADDRESS, "Exceed max buy per address");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed max token supply");
        require(totalSupply() + amount <= thisRoundSupply, "Exceed max token supply");
        require(msg.value >= amount * price_per_token, "Not enough ETH");

        uint256 initSupply = totalSupply();
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = initSupply + i + 1;
            uint256 randomSeed = uint256(
                keccak256(abi.encodePacked(msg.sender, tokenId, block.difficulty))
            );
            uint8 typeResult = calculateType(randomSeed);
            uint8 attributeResult = calculateAttribute(randomSeed);
            types[tokenId] = typeResult;
            attributes[tokenId] = attributeResult;
            names[tokenId] = uint8(randomSeed % 52);
            _safeMint(msg.sender, tokenId);
            emit MintSuccess(msg.sender, tokenId, typeResult, attributeResult, names[tokenId]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setUseNewTokenURI(bool flag) public onlyOwner{
        useNewTokenURI = flag;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      string memory _baseURI = _baseTokenURI;
      if(useNewTokenURI){
          return
          bytes(_baseURI).length > 0 ? string(abi.encodePacked(
            _baseURI, 
            Strings.toString(tokenId)
          )) : "";
      }else{
        //   21*Name+3*(types-1)+Attr
        // uint16 index  = uint16(names[tokenId]) * 52 + uint16(types[tokenId]) * 7 +  uint16(attributes[tokenId]) * 3;
        uint16 index  = uint16(names[tokenId]) * 21 + uint16(types[tokenId]-1) * 3 +  uint16(attributes[tokenId]);
        return
          bytes(_baseURI).length > 0 ? string(abi.encodePacked(
            _baseURI, 
            Strings.toString(index)
          )) : "";
      }
    }

    function getType(uint256 tokenId) public view tokenUrlExist(tokenId) returns (uint8) {
        return types[tokenId];
    }

    function getAttribute(uint256 tokenId) public view tokenUrlExist(tokenId) returns (uint8) {
        return attributes[tokenId];
    }    

    function getName(uint256 tokenId) public view tokenUrlExist(tokenId) returns (uint8) {
        return names[tokenId];
    }

    function getCharactherByIndex(address owner,uint256 index) public view returns(uint256,uint256,address,uint8,uint8,uint8){
        uint256 tokenId = tokenOfOwnerByIndex(owner,index);
        return (index,tokenId,owner,getType(tokenId),getAttribute(tokenId),getName(tokenId));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _baseTokenURI = _baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // function burn(uint256 tokenId) public override onlyOwner {
    //     _burn(tokenId);
    // }

    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}
