//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GorillaBitsI.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

import "./ERC1155Holder.sol";

/**
 * @dev GorillaBitsBridge is bridging a 1155 Borilla Bits into a 721 custom contract
 */
contract GorillaBitsBridgeEth is ERC1155Holder, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using SafeERC20 for IERC20;

  /**
   * @dev total bridged NFTs
   */
  uint32 public totalBridged;

  /**
   * received NFTs (not yet claimed and transformed into 721)
   */
  uint256[] public idsReceived;

  /**
   * @dev received and successfully claimed (this contains newly 721 ids)
   */
  uint16[] public idsBridged;

  /**
   * @dev in case something goes bad, to stop claiming
   */
  bool public enabled;

  /**
   * @dev keeps all the ids that are sent and the owners of them
   */
  mapping(uint256 => address) public idsAndSenders;
  mapping(address => uint256[]) public sendersAndIds;

  /**
   * @dev olds OS ids bridged
   */
  mapping(address => uint256[]) public oldIdsBridgedBySender;

  /**
   * @dev signer of the bridging
   */
  address private signer;

  /**
   * @dev OpenSea and GorillaBits contract
   */
  IERC1155 public osContract;
  GorillaBitsI public gbContract;

  event ReceivedFromOS(address indexed _sender, address indexed _receiver, uint256 indexed _tokenId, uint256 _amount);

  event Minted721(address indexed _sender, uint256 indexed _tokenId);

  event ToggleBridging(bool _enabled);

  event TokenRecovered(address indexed _token, address _destination, uint256 _amount);

  constructor() {}

  /**
   * @dev triggered by 1155 transfer only from openSea
   */
  function onERC1155Received(
    address _sender,
    address _receiver,
    uint256 _tokenId,
    uint256 _amount,
    bytes calldata _data
  ) public override nonReentrant returns (bytes4) {
    require(msg.sender == address(osContract), "Forbidden");
    require(enabled, "Bridging is stopped");

    triggerReceived1155(_receiver, _tokenId);

    emit ReceivedFromOS(_sender, _receiver, _tokenId, _amount);
    return super.onERC1155Received(_sender, _receiver, _tokenId, _amount, _data);
  }

  /***********External**************/
  /**
   * @dev claiming a token based on a signature
   */
  function claim(
    uint256 _oldId,
    uint16 _newId,
    address _account,
    string calldata _network,
    bytes calldata _signature
  ) external nonReentrant {
    require(enabled, "Bridging is stopped");
    require(_account == msg.sender, "Not the owner");
    require(verify(_oldId, _newId, _account, _network, _signature), "Not approved");
    totalBridged++;
    idsBridged.push(_newId);
    oldIdsBridgedBySender[msg.sender].push(_oldId);

    mintOnClaiming(msg.sender, _newId);
  }

  /**
   * @dev owner minting 721
   */

  function mint721(uint16 _tokenId, address _to) external onlyOwner {
    require(_to != address(0), "Mint to address 0");
    require(!gbContract.exists(_tokenId), "Token exists");

    if (gbContract.exists(_tokenId) && gbContract.ownerOf(_tokenId) == address(this)) {
      gbContract.safeTransferFrom(address(this), _to, _tokenId);
      return;
    }
    _mint721(_tokenId, _to);
  }

  /***********Private**************/

  /**
   * @dev minting 721 to the owner
   */
  function _mint721(uint16 _tokenId, address _owner) private {
    gbContract.mint(_owner, uint16(_tokenId));
    emit Minted721(_owner, _tokenId);
  }

  /**
   * @dev update params once we receive a transfer from 1155
   * the sender can not be address(0) and tokenId needs to be allowed
   */
  function triggerReceived1155(address _sender, uint256 _tokenId) internal {
    require(_sender != address(0), "Update from address 0");

    idsReceived.push(_tokenId);
    idsAndSenders[_tokenId] = _sender;
    sendersAndIds[_sender].push(_tokenId);
  }

  /**
   * @dev minting when claiming
   */
  function mintOnClaiming(address _sender, uint16 _tokenId) internal {
    require(_sender != address(0), "Can not mint to address 0");
    require(_tokenId != 0, "New token id !exists");

    require(!gbContract.exists(_tokenId), "Token already minted");

    gbContract.mint(_sender, _tokenId);
    emit Minted721(_sender, _tokenId);
  }

  /***********Setters**************/

  /**
   * @dev sets Gorilla Bits 721 token
   */
  function setGBContract(GorillaBitsI _contract) external onlyOwner {
    require(address(_contract) != address(0), "_contract !address 0");
    gbContract = _contract;
  }

  /**
   * @dev sets Gorilla Bits 721 token
   */
  function setOSContract(IERC1155 _contract) external onlyOwner {
    require(address(_contract) != address(0), "_contract !address 0");
    osContract = _contract;
  }

  /**
   * @dev sets an approved claimer of the 721
   */
  function setSigner(address _signer) external onlyOwner {
    require(_signer != address(0), "_signer !address 0");
    signer = _signer;
  }

  /***********Views**************/

  function verify(
    uint256 _oldId,
    uint16 _newId,
    address _owner,
    string calldata _network,
    bytes calldata _signature
  ) internal view returns (bool) {
    return signer == keccak256(abi.encodePacked(_oldId, _newId, _owner, _network)).toEthSignedMessageHash().recover(_signature);
  }

  /***********Getters**************/

  /**
   * @dev get the ids already transferred by a collector
   */
  function getTransferredByCollector(address _collector) external view returns (uint256[] memory) {
    require(_collector != address(0), "_collector is address 0");
    return sendersAndIds[_collector];
  }

  /**
   * @dev get the ids that were bridged by collector
   */
  function getBridgedByCollector(address _collector) external view returns (uint256[] memory) {
    require(_collector != address(0), "_collector is address 0");
    return oldIdsBridgedBySender[_collector];
  }

  /**
   * @dev get total transfer count
   */
  function getTokenBridgedCount() external view returns (uint128) {
    return totalBridged;
  }

  /**
   * @dev get bridged ids (claimed already), this will be the new 721 ids
   */
  function getBridgedTokens() external view returns (uint16[] memory) {
    return idsBridged;
  }

  /**
   * @dev get ids of tokens that were transfered to the bridge
   */
  function getIdsTransfered() external view returns (uint256[] memory) {
    return idsReceived;
  }

  function isTransferred(uint256 _id) external view returns (bool) {
    for (uint256 i; i < idsReceived.length; i++) {
      if (idsReceived[i] == _id) return true;
    }
    return false;
  }

  /***********Emergency**************/

  /**
   * @dev can enable/disable claiming and bridging
   */
  function toggleBridging(bool _enabled) external onlyOwner {
    enabled = _enabled;
    emit ToggleBridging(_enabled);
  }

  /**
   * @notice Recover NFT sent by mistake to the contract
   * @param _nft the NFT address
   * @param _destination where to send the NFT
   * @param _tokenId the token to want to recover
   */
  function recoverNFT(
    address _nft,
    address _destination,
    uint256 _tokenId
  ) external onlyOwner {
    require(_destination != address(0), "Destination can not be address 0");
    IERC721(_nft).safeTransferFrom(address(this), _destination, _tokenId);
    emit TokenRecovered(_nft, _destination, _tokenId);
  }

  /**
   * @notice Recover NFT sent by mistake to the contract
   * @param _nft the 1155 NFT address
   * @param _destination where to send the NFT
   * @param _tokenId the token to want to recover
   * @param _amount amount of this token to want to recover
   */
  function recover1155NFT(
    address _nft,
    address _destination,
    uint256 _tokenId,
    uint256 _amount
  ) external onlyOwner {
    require(_destination != address(0), "Destination can not be address 0");
    IERC1155(_nft).safeTransferFrom(address(this), _destination, _tokenId, _amount, "");
    emit TokenRecovered(_nft, _destination, _tokenId);
  }

  /**
   * @notice Recover TOKENS sent by mistake to the contract
   * @param _token the TOKEN address
   * @param _destination where to send the NFT
   */
  function recoverERC20(address _token, address _destination) external onlyOwner {
    require(_destination != address(0), "Destination can not be address 0");
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(address(this), _destination, amount);
    emit TokenRecovered(_token, _destination, amount);
  }
}
