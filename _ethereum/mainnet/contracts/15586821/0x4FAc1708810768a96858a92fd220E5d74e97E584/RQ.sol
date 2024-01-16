// SPDX-License-Identifier: MIT


// https://kanon.art - K21
//
//
//                                                      $@@@@@@@@@@@$$$
//                                                  $$@@@@@@$$$$$$$$$$$$$$##
//                                              $$$$$$$$$$$$$$$$$#########***
//                                           $$$$$$$$$$$$$$$#######**!!!!!!
//                                        ##$$$$$$$$$$$$#######****!!!!=========
//                                      ##$$$$$$$$$#$#######*#***!!!=!===;;;;;
//                                    *#################*#***!*!!======;;;:::
//                                   ################********!!!!====;;;:::~~~~~
//                                 **###########******!!!!!!==;;;;::~~~--,,,-~
//                                ***########*#*******!*!!!!====;;;::::~~-,,......,-
//                              ******#**********!*!!!!=!===;;::~~~-,........
//                              ***************!*!!!!====;;:::~~-,,..........
//                            !************!!!!!!===;;::~~--,............
//                            !!!*****!!*!!!!!===;;:::~~--,,..........
//                           =!!!!!!!!!=!==;;;::~~-,,...........
//                           =!!!!!!!!!====;;;;:::~~--,........
//                          ==!!!!!!=!==;=;;:::~~--,...:~~--,,,..
//                          ===!!!!!=====;;;;;:::~~~--,,..#*=;;:::~--,.
//                          ;=============;;;;;;::::~~~-,,...$$###==;;:~--.
//                         :;;==========;;;;;;::::~~~--,,....@@$$##*!=;:~-.
//                         :;;;;;===;;;;;;;::::~~~--,,...$$$$#*!!=;~-
//                          :;;;;;;;;;;:::::~~~~---,,...!*##**!==;~,
//                          :::;:;;;;:::~~~~---,,,...~;=!!!!=;;:~.
//                          ~:::::::::::::~~~~~---,,,....-:;;=;;;~,
//                           ~~::::::::~~~~~~~-----,,,......,~~::::~-.
//                            -~~~~~~~~~~~~~-----------,,,.......,-~~~~~,.
//                             ---~~~-----,,,,,........,---,.
//                              ,,--------,,,,,,.........
//                                .,,,,,,,,,,,,......
//                                   ...............
//                                       .........
//
//0000000000000000000000000000000000000KKKKK0KKKXXXXXNNNNWWWWWNNNX000000000000000000000000000000000000
//
////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

import "./ERC721EnumerableDelegable.sol";
import "./IDQ.sol";
import "./IERC721Dispatcher.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./ERC165Checker.sol";
import "./IERC2981.sol";
import "./BasisPoints.sol";
import "./BytesLib.sol";
import "./Base64.sol";
import "./Strings.sol";

/**
 * @title RQ
 * @dev Wraps ERC721 non-fungible tokens and returns ERC721Delegable
 * token and delegate pair.
 * @author 0xAnimist (kanon.art)
 */
