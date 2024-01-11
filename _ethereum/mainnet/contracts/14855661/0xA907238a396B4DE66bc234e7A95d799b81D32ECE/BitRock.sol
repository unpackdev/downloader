// SPDX-License-Identifier: MIT
// site : https://bitrock.cc
// market :  https://opensea.io/collection/bitrocknfts



pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./strings.sol";


contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract BitRock is ERC721Enumerable, ContextMixin, NativeMetaTransaction, Ownable  {
  
// Use safeMath library for doing arithmetic with uint256 and uint8 numbers
  using SafeMath for uint256;

  using SafeMath for uint32;

  using SafeMath for uint16;

  using SafeMath for uint8;

  using strings for *;


  /*************************************************************/
  // The struct for define meteroite
  struct rockAttribute{
      string name; // max length 32
      uint32 diameter; // = meta-km * 100 for floating
      uint8 orbitalAltitude; // = 1 - 20
      uint8 orbitalAngle; // = degree (0 - 179)
      uint32 orbitalPeriod; // = meta-days * 100 for floating
      uint32 rotationPeriod; // = meta-days * 100 for floating
      string parent; // max length 32
      uint mintTime; // unix time
  }

  //This defines the map from tokenID to rockAttribute.
  mapping(uint256 => rockAttribute) private _tokenAttributes;

  //This variable is used to query the uniqueness of tokenname
  mapping(string => bool) private _tokenNames;

  //This variable is used to query the uniqueness of tokenOrbits
  mapping(string => bool) private _tokenOrbits;

  //used to set nature planet in solar from deployment.
  struct naturePlanet{
    string name;
    uint256 diameter;
  }

  //used to store nature planets in solar.
  struct parentParam{
    uint256 diameter;
    bool isNature;
  }

  //uesd to store planets which can used as parent.
  mapping(string => parentParam) private _parentPlanets;
  

  struct allTokenInfos{
    rockAttribute rockAttr;
    address owner;
  }
  /*************************************************************/

  // address to withdraw funds from contract
  address payable private withdrawAddress;

  // maximum number of tokens that can be purchased in one transaction
  uint8 public constant MAX_PURCHASE = 10;

  // maximum number of team tokens that can be free purchased in one transaction.()
  // Only owner and teamMember can mint team token, total teams count is 1000.
  uint256 public constant MAX_TEAM_MINT = 500;

  // public price of a single Rock in wei
  uint256 public constant MET_PRICE_BASIC =   153010000000000000 wei;

  //private price of per meta km in wei 
  uint256 public constant MET_PRICE_SIZE_PRIVATE = 7000000000000 wei;

  //public price of per meta km in wei             
  uint256 public constant MET_PRICE_SIZE_PUBLIC = 70000000000000 wei;

  // freeze contract tokens have persistence tokenURI that can not be changed
  bool public isFreeze;

  // maximum number of Rocks that can be minted on this contract
  uint256 public maxTotalSupply = 10000;

  // private sale current status - active or not
  bool private _privateSale = false;

  // public sale current status - active or not
  bool private _publicSale = false;

  // used minting slots for mint team
  mapping(address => uint256) private _teamSlots; 

  // whitelisted addresses that can participate in the presale event
  mapping(address => uint8) private _whiteList;

  // used minting slots for public sale
  mapping(address => uint8) private _publicSlots;

  // all token URI's map
  mapping(uint256 => string) private _tokenURIs;

  // event that emits when private sale changes state
  event privateSaleState(bool active);

  // event that emits when public sale changes state
  event publicSaleState(bool active);

  // event that emits when next contract start
  event NextContractStartEvent();

  // event that emits when user bought Rocks on public sale
  event tokenMinted(string typeOfMint, address addr, uint256 slots, uint256 totalRemaining, uint256 tokenId, rockAttribute attributes);

  //proxyRegistry Address for opensea.
  address proxyRegistryAddress;

  //team address
  address teamMember;




  constructor (
    naturePlanet[] memory naturePlanets,
    address payable _withdrawAddress,
    address _teamMember,
    address _proxyRegistryAddress
  ) ERC721("BITROCK","BITROCK") {
        withdrawAddress = _withdrawAddress;
        teamMember = _teamMember;
        for(uint8 i=0;i<naturePlanets.length;i++){
          _parentPlanets[naturePlanets[i].name].diameter =  naturePlanets[i].diameter;
          _parentPlanets[naturePlanets[i].name].isNature = true;
        }
        proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
  * @dev check if address is team or owner
  *
  * @return bool if address is team or owner
  */
  function isTeamAddress(address _address) public view virtual returns (bool) {
    return _address == owner() || _address == teamMember;
  }

  /**
  * @dev check if private sale is active now
  *
  * @return bool if private sale active
  */
  function isPrivateSaleActive() public view virtual returns (bool) {
    return _privateSale;
  }

  /**
  * @dev check if public sale is active now
  *
  * @return bool if private sale active
  */
  function isPublicSaleActive() public view virtual returns (bool) {
    return _publicSale;
  }

  /**
  * @dev check if public sale is already finished
  *
  * @return bool if private sale active
  */
  function isPublicSaleEnded() public view virtual returns (bool) {
    return maxTotalSupply == totalSupply();
  }

  /**
  * @dev check address remaining mint slots for team
  *
  * @param _address address ETH address to check
  * @return uint8 remaining slots
  */
  function addressTeamSlots(address _address) public view returns (uint256) {
    if(_address!=owner() && _address!=teamMember){
      return 0;
    }  
    return MAX_TEAM_MINT - _teamSlots[_address];
  }

  /**
  * @dev check address remaining mint slots for private sale
  *
  * @param _address address ETH address to check
  * @return uint8 remaining slots
  */
  function addressPrivateSaleSlots(address _address) public view returns (uint256) {
    return _whiteList[_address];
  }

  /**
  * @dev check address remaining mint slots for public sale
  *
  * @param _address address ETH address to check
  * @return uint8 remaining slots
  */
  function addressPublicSaleSlots(address _address) public view returns (uint256) {
    return MAX_PURCHASE - _publicSlots[_address];
  }

  /**
  * @dev set private sale state
  */
  function setPrivateSaleState(bool state) external onlyOwner {
    _privateSale = state;
    emit privateSaleState(_privateSale);
  }

  /**
  * @dev set public sale state
  */
  function setPublicSaleState(bool state) external onlyOwner {
    _publicSale = state;
    emit publicSaleState(_publicSale);
  }


  /**
  * @dev add ETH addresses to whitelist
  *
  * Requirements:
  * - private sale must be inactive
  * - numberOfTokens should be less than MAX_PURCHASE value
  *
  * @param addresses address[] array of ETH addresses that need to be whitelisted
  * @param numberOfTokens uint8 tokens amount for private sale per address
  */
  function setWhitelistAddresses(address[] calldata addresses, uint8 numberOfTokens) external {
    require(msg.sender == owner() || msg.sender == teamMember,'Sorry,you have not access to set white list.');
    require(!isFreeze, "contract have already frozen!");
    require(!_privateSale, "Private sale is now running!!!");
    require(numberOfTokens <= MAX_PURCHASE, "numberOfTokens is higher that MAX PURCHASE limit!");

    for (uint256 i = 0; i < addresses.length; i++) {
      if (addresses[i] != address(0)) {
        _whiteList[addresses[i]] = numberOfTokens;
      }
    }
  }

  /**
  * @dev remove ETH addresses from whitelist
  *
  * Requirements:
  * - private sale must be inactive
  *
  * @param addresses address[] array of ETH addresses that need to be removed from whitelist
  */
  function removeWhitelistAddresses(address[] calldata addresses) external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    require(!_privateSale, "Private sale is now running!!!");

    for (uint256 i = 0; i < addresses.length; i++) {
      _whiteList[addresses[i]] = 0;
    }
  }


  /**
  * @dev mint new Rock token by team with given 
  * attributes to provided address
  *
  * Requirements:
  * - attributes should be in a valid 
  * - sender should have minting slots
  *
  * @param _attributes is struct with Rocks attributes
  */
  function mintTeamToken(rockAttribute memory _attributes) public payable {
    require(msg.sender == owner() || msg.sender == teamMember,'Sorry,you have not access to mint team.');
    require(totalSupply() + 1 <= maxTotalSupply, "Total Supply limit have reached!");
    require(1 + _teamSlots[msg.sender] <= MAX_TEAM_MINT, "Address team limit have reached!");
    require(checkCanMint(_attributes)==true,"It can't mint because some attribute is invalid.");

    _teamSlots[msg.sender] = uint256(_teamSlots[msg.sender].add(1));
    uint256 tokenId = _mintToken(msg.sender, _attributes);
    emit tokenMinted( 
                    "TEAM",
                    msg.sender, 
                    MAX_TEAM_MINT - _teamSlots[msg.sender], 
                    maxTotalSupply - totalSupply(),
                    tokenId,
                    _attributes
                  );
  }

  /**
  * @dev mint new Rock token with given
  * attributes to provided address
  *
  * Requirements:
  * - private sale should be active
  * - attributes should be in a valid
  * - sender should have private sale minting slots
  * - sender should pay correct price for each token
  *
  * @param _attributes is struct with Rocks attributes
  */
  function mintPrivate(rockAttribute memory _attributes) public payable {
    require(_privateSale, "Private sale is not active!");
    require(totalSupply() + 1 <= maxTotalSupply, "Total Supply limit have reached!");
    require(_whiteList[msg.sender] >= 1, "Not enough presale slots to mint tokens!");
    require(checkCanMint(_attributes)==true,"It can't mint because some attribute is invalid.");
    require(MET_PRICE_BASIC + MET_PRICE_SIZE_PRIVATE * (_attributes.diameter / 100 + 1 )== msg.value, "Ether value sent is not correct!");

    _whiteList[msg.sender] = uint8(_whiteList[msg.sender].sub(1));
    uint256 tokenId = _mintToken(msg.sender, _attributes);

    payable(withdrawAddress).transfer(msg.value);
    emit tokenMinted( 
                        "PRIVATE",
                        msg.sender, 
                        _whiteList[msg.sender], 
                        maxTotalSupply - totalSupply(),
                        tokenId,
                        _attributes
                      );
  }


  /**
  * @dev mint new Rock token with given
  * attributes to provided address
  *
  * Requirements:
  * - public sale should be active
  * - attributes should be in a valid
  * - sender should have public sale minting slots
  * - sender should pay correct price for each token
  *
  * @param _attributes is struct with Rocks attributes
  */
  function mintPublic(rockAttribute memory _attributes) public payable{
    require(_publicSale, "Public sale is not active!");
    require(totalSupply() + 1 <= maxTotalSupply, "Total Supply limit have reached!");
    require(1 + _publicSlots[msg.sender] <= MAX_PURCHASE, "Address limit have reached!");
    require(checkCanMint(_attributes)==true,"It can't mint because some attribute is invalid.");
    require(MET_PRICE_BASIC + MET_PRICE_SIZE_PUBLIC * (_attributes.diameter / 100 + 1 )== msg.value, "Ether value sent is not correct!");

    _publicSlots[msg.sender] = uint8(_publicSlots[msg.sender].add(1));
    uint256 tokenId = _mintToken(msg.sender, _attributes);

    payable(withdrawAddress).transfer(msg.value);
    emit tokenMinted( 
                        "PUBLIC",
                        msg.sender, 
                        MAX_PURCHASE - _publicSlots[msg.sender], 
                        maxTotalSupply - totalSupply(),
                        tokenId,
                        _attributes
                      );
  }


  /**
  * @dev mint new Rock token with given
  * attributes to sender
  *
  * @param _attributes is struct with Rock attributes
  */
  function _mintToken(address to, rockAttribute memory _attributes) private returns(uint256) {
      require(!isFreeze, "Contract have already frozen!");
      uint256 tokenId = totalSupply().add(1);
      _safeMint(to, tokenId);
      _attributes.mintTime = block.timestamp;
      _tokenNames[_attributes.name] = true; //set name is occupied
      _tokenOrbits[getOrbitId(_attributes)] = true; //set orbit is occupied
      _tokenAttributes[tokenId] = _attributes;
      return tokenId;
  }

  /**
  * @dev get the identification code of orbit with
  * given rock attributes
  *
  * @param _attributes is struct with Rock attributes
  * @return string the identification code of orbit
  */
  function getOrbitId(rockAttribute memory _attributes) private pure returns(string memory) {
    string memory altitudeStr =  _uint2str(_attributes.orbitalAltitude);
    string memory splitStr = "|";
    string memory angleStr = _uint2str(_attributes.orbitalAngle);
    return altitudeStr.toSlice().concat(splitStr.toSlice()).toSlice().concat(angleStr.toSlice()).toSlice().concat(splitStr.toSlice()).toSlice().concat(_attributes.parent.toSlice());
  }

  /**
  * @dev check if the given name is exit. 
  * 
  *
  * @param _name is given name
  * @return bool if the given name is exit. 
  */
  function isExitName(string memory _name) public view returns(bool) {
    return _tokenNames[_name];
  }

  /**
  * @dev check if the given name is valid to mint. 
  * 
  *
  * @param _name is given name
  * @return bool if the given name is valid to mint. 
  */
  function isNameValid(string memory _name) public view returns(bool) {
     if(bytes(_name).length < 3 || bytes(_name).length > 32){
       return false;
     }
     if(_name.toSlice().contains("|".toSlice())){
       return false;
     }
     if(_name.toSlice().contains("`".toSlice())){
        return false;
     }
     if(bytes(_name)[bytes(_name).length - 1]==0x20){
        return false;
     }
     if(bytes(_name)[0]==0x20){
        return false;
     }
     if(isParentValid(_name)==true){
        return false;
     }
     for(uint8 idx = 0; idx < bytes(_name).length ; idx++){
        /*AsicII only */
        if(bytes(_name)[idx] > 0x7e || bytes(_name)[idx] < 0x20){
            return false;
        }
        /*Forbiden lowercase*/
        if(bytes(_name)[idx] >= 0x61 && bytes(_name)[idx] <= 0x7a){
            return false;
        }   
     }
     return true;
  }

  /**
  * @dev check if the given orbit is exit. 
  * 
  *
  * @param _attributes is given attribute
  * @return bool if the given orbit is exit. 
  */
  function isExitOrbit(rockAttribute memory _attributes) public view returns(bool){
      return _tokenOrbits[getOrbitId(_attributes)];
  }

  /**
  * @dev check if the parent is valid. 
  * 
  *
  * @param _name is given parent name
  * @return bool if the parent is valid. 
  */
  function isParentValid(string memory _name) public view returns(bool){
    return _parentPlanets[_name].diameter > 0 ;
  }

  /**
  * @dev check if the attribute is valid. 
  * 
  *
  * @param _attributes is given attribute
  * @return bool if the attribute is valid. 
  */
  function isAttributeValid(rockAttribute memory _attributes) public view returns(bool){
    require( isNameValid(_attributes.name) == true ,"Rock's name is invalid.");
    //For float value in solidity, _attributes.diameter(uint256) must be mutipled by 100 before upload. So here for simple calculate,we can let _attributes.diameter derectly compare between with _parentPlanets[_attributes.parent].diameter. 
    require(_attributes.diameter <= _parentPlanets[_attributes.parent].diameter     
            && _attributes.diameter >= _parentPlanets[_attributes.parent].diameter / 100,"Rock's diameter is invalid (valid range: 0.01% - 1% of parent diameter).");
    require(_attributes.orbitalAltitude >=1 && _attributes.orbitalAltitude <=20,"Rock's orbital altitude is invalid.");
    require(_attributes.orbitalAngle >= 0 && _attributes.orbitalAngle <= 179,"Rock's orbital angle is invalid.");
    require(_attributes.orbitalPeriod >= 100 && _attributes.orbitalPeriod <= 10000,"Rock's orbital period is invalid.");//also mutipled by 100 before upload
    require(_attributes.rotationPeriod >= 100 && _attributes.rotationPeriod <= 10000,"Rock's rotation period is invalid.");//also mutipled by 100 before upload
    return true;
  }

  /**
  * @dev check if the given attribute can mint.
  * 
  *
  * @param _attributes is given attribute
  * @return bool if the given attribute can mint.
  */
  function checkCanMint(rockAttribute memory _attributes) public view returns(bool) {
    require(isAttributeValid(_attributes) == true,"Rock's parameter is invalid.");
    require(isExitName(_attributes.name) == false,"There is a same name Rock minted in contract,please change the name.");
    require(isExitOrbit(_attributes) == false,"The orbit you want to mint is occupied by other Rock.");
    require(isParentValid(_attributes.parent) == true,"The parent planet is not exited.");
    return true;
  }

  /**
  * @dev return attributes of given Rock
  *
  * @param tokenId is given token id
  * @return rockAttribute attributes of given Rock
  */
  function tokenAttributes(uint256 tokenId) public view virtual returns (rockAttribute memory) {
    require(_exists(tokenId), "ERC721URIStorage: rockAttribute for nonexistent token");
    return _tokenAttributes[tokenId];
  }

  /**
  * @dev freeze contract to prevent any tokenURI changes
  * and set maxTotalSupply as current total supply
  *
  * Requirements:
  *
  * - `sender` must be contract owner
  */
  function freeze() external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    isFreeze = true;
    maxTotalSupply = totalSupply();
  }

  /**
  * @dev Sets public function that will set
  * `_tokenURI` as the tokenURI of `tokenId`.
  *
  * Requirements:
  *
  * - `tokenId` must exist.
  * - `sender` must be contract owner
  */
  function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
    require(!isFreeze, "contract have already frozen!");
    _setTokenURI(tokenId, _tokenURI);
  }

  /**
  * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = _baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return super.tokenURI(tokenId);
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }


  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
    delete _tokenNames[_tokenAttributes[tokenId].name];
    delete _tokenOrbits[getOrbitId(_tokenAttributes[tokenId])];
    delete _tokenAttributes[tokenId];
  }   

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address owner, address operator)
      override(ERC721, IERC721)
      public
      view
      returns (bool)
  {
      // Whitelist OpenSea proxy contract for easy trading.
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }

  /**
    * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
    */
  function _msgSender()
      internal
      override
      view
      returns (address sender)
  {
      return ContextMixin.msgSender();
  }


  /**
   * @dev format given uint to memory string
   *
   * @param _i uint to convert
   * @return string is uint converted to string
   */
  function _uint2str(uint _i) internal pure returns (string memory) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

}

