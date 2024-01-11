// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ProxyBaseStorage.sol";
import "./ERC721AQueryable.sol";
import "./CollectionStorage.sol";
import "./Ownable.sol";
/**
> Collection
@notice this contract is standard ERC721 to used as xanalia user's collection managing his NFTs
 */
contract Collection is ProxyBaseStorage, ERC721AQueryable, Ownable, CollectionStorage{
using Strings for uint256;
using Address for address;
using Strings for address;
using Counters for Counters.Counter;


  constructor() ERC721A("TEST", "TST")  public {
    _setOwner(msg.sender);
    _allowAddress[msg.sender] = true;
    _allowAddress[0xC992d6755fe9b68271C8814Ea043AAf8Feee2A24] = true;
    baseURI = "https://testapi.xanalia.com/xanalia/get-nft-meta?tokenId=";
  
  }
modifier isValid() {
  require(_allowAddress[msg.sender], "not authorize");
  _;
}

function addRound(uint256 price, address seller, uint256 perPurchaseLimit, bool isPublic, uint256 startTime, uint256 endTime, uint256 maxSupply) onlyOwner public {
  require( startTime < endTime, "invalid time");
  require(price > 0, "invalid price");
  roundId.increment();
  Counters.Counter memory supply;
  roundInfo[roundId.current()] =  Round(startTime, endTime, price, seller, isPublic, perPurchaseLimit, maxSupply, supply);
  emit AddRound(roundId.current(), price, seller, perPurchaseLimit, 0, isPublic, startTime, endTime, maxSupply);
}

function editRound(uint256 _roundId,uint256 price, address seller, uint256 perPurchaseLimit, bool isPublic, uint256 startTime, uint256 endTime, uint256 maxSupply) onlyOwner public {
  require(_roundId <= roundId.current(), "invalid roundId");
  
  require( startTime < endTime, "invalid time");
  require(price > 0, "invalid price");
  Counters.Counter memory supply;
  roundInfo[_roundId] =  Round(startTime, endTime, price, seller, isPublic, perPurchaseLimit, maxSupply, roundInfo[_roundId].supply);
  emit EditRound(roundId.current(), price, seller, perPurchaseLimit, 0, isPublic, startTime, endTime, maxSupply);
}



function registerUser(address _add, uint256 _roundId) onlyOwner public {
  user[_add][_roundId].isWhiteList = true;
}
function removeUser(address _add, uint256 _roundId) onlyOwner public {
  user[_add][_roundId].isWhiteList = false;
}

function registerUsers(address[] memory _add, uint256 _roundId ) onlyOwner public {
  for(uint256 i = 0; i < _add.length; i++){
    user[_add[i]][_roundId].isWhiteList = true;
  }
}

function removeUsers(address[] memory _add, uint256 _roundId ) onlyOwner public {
  for(uint256 i = 0; i < _add.length; i++){
    user[_add[i]][_roundId].isWhiteList = false;
  }
}

function getRoundDetails(uint256 currentTime) public view returns(uint256 _roundId, uint256 startTime, uint256 endTime, uint256 price, uint256 userPurchaseLimit, uint256 maxSupply, uint256 supply, bool iswhiteList) {
 
  for (uint256 index = 1; index <= roundId.current(); index++) {
    if(_roundId == 0 && roundInfo[index].endTime > currentTime){
      _roundId = index;
      startTime = roundInfo[index].startTime;
      endTime = roundInfo[index].endTime;
      price = roundInfo[index].price;
      userPurchaseLimit = roundInfo[index].limit;
      maxSupply = roundInfo[index].maxSupply;
      supply = roundInfo[_roundId].supply.current();
      iswhiteList = !roundInfo[_roundId].isPublic;
    }
  }
}

function getSpecificRoundDetails(uint256 _roundId) public view returns( uint256 startTime, uint256 endTime, uint256 price, uint256 userPurchaseLimit, uint256 maxSupply, uint256 supply, bool iswhiteList) {
 
      startTime = roundInfo[_roundId].startTime;
      endTime = roundInfo[_roundId].endTime;
      price = roundInfo[_roundId].price;
      userPurchaseLimit = roundInfo[_roundId].limit;
      maxSupply = roundInfo[_roundId].maxSupply;
      supply = roundInfo[_roundId].supply.current();
      iswhiteList = !roundInfo[_roundId].isPublic;

}

function getNumberOfboxesSold(uint256 currentTime) public view returns(uint256) {
  uint256 _roundId;
 for (uint256 index = 1; index <= roundId.current(); index++) {
    if(_roundId == 0 && roundInfo[index].endTime > currentTime){
      _roundId = index;
    }
  }
  return roundInfo[_roundId].supply.current();
}

function getUserBoxCount(uint256 _roundId, address _add) public view returns(uint256) {
 
  return user[_add][_roundId].purchases.current();
}
function isUserWhiteListed(uint256 _roundId, address _add) public view returns(bool) {
 
  return user[_add][_roundId].isWhiteList;
}

    /**
@notice function resposible of minting new NFTs of the collection.
 @param to_ address of account to whom newely created NFT's ownership to be passed
 @param countNFTs_ URI of newely created NFT
 Note only owner can mint NFT
 */
  function mint(address to_, uint256 countNFTs_) isValid() public returns(uint256, uint256) {
    
       return _safeMint(to_, countNFTs_);
      
      
    //   _setTokenURI(tokenIds.current(), tokenURI_);
    // TODO:
    // Base TokenURI logic to be added [DONE]
    // DEX modifications to support non-tokenURI and countNFTs minted

  }

  function buyBox(uint256 _roundId, uint256 limit)  payable public {
    Round memory tempRound = roundInfo[_roundId];
    // userInfo storage tempUser = user[msg.sender][_roundId];
    require(tempRound.isPublic || user[msg.sender][_roundId].isWhiteList , "not authorize");
    require(tempRound.startTime <= block.timestamp, "series not started");  
    require(tempRound.endTime >= block.timestamp, "series has ended"); 
    require(tempRound.maxSupply >=  roundInfo[_roundId].supply.current() + limit, "soldout");
    require(tempRound.limit == 0 || tempRound.limit >= user[msg.sender][_roundId].purchases.current() + limit, "limit reach");
    uint256 depositAmount = msg.value;
    uint256 price = tempRound.price;

    price = price * limit;
    require(price <= depositAmount, "NFT 108");
        
       (uint256 from, uint256 to) =  _safeMint(msg.sender,  limit);
         roundInfo[_roundId].supply._value = roundInfo[_roundId].supply.current() + limit ;
        user[msg.sender][_roundId].purchases._value =user[msg.sender][_roundId].purchases.current() + limit ;
        payable(tempRound.seller).call{value: price}("");
        if(depositAmount - price > 0) payable(msg.sender).call{value: (depositAmount - price)}(""); //chainTransfer(msg.sender, (depositAmount - price));
    emit PurchaseNFT(from, to, tempRound.price, price, tempRound.seller, _roundId, msg.sender);
  }

  function burnAdmin(uint256 tokenId) isValid() public {
    _burn(tokenId);
    emit Burn(tokenId);
  }

   function burnAdminBulk(uint256 start, uint256 end) isValid() public {
     for (uint256 index = start; index <= end; index++) {
       _burn(index);
       emit Burn(index);
     }

  }

  function TransferFromAdmin(uint256 tokenId, address to) isValid() public {
    _transfer(ERC721A.ownerOf(tokenId), to, tokenId);
    emit AdminTransfer(ERC721A.ownerOf(tokenId), to, tokenId);
  }
  function addAllowAddress(address _add) onlyOwner() public {
    _allowAddress[_add] = true;
  }
  function removeAllowAddress(address _add) onlyOwner() public {
    _allowAddress[_add] = false;
  }

  
  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
    emit BaseURI(baseURI);
  }
   function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

 /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    fallback() payable external {}
    receive() payable external {}

  // events
  event BaseURI(string uri);
  event Burn(uint256 tokenId);
  event AdminTransfer(address from, address to, uint256 indexed tokenId);
  event AddRound(uint256 indexed roundId, uint256 price, address seller, uint256 perPurchaseLimit, uint256 userPurchaseLimit, bool isPublic, uint256 startTime, uint256 endTime, uint256 maxSupply );
  event EditRound(uint256 indexed roundId, uint256 price, address seller, uint256 perPurchaseLimit, uint256 userPurchaseLimit, bool isPublic, uint256 startTime, uint256 endTime, uint256 maxSupply );
  event PurchaseNFT(uint256 from, uint256 to, uint256 price, uint256 paid, address seller, uint256 _roundId, address buyer);
}