contract RQ is ERC721EnumerableDelegable, IERC721Receiver, IERC2981, ReentrancyGuard, Ownable {

  // Address of DQ contract
  address public _DQContract;

  // DQ contract object
  IDQ private _dq;

  // ERC165 interface ID for ERC2981
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // Stores information about each wrapped source NFT
  struct Source {
    bool valid;
    address sourceContract;
    address royaltyRecipient;
    uint256 sourceTokenId;
    uint256 royaltyInBp;
    uint256 wrappedTimestamp;
  }

  // Stores information about each wrappable NFT
  struct Wrappable {
    address contractAddress;
    uint256 tokenId;
    bool isWrappable;
  }

  // Mapping from token ID to the wrapped source NFT
  mapping(uint256 => Source) private _sources;

  // Mapping from the source NFT contract to source NFT token ID to token ID
  mapping(address => mapping (uint256 => uint256)) private _tokenIdsBySource;

  // Wrappable tokens Whitelists
  mapping(address => mapping(uint256 => Wrappable)) private _wrappableTokens;

  // RQ counter, does not decrement on unwrap
  uint256 public totalRQs = 1;

  /**
   * @dev Emitted when a token is wrapped.
   */
  event Wrapped(uint256 indexed tokenId, address indexed sourceContract, uint256 indexed sourceTokenId, address owner, bytes data);

  /**
   * @dev Emitted when a token is unwrapped.
   */
  event Unwrapped(uint256 indexed tokenId, address indexed sourceContract, uint256 indexed sourceTokenId, address owner, bytes data);

  /**
   * @dev Initializes the contract by setting a `DQContract_` address and a `name` and `symbol` for the token collection.
   */
  constructor(address DQContract_) ERC721("K21 RQ NFT", "K21RQ"){
    _DQContract = DQContract_;
    _dq = IDQ(DQContract_);
  }

  /**
   * @dev Gates access to only the delgate token owner of `_tokenId`
   */
  modifier onlyDelegate(uint256 _tokenId) {
    require(_msgSender() == _getDelegateOwner(_tokenId), "RQ: Not delegate token owner");
    _;
  }

  /**
   * @dev Whitelists tokens that can be wrapped
   */
  modifier onlyWrappableToken(address _contractAddress, uint256 _tokenId) {
    Wrappable memory wrappableToken = _wrappableTokens[_contractAddress][_tokenId];

    require(wrappableToken.isWrappable, "RQ: Token is not whitelisted for wrap");

    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721EnumerableDelegable) returns (bool) {
      return interfaceId == type(ERC721EnumerableDelegable).interfaceId || interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC2981-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
    bool isERC2981 = ERC165Checker.supportsInterface(_sources[tokenId].sourceContract, _INTERFACE_ID_ERC2981);

    if(isERC2981){
      try IERC2981(_sources[tokenId].sourceContract).royaltyInfo(_sources[tokenId].sourceTokenId, salePrice) returns (address _receiver, uint256 _royaltyAmount) {
        return (_receiver, _royaltyAmount);
      } catch {
        return (address(0), 0);
      }
    }else{
      //defaults to (address(0), 0) if not set
      receiver = _sources[tokenId].royaltyRecipient;
      royaltyAmount = BasisPoints.mulByBp(salePrice, _sources[tokenId].royaltyInBp);
    }
  }

  //Address to string encodeing by k06a
  //see: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function toString(address account) internal pure returns(string memory) {
    return toString(abi.encodePacked(account));
  }

  function toString(bytes32 value) internal pure returns(string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes memory data) internal pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }

  /**
   * @dev Sets a default royalty for `_tokenId` token that is invoked
   * if the underlying source NFT is not ERC2981.
   *
   * Requirements:
   *
   * - caller must be owner of the delegate token of `_tokenId` token
   */
  function setRoyalty(address _recipient, uint256 _royaltyInBp, uint256 _tokenId) external onlyDelegate(_tokenId){
    _sources[_tokenId].royaltyRecipient = _recipient;
    _sources[_tokenId].royaltyInBp = _royaltyInBp;
  }

  /**
   * @dev Wraps a source NFT and mints an ERC721EnumerableDelegable NFT
   * to the caller, mints a DQ NFT to the caller and sets it as the
   * delegate token.
   */
  function wrap(address _sourceContract, uint256 _sourceTokenId, bytes calldata _data) external virtual onlyWrappableToken(_sourceContract, _sourceTokenId) nonReentrant {
    IERC721(_sourceContract).safeTransferFrom(_msgSender(), address(this), _sourceTokenId, _data);
  }

  /**
   * @dev Unwraps `_tokenId` token and returns the source NFT to the caller.
   *
   * Requirements:
   *
   * - caller must be owner of the delegate token of `_tokenId` token
   */
  function unwrap(uint256 _tokenId, bytes calldata _data) external onlyDelegate(_tokenId) nonReentrant {
    IERC721(_sources[_tokenId].sourceContract).safeTransferFrom(address(this), _msgSender(), _sources[_tokenId].sourceTokenId, _data);

    _sources[_tokenId].valid = false;
    _burn(_tokenId);

    emit Unwrapped(_tokenId, _sources[_tokenId].sourceContract, _sources[_tokenId].sourceTokenId, _msgSender(), _data);
  }

  /**
   * @dev Adds a token to the Wrappable whitelist and set it's creator and gatedUri
   * @param _contractAddress contract address of the token to be whitelisted
   * @param _tokenId token to be whitelisted
   */
  function addWrappableToken(address _contractAddress, uint256 _tokenId) public onlyOwner {
    _wrappableTokens[_contractAddress][_tokenId] = Wrappable(
      _contractAddress,
      _tokenId,
      true
    );
  }

  /**
   * @dev Removes a token to the Wrappable whitelist
   * @param _contractAddress contract address of the token to be removed from whitelist
   * @param _tokenId token to be removed from whitelist
   */
  function removeWrappableToken(address _contractAddress, uint256 _tokenId) public onlyOwner {
    delete _wrappableTokens[_contractAddress][_tokenId];
  }

  /**
   * @dev Gets the source NFT contract address and token ID for `_tokenId` token.
   * @param _tokenId RQ NFT tokenId to query
   * @return sourceContract source NFT contract address
   * @return sourceTokenId source NFT tokenId
   */
  function getSource(uint256 _tokenId) public view returns(address sourceContract, uint256 sourceTokenId) {
    require(_tokenId < totalRQs, "RQ: tokenId out of bounds");
    return (_sources[_tokenId].sourceContract, _sources[_tokenId].sourceTokenId);
  }

  /**
   * @dev Gets the `tokenId` of the token corresponding to the
   * wrapped source NFT
   * @param _sourceContract source NFT contract address
   * @param _sourceTokenId source NFT token ID
   * @return success true if successful
   * @return tokenId the tokenId
   */
  function getTokenIdBySource(address _sourceContract, uint256 _sourceTokenId) public view returns(bool success, uint256 tokenId) {
    if(_tokenIdsBySource[_sourceContract][_sourceTokenId] > 0){
      return (true, _tokenIdsBySource[_sourceContract][_sourceTokenId]);
    }
    return (false, 0);
  }

  /**
   * @dev Gets the timestamp that the underlying source token of `tokenId` token was wrapped.
   * @param _tokenId token ID
   * @return wrappedTimestamp timestamp when wrapping occured
   */
  function getWrappedTimestamp(uint256 _tokenId) public view returns(uint256 wrappedTimestamp) {
    require(_exists(_tokenId), "RQ: no such token");
    return _sources[_tokenId].wrappedTimestamp;
  }

  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data) external override onlyWrappableToken(_msgSender(), _tokenId) returns(bytes4) {
      if(
        !((_msgSender() == address(this) && _from == address(0)) || (_msgSender() == _DQContract && _from == address(0)))
      ){//not self-minted or minted from DQ
        //wrap the received token
        uint256 newTokenId;
        uint256 existingTokenId = _tokenIdsBySource[_msgSender()][_tokenId];

        if(existingTokenId > 0){//previously wrapped: reassign same tokenId
          newTokenId = existingTokenId;
          _sources[newTokenId].valid = true;
          _sources[newTokenId].wrappedTimestamp = block.timestamp;
        }else{//never wrapped previously
          newTokenId = totalRQs;//start at 1
          _tokenIdsBySource[_msgSender()][_tokenId] = newTokenId;
          Source memory newSource = Source(true, _msgSender(), address(0), _tokenId, 0, block.timestamp);
          _sources[newTokenId] = newSource;
          totalRQs++;
        }

        //mint RQ to DQ Contract
        _safeMint(_DQContract, newTokenId);
        //minting DQ token sets the delegate and returns RQ and DQ to _from
        _dq.mint(_from, newTokenId);
        emit Wrapped(newTokenId, _msgSender(), _tokenId, _from, _data);
      }

      return IERC721Receiver.onERC721Received.selector;
  }

  /**
   * @dev Requests safeTransferFrom() of `_tokenId` token by first
   * requesting approval be set by the owner of the delegate token
   * with `_terms` terms.
   * @param _to address to transfer the token to
   * @param _tokenId token to transfer
   * @param _terms terms of the delegate approval request
   * @param _data data
   */
  function requestSafeTransferFrom (
    address _to,
    uint256 _tokenId,
    bytes memory _terms,
    bytes calldata _data)
  external virtual {
    _requestApproval(_to, _tokenId, _terms, _data);
    safeTransferFrom(ownerOf(_tokenId), _to, _tokenId, _data);
  }

  /**
   * @dev Requests approval be set for `_to` address by the owner
   * of the delegate token with `_terms` terms.
   * @param _to address to transfer the token to
   * @param _tokenId token to transfer
   * @param _terms terms of the delegate approval request
   * @param _data data
   */
  function _requestApproval(address _to, uint256 _tokenId, bytes memory _terms, bytes calldata _data) internal virtual {
    (address delegateContract, uint256 delegateToken) = getDelegateToken(_tokenId);
    address delegate = IERC721(delegateContract).ownerOf(delegateToken);
    //require(IERC165(delegate).supportsInterface(type(IERC721Dispatcher)), "RQ: not a valid dispatcher");

    IERC721Dispatcher(delegate).requestApproval(_msgSender(), _to, address(this), _tokenId, _terms, _data);
  }

  /**
   * @dev Returns URI for the wrapped token by passing through the URI from the source
   * @param _tokenId RQ NFT token to query
   * @return string value of the token URI
   */
  function tokenURI(uint256 _tokenId) override public view returns(string memory) {
    address sourceOwner = IERC721(_sources[_tokenId].sourceContract).ownerOf(_sources[_tokenId].sourceTokenId);

    if(sourceOwner == address(this)){
      return IERC721Metadata(_sources[_tokenId].sourceContract).tokenURI(_sources[_tokenId].sourceTokenId);
    }else{//re-wrapped token, can be rugged
      string memory metadata = '{"name":"Recursive RQ", "description":"This token is the product of wrapping an ERC721Delegable token, which means it can and likely will get rugged. Buy it at your own risk.",';

      string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: monospace; font-size: 14px; }</style><rect width="100%" height="100%" fill="blue" /><text x="10" y="20" class="base">500</text></svg>';

      string memory json = Base64.encode(bytes(string(abi.encodePacked(
        metadata,
        '"image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '"}'))));

      return string(abi.encodePacked('data:application/json;base64,', json));
    }
  }

  /**
   * @dev Used to catch and route custom functions implemented by the source token.
   */
  fallback() external payable {
    //replace tokenId with sourceTokenId
    bytes memory methodId = new bytes(4);
    methodId = msg.data[0:4];
    bytes memory sourceTokenIdInBytes = new bytes(32);
    sourceTokenIdInBytes = msg.data[4:36];
    bytes memory prefix = new bytes(36);
    prefix = BytesLib.concat(methodId, sourceTokenIdInBytes);
    bytes memory payload = new bytes(msg.data.length - 36);
    payload = msg.data[36:];
    bytes memory data = new bytes(msg.data.length);
    data = BytesLib.concat(prefix, payload);

    //get source contract and source token ID
    uint256 tokenId = uint256(bytes32(msg.data[4:36]));
    uint256 sourceTokenId;
    address sourceContract;
    (sourceContract, sourceTokenId) = getSource(tokenId);

    //route call to source
    address(sourceContract).call{value:msg.value, gas:gasleft()}(data);
  }
}
