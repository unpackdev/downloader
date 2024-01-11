// SPDX-License-Identifier: MIT
// @author Artist: Andrei Molodkin (andreimolodkin.eth)
// @author Dev: Mourad Kejji (mouradif.eth)
pragma solidity 0.8.14;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                         PU                           TI NBLO                                         //
//                                   ODCHA                                 INPUT                                        //
//                                 INBLOOD                                                                              //
//                               CHAI                                                                                   //
//                              NPU                                                TI N                                 //
//                             BL                                                  OODCH                                //
//                             AI                                                  NPUTI                                //
//                            NB                                                    LOODC                               //
//                            HA                                                    INPUTI                              //
//                            N                                                     BLOODC                              //
//                            HA I                                                NPUTINB                               //
//                         LOODCH                                                 AINPUTI NBL                           //
//                          OODCHA                                                 INPUTINBL                            //
//                           OODCH      AINPUTINBLOODCHA     INPUTINBLOODCHAIN      PUTINBLO                            //
//                             ODC    HAINPUTINBLOODCHAIN   PUTINBLOODCHAINPUTIN     BLOO D                             //
//                                            CHA  INPUT    INBLOODCHA   I         NPUT                                 //
//                                                                                INBL OO                               //
//                                                                              DCHAINP                                 //
//                                  UTIN                                       BLOODCHA                                 //
//                                 INPUTI           N          B            LOODCHAI                                    //
//                                  NPUTI          N             BLO       ODCHAINPU                                    //
//                                  TINBLO          ODCH      AINP  U    TINBLOODCHA                                    //
//                                   INPU             TINBLOODCH          AINPUTINBL                                    //
//                                    OODCH            AINPUT          INBLOODCHAINPU                                   //
//                                     TINBLOODCHAINPUTINBLOODCHAINPUTINBLOODCHAINPUTINB                                //
//                                     LOODCHAINPUTI       NBLOODCHAINPUTINBLOODC  HAINPUT                              //
//                                   INBLOODCHAINPUTINBLOODCHAINPUTINBLOODCHAINPU  TINBLOODCH                           //
//                                 AINPUTI  NBLO       ODCHAI         NPUTINBLOO   DCHAINPUTINBLOO                      //
//                             DCHAINPUTINB   LOOD                 CHAINPUTINB     LOODCHAINPUTINBLOODCHAINPU           //
//                      TINBLOODCHAINPUTINB      LOODCHAINPUTINBLOODCHAINPUT      INBLOODCHAINPUTINBLOODCHAINPUT        //
//                INBLOODCHAINPUTINBLOODCHA         INPUTINBLOODCHAINPUTIN        BLOODCHAINPUTINBLOODCHAINPUTIN        //
//            BLOODCHAINPUTINBLOODCHAINPUTIN             BLOODCHAINPUTI          NBLOODCHAINPUTINBLOODCHAINPUTIN        //
//            BLOODCHAINPUTINBLOODCHAINPUTINB              LOODCHAIN             PUTINBLOODCHAINPUTINBLOODCHAINP        //
//            UTINBLOODCHAINPUTINBLOODCHAINPU             TINBLOODCH             AINPUTINBLOODCHAINPUTINBLOODCHA        //
//            INPUTINBLOODCHAINPUTINBLOODCHAIN         PUTINBLOODCHAINP         UTINBLOODCHAINPUTINBLOODCHAINPUT        //
//            INBLOODCHAINPUTINBLOODCHAINPUTIN       BLOODCHAINPUTINBLOODCH     AINPUTINBLOODCHAINPUTINBLOODCHAI        //
//            N              PUTINBLOODCHAINPUT           INBLOODCHAI           NPUTINBLOODCHAINPUTINBLOODCHAINP        //
//                                            UT             INBLOODC           HAINPUTINBLOODCHAINPUTINBLOODCHA        //
//                                                           I      NP         UTINBLOODCHAINPUTINBLOODCHAINPUTI        //
//                                                                             NBLOODCHAINPUTINBLOODCHAINPUTINBL        //
//                                                                            OO                    DCHAINPUTIN         //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./RaribleRoyaltyV2.sol";
import "./LibRoyaltiesV2.sol";

contract PutinBloodChain is ERC721, Ownable, RaribleRoyaltyV2 {
  /**
   * @dev Emitted when an NFT is minted
   */
  event Purchase(uint256 indexed tokenId, address indexed buyer, uint256 indexed timestamp);

  /**
   * @dev Emitted when the funds are transferred to the NGO
   */
  event NGOTransfer(address indexed to, uint256 indexed amount, uint256 indexed timestamp);

  /**
   * @dev URI for serving tokens and contract metadata
   */
  string private __baseURI = "https://putinbloodchain.com/metadata/";

  /**
   * @dev Minting price for one token
   */
  uint256 private _price = 1.25 ether;

  /**
   * @dev Wallet address of the NGO that will receive all the funds
   */
  address public ngo = 0xA59B29d7dbC9794d1e7f45123C48b2b8d0a34636; // uniceffrance.eth

  /**
   * @dev Wallet address of the developer (to get an airdrop of the token #0 serving as Dev's Proof)
   */
  address public dev = 0x9Eb3a30117810d5a36568714EB5350480942f644; // mouradif.eth

  constructor() ERC721("Putin Bloodchain", "PBC") {
    _safeMint(dev, 0);
    _setDefaultRoyalty(ngo, 1000);
  }

  function _baseURI() internal view override returns (string memory) {
    return __baseURI;
  }

  /**
   * @notice The minting price for one token
   */
  function price() public view returns(uint256) {
    return _price;
  }

  /**
   * @dev OpenSea's contract level metadata
   * See: https://docs.opensea.io/docs/contract-level-metadata
   */
  function contractURI() public view returns(string memory) {
    return string(abi.encodePacked(__baseURI, "contract"));
  }

  /**
   * @notice Purchase an NFT (tokenId must be between 1 and 24)
   */
  function buy(uint256 tokenId) public payable {
    require(tokenId > 0 && tokenId < 25, "That token does not exist");
    require(msg.value == _price, "You must send the right amount");
    _safeMint(msg.sender, tokenId);
    emit Purchase(tokenId, msg.sender, block.timestamp);
  }

  /**
   * @notice Transfer the funds to the NGO
   */
  function transferToNGO() public {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to send");
    (bool success, ) = ngo.call{value: balance}("");
    require(success, "Could not process payment");
    emit NGOTransfer(ngo, balance, block.timestamp);
  }

  /**
   * @notice Update the NGO's wallet address
   *  - This function is to be called only in case the destination NGO loses access
   *    to their current wallet and needs to create a new one
   *  - This function can only be called by the contract owner
   */
  function updateNGOWallet(address _new) public onlyOwner {
    ngo = _new;
    _setDefaultRoyalty(_new, 1000);
  }

  /**
   * @notice Updates the Metadata base URI
   *  - This function can only be called by the contract owner
   */
  function setBaseURI(string calldata uri) public onlyOwner {
    __baseURI = uri;
  }

  /**
   * @notice Updates the minting price
   *  - This function can only be called by the contract owner
   */
  function setPrice(uint256 newPrice) public onlyOwner {
    _price = newPrice;
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC721, RaribleRoyaltyV2)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
