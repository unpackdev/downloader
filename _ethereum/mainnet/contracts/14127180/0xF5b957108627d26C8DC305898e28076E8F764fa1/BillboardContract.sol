// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./IMarket.sol";
import "./IMedia.sol";
import "./IERC20.sol";
import "./Initializable.sol";

interface ERC721Owner {
  function ownerOf(uint256 token) external view returns (address);
}

/// @title Billboards colective contracts
/// @author The Coinvise Team
/// @notice This contract implements functionalities from the zora Contracts - https://github.com/ourzora/core
/// @dev a number of the logic here actually happens in the zora contracts
contract BillboardsCollective is IERC721Receiver, Initializable {
  using SafeMath for uint256;

  /// @notice Mapping of address to boolean
  mapping(address => bool) public isAdmin;

  /// @notice Address of WETH
  address wethAddress;

  /// @notice address of the zora contracts
  IMedia MediaContract;
  IMarket MarketContract;

  ERC721Owner MediaOwner;

  IERC20 wethInstance;

  address mainAdmin;

  /// @notice Emitted when contract WETH balance is withdrawn
  /// @param _to The address the balance was sent to
  /// @param _contractBal The amount of the contract balance that was sent
  event ContractBalanceWithdrawn(address _to, uint256 _contractBal);

  /// @notice restricts function call to only admin wherever applied
  modifier onlyAdmin() {
    require(
      isAdmin[msg.sender] == true,
      "only an admin can call this function"
    );
    _;
  }

  /// @notice restricts function call to only main admin wherever applied
  modifier onlyMainAdmin() {
    require(
      msg.sender == mainAdmin,
      "only the main admin can call this function"
    );
    _;
  }

  /// @notice BillboardsCollective constructor
  /**
   * @dev We cannot have constructors in upgradeable contracts,
   *      therefore we define an initialize function which we call
   *      manually once the contract is deployed.
   *      the initializer modififer ensures that this can only be called once.
   *      in practice, the openzeppelin library automatically calls the initialize
   *      function once deployed.
   */
  /// @param _mainAdmin Address of the main admin (super admin)
  /// @param _mediaContractAddress is the address of zora media contract
  /// @param _marketContractAddress is the address if zora market contract
  /// @param _wethAddress Address of WETH
  function initialize(
    address _mainAdmin,
    address _mediaContractAddress,
    address _marketContractAddress,
    address _wethAddress
  ) public initializer {
    MediaContract = IMedia(_mediaContractAddress);
    MarketContract = IMarket(_marketContractAddress);
    MediaOwner = ERC721Owner(_mediaContractAddress);
    wethAddress = _wethAddress;
    wethInstance = IERC20(_wethAddress);
    mainAdmin = _mainAdmin;
    isAdmin[_mainAdmin] = true;
  }

  function viewMainAdmin() public view returns (address) {
    return mainAdmin;
  }

  function addAdmin(address _newAdmin) public onlyMainAdmin {
    isAdmin[_newAdmin] = true;
  }

  function removeAdmin(address _adminAddress) public onlyMainAdmin {
    require(
      isAdmin[_adminAddress] == true,
      "this address is currently not an admin"
    );
    isAdmin[_adminAddress] = false;
  }

  /// @notice This function mints a Media, it calls the mint function in the zora Media contract
  /// @dev This function is only callable by admin
  /// @param tokenURI A valid URI of the content represented by this token
  /// @param metadataURI A valid URI of the metadata associated with this token
  /// @param contentHash A SHA256 hash of the content pointed to by tokenURI
  /// @param metadataHash A SHA256 hash of the content pointed to by metadataURI
  function MintMedia(
    string memory tokenURI,
    string memory metadataURI,
    bytes32 contentHash,
    bytes32 metadataHash
  ) public onlyAdmin {
    IMedia.MediaData memory newData = IMedia.MediaData(
      tokenURI,
      metadataURI,
      contentHash,
      metadataHash
    );
    IMarket.BidShares memory bid_Share = IMarket.BidShares(
      Decimal.D256(0 * 10**18),
      Decimal.D256(15 * 10**18),
      Decimal.D256(85 * 10**18)
    );

    MediaContract.mint(newData, bid_Share);
  }

  /**
   * @notice This function mints mulitple Medias, it calls the mint function in the zora Media contract,
   * The zora contracts doesn't have a function to batch Mint, we only pass arrays here
   */
  /// @dev This function is only callable by admin - it takes an array of parameters described in the next lines
  /// @param allTokenURI an array of valid URIs of the contents represented by this tokens
  /// @param allMetadataURI an array of valid URIs of the metadata associated with this tokens
  /// @param allContentHash an array of SHA256 hash of the contents pointed to by each tokenURI
  /// @param allMetadataHash an array of SHA256 hash of the contents pointed to by each metadataURI
  /// @return returns boolean value
  function BatchMintMedia(
    string[] memory allTokenURI,
    string[] memory allMetadataURI,
    bytes32[] memory allContentHash,
    bytes32[] memory allMetadataHash
  ) public onlyAdmin returns (bool) {
    for (uint256 i = 0; i < allTokenURI.length; i++) {
      IMedia.MediaData memory newData = IMedia.MediaData(
        allTokenURI[i],
        allMetadataURI[i],
        allContentHash[i],
        allMetadataHash[i]
      );
      IMarket.BidShares memory bid_Share = IMarket.BidShares(
        Decimal.D256(0 * 10**18),
        Decimal.D256(15 * 10**18),
        Decimal.D256(85 * 10**18)
      );
      MediaContract.mint(newData, bid_Share);
    }
    return true;
  }

  /// @notice Function to get the owner of a media
  /// @param tokenId The id of the media
  /// @return The address of the owner
  function OwnerOfMedia(uint256 tokenId) public view returns (address) {
    return MediaOwner.ownerOf(tokenId);
  }

  /// @notice this function returns bidshares on a particular Media when it is sold
  /// @param tokenId id of the media
  /// @return returns the bid shares
  function MediaBidShares(uint256 tokenId)
    public
    view
    returns (IMarket.BidShares memory)
  {
    return MarketContract.bidSharesForToken(tokenId);
  }

  /// @notice this function is an implementation from the openzepellin IERC721Reciever
  /**
   * @dev Whenever an IERC721 tokenId token is transferred to this contract via IERC721.safeTransferFrom by operator from `from`,
   * this function is called.
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /// @notice this functionality implements the set Ask in zora contracts
  /// @dev the actual logic happens in the zora contracts
  /// @param _amount the amount to set on the Media
  /// @param _tokenId the id of the media
  function setToSale(uint256 _amount, uint256 _tokenId) public {
    IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethAddress);
    MediaContract.setAsk(_tokenId, saleCondition);
  }

  /// @notice this functionality implements the setAsk for multiple Media in a single function call with uniform amount
  /// @dev zora Media contract doesn't have a function to batch setAsk, we only pass in an array of ids from here
  /// @param _amount amount to set the Medias to
  /// @param _tokenIds an array of token Ids
  function batchSetSale(uint256 _amount, uint256[] memory _tokenIds) public {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IMarket.Ask memory saleCondition = IMarket.Ask(_amount, wethAddress);
      MediaContract.setAsk(_tokenIds[i], saleCondition);
    }
  }

  /// @notice Function to see the current ask price on a tokenId
  /// @param tokenId The tokenId of the Media
  /// @return uint256 The ask price of the tokenId
  function currentAskPrice(uint256 tokenId) public view returns (uint256) {
    return MarketContract.currentAskForToken(tokenId).amount;
  }

  /// @notice Function to see the current WETH balance
  /// @return uint256 The current WETH balance
  function wethBalanceOfContract() public view returns (uint256) {
    return wethInstance.balanceOf(address(this));
  }

  /// @notice Function to withdraw the current WETH balance
  /// @param _wallet The address to send the WETH to
  function withdrawContractBalance(address _wallet) public onlyMainAdmin {
    uint256 wethBal = wethBalanceOfContract();
    wethInstance.transfer(_wallet, wethBal);

    emit ContractBalanceWithdrawn(_wallet, wethBal);
  }
}
