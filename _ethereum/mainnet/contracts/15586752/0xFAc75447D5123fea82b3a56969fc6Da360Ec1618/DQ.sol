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

import "./IERC721Delegable.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC2981.sol";
import "./DQURI.sol";
import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";
import "./BasisPoints.sol";


interface IDQURI {
  function packSVG(uint256 _tokenId, uint256 _sourceTokenId, address _sourceContract) external view returns(string memory);
  function packName(uint256 _tokenId, uint256 _sourceTokenId, address _sourceContract) external view returns(string memory);
  function packDescription(uint256 _tokenId, uint256 _sourceTokenId, address _sourceContract) external view returns(string memory);
  function packVersion(uint256 _tokenId) external view returns(string memory);
  function packSourceContract(uint256 _tokenId, address _sourceContract) external view returns(string memory);
  function packSourceTokenId(uint256 _tokenId, uint256 _sourceTokenId) external view returns(string memory);
  function renderURI(string memory _name, string memory _description, string memory _version, string memory _sourceContract, string memory _sourceTokenId, string memory _svg) external view returns(string memory);
}


interface IRQ is IERC721Delegable, IERC721Enumerable, IERC2981 {
  function getAdmin() external view returns(address);
  function getSource(uint256 _tokenId) external view returns(address, uint256);
}


/**
 * @title DQ
 * @dev Delegate token contract for RQDQ.
 * @author 0xAnimist (kanon.art)
 */
contract DQ is ERC721Enumerable, IERC721Receiver, Ownable {

  // Is initialized flag
  bool public initialized = false;

  // RQ Contract address
  address public RQContract;

  // RQ Contract
  IERC721Delegable private _rq;

  // Contract that generates the look of DQ NFTs
  IDQURI private dqURI;

  // DQ counter
  uint256 public totalDQs = 1;

  struct RoyaltyInfo {
    address receiver;
    uint256 royaltyInBp;
  }

  // Mapping of royalty info for DQ tokens
  mapping(uint256 => RoyaltyInfo) private _royaltyInfos;

  // Maps DQ tokens to RQ pair
  mapping(uint256 => uint256) private _DQTokenIdToRQTokenId;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  modifier onlyRQContract() {
    require(initialized, "Not initialized");
    require(_msgSender() == RQContract, "Only RQ Contract");
    _;
  }

  modifier ifInitialized() {
    require(initialized, "Not initialized");
    _;
  }

  modifier onlyAdmin() {
    IRQ rq = IRQ(RQContract);
    require(_msgSender() == rq.getAdmin(), "Not admin");
    _;
  }

  /**  @notice ERC165-compliancy: checks if the contract supports a given interface id
    *  @param interfaceId interfaceId to check against the supported interfaces
    */
  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
      return
          interfaceId == type(IERC721Enumerable).interfaceId ||
          interfaceId == _INTERFACE_ID_ERC2981 ||
          super.supportsInterface(interfaceId);
  }


  /**  @notice Sets the contract/library that generates the URI for a token
    *  @param _dqURIAddress address of the contract/library
    */
  function setDQURI(address _dqURIAddress) public onlyAdmin {
    dqURI = IDQURI(_dqURIAddress);
  }

  /**  @notice Returns URI for the DQ NFT
    *  @dev Relies on an external contract linked through dqURI
    *  @param _tokenId RQ NFT to query
    *  @return string value of the token URI
    */
  function tokenURI(uint256 _tokenId) override public view ifInitialized returns(string memory) {
    require(_exists(_tokenId), "DQ NFT does not exist");
    IRQ rq = IRQ(RQContract);

    uint256 rqTokenId = _DQTokenIdToRQTokenId[_tokenId];

    /*TODO: change this ownerOf require as the tokenIds won't be matched*/
    require(rq.ownerOf(rqTokenId) != address(0), "RQ NFT does not exist");
    address sourceContract;
    uint256 sourceTokenId;
    (sourceContract, sourceTokenId) = rq.getSource(rqTokenId);

    string memory name_ = dqURI.packName(_tokenId, sourceTokenId, sourceContract);

    string memory description_ = dqURI.packDescription(_tokenId, sourceTokenId, sourceContract);

    string memory version_ = dqURI.packVersion(_tokenId);
    string memory sourceContract_ = dqURI.packSourceContract(_tokenId, sourceContract);
    string memory sourceTokenId_ = dqURI.packSourceTokenId(_tokenId, sourceTokenId);

    string memory svg_ = dqURI.packSVG(_tokenId, sourceTokenId, sourceContract);

    return dqURI.renderURI(name_, description_, version_, sourceContract_, sourceTokenId_, svg_);
  }

  /**  @notice Mints the next DQ NFT, sets it as the delegate for `_rqTokenId` RQ token,
    *  and sends both the DQ and RQ tokens to `_owner` address
    *  @param _owner owner of the token to be minted
    *  @param _rqTokenId tokenId of the corresponding RQ token
    */
  function mint(address _owner, uint256 _rqTokenId) external onlyRQContract {
    require(_msgSender() == RQContract, "DQ: only RQ can mint");
    uint256 dqTokenId = totalDQs;
    _safeMint(_owner, dqTokenId);//start at 0
    _rq.setDelegateToken(address(this), dqTokenId, _rqTokenId);
    _rq.safeTransferFrom(address(this), _owner, _rqTokenId);
    _DQTokenIdToRQTokenId[dqTokenId] = _rqTokenId;
    totalDQs++;

    IRQ rq = IRQ(RQContract);
    (_royaltyInfos[dqTokenId].receiver, _royaltyInfos[dqTokenId].royaltyInBp) = rq.royaltyInfo(_rqTokenId, BasisPoints.BASE);
  }

  /**  @notice Burns a DQ NFT
    *  @param _tokenId tokenId of the token to be burned
    *
  function burn(uint256 _tokenId) external onlyRQContract {
    ERC721._burn(_tokenId);
  }*/

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data) external override returns(bytes4) {

      return IERC721Receiver.onERC721Received.selector;
  }

  /*  @notice Called with the sale price to determine how much royalty
   *          is owed and to whom.
   *  @param _tokenId - the NFT asset queried for royalty information
   *  @param _salePrice - the sale price of the NFT asset specified by _tokenId
   *  @return receiver - address of who should be sent the royalty payment
   *  @return royaltyAmount - the royalty payment amount for _salePrice
   */
  function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
      //defaults to (address(0), 0) if not set
      receiver = _royaltyInfos[_tokenId].receiver;
      royaltyAmount = BasisPoints.mulByBp(_salePrice, _royaltyInfos[_tokenId].royaltyInBp);
    }

  /**
   * @dev Sets a default royalty for `_tokenId` token.
   *
   * Requirements:
   *
   * - caller must be owner of the delegate token of `_tokenId` token
   */
  function setRoyalty(address _receiver, uint256 _royaltyInBp, uint256 _tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "DQ: only owner can set royalty");
    _royaltyInfos[_tokenId].receiver = _receiver;
    _royaltyInfos[_tokenId].royaltyInBp = _royaltyInBp;
  }


  /**  @notice Initializes the contract
    *  @param _RQContract address of the RQ contract
    *  @param _dqURIAddress address of the contract/library that generates the URI of DQ NFTs
    */
  function initialize(address _RQContract, address _dqURIAddress) external onlyOwner {
    require(!initialized, "Already initialized");
    RQContract = _RQContract;
    _rq = IERC721Delegable(RQContract);
    dqURI = IDQURI(_dqURIAddress);
    initialized = true;
  }


  constructor() ERC721("K21 DQ NFT", "K21DQ") Ownable() {
  }

}
