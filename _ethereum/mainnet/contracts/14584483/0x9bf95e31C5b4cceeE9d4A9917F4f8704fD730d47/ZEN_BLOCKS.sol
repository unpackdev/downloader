// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: mhxalt.eth
/// @author: seesharp.eth

import "./ERC721A.sol";
import "./IERC20.sol";
import "./Ownable.sol";

/// __/\\\\\\\\\\\\\\\_________________________________________/\\\\\\\\\\\\\____/\\\\\\___________________________________________________________        
///  _\////////////\\\_________________________________________\/\\\/////////\\\_\////\\\_________________________________/\\\______________________       
///   ___________/\\\/__________________________________________\/\\\_______\/\\\____\/\\\________________________________\/\\\______________________      
///    _________/\\\/_________/\\\\\\\\___/\\/\\\\\\_____________\/\\\\\\\\\\\\\\_____\/\\\________/\\\\\________/\\\\\\\\_\/\\\\\\\\_____/\\\\\\\\\\_     
///     _______/\\\/_________/\\\/////\\\_\/\\\////\\\____________\/\\\/////////\\\____\/\\\______/\\\///\\\____/\\\//////__\/\\\////\\\__\/\\\//////__    
///      _____/\\\/__________/\\\\\\\\\\\__\/\\\__\//\\\___________\/\\\_______\/\\\____\/\\\_____/\\\__\//\\\__/\\\_________\/\\\\\\\\/___\/\\\\\\\\\\_   
///       ___/\\\/___________\//\\///////___\/\\\___\/\\\___________\/\\\_______\/\\\____\/\\\____\//\\\__/\\\__\//\\\________\/\\\///\\\___\////////\\\_  
///        __/\\\\\\\\\\\\\\\__\//\\\\\\\\\\_\/\\\___\/\\\___________\/\\\\\\\\\\\\\/___/\\\\\\\\\__\///\\\\\/____\///\\\\\\\\_\/\\\_\///\\\__/\\\\\\\\\\_ 
///         _\///////////////____\//////////__\///____\///____________\/////////////____\/////////_____\/////________\////////__\///____\///__\//////////__

contract ZEN_BLOCKS is ERC721A, Ownable {
  address public ashContract;
  uint256 constant public tokenRefreshPriceInASH = 1000000000000000000; // 1 ASH
  uint256 constant public tokenRefreshPriceInETH = 5000000000000000; // 0.005 ETH

  uint256 public tokenRefreshEndTs = 0;

  uint256 public currentUpgradeId = 0;
  address public dataBlocksContract = address(0x0);
  string public baseURI;

  mapping(uint256 => uint256) public tokenUpgradeStatus;
  mapping(uint256 => uint256) public tokenRefreshRequestStatus;

  uint256 private _royaltyBps;
  address payable private _royaltyRecipient;

  bytes4 constant private _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
  bytes4 constant private _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
  bytes4 constant private _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

  event Upgrade(uint256 indexed tokenId, uint256 indexed upgradeStatus);
  event TokenRefreshRequested(uint256 indexed tokenId);
  event TokenRefreshActivated();

  constructor(string memory name_, 
              string memory symbol_,
              string memory baseURI_,
              address _ashContract) ERC721A(name_, symbol_) {
    baseURI = baseURI_;
    ashContract = _ashContract;
  }


  // since all checks are done @ datablocks, we don't need to check anything
  function mint(address _addr, uint256 _amount) public {
    require(dataBlocksContract != address(0x0), "data blocks contract must be set");
    require(msg.sender == dataBlocksContract, "must be called from data blocks");

    _safeMint(_addr, _amount);
  }

  // multiple upgrades can be applied to a single zen block
  // since all checks are done @ datablocks, we don't need to check any ownership here
  function upgrade(uint256 _tokenId) public {
    require(dataBlocksContract != address(0x0), "data blocks contract must be set");
    require(msg.sender == dataBlocksContract, "must be called from data blocks");
    require(currentUpgradeId != 0, "upgrade id not set");

    require(tokenUpgradeStatus[_tokenId] & currentUpgradeId == 0, "upgrade already applied");
    tokenUpgradeStatus[_tokenId] |= currentUpgradeId;
    emit Upgrade(_tokenId, tokenUpgradeStatus[_tokenId]);
  }

  // returns upgrade status as bitfield. For example if zen block is upgraded in 
  //season 1 and 3, this will return 0b101 = 5
  function upgradeStatusOf(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), "token does not exist");
    return tokenUpgradeStatus[_tokenId];
  }

  function requestTokenRefreshWithASH(uint256 _tokenId) public {
    require(tokenRefreshEndTs != 0, "token refresh period is not open");
    require(block.timestamp <= tokenRefreshEndTs, "token refresh period has ended");

    require(ownerOf(_tokenId) == msg.sender, "not your token");
    require(tokenRefreshRequestStatus[_tokenId] == 1, "not eligible to refresh");
    tokenRefreshRequestStatus[_tokenId] = 0;

    bool success = IERC20(ashContract).transferFrom(msg.sender, address(this), tokenRefreshPriceInASH);
    require(success, "approve contract for ASH");

    emit TokenRefreshRequested(_tokenId);
  }

  function requestTokenRefreshWithETH(uint256 _tokenId) public payable {
    require(tokenRefreshEndTs != 0, "token refresh period is not open");
    require(block.timestamp <= tokenRefreshEndTs, "token refresh period has ended");

    require(ownerOf(_tokenId) == msg.sender, "not your token");
    require(tokenRefreshRequestStatus[_tokenId] == 1, "not eligible to refresh");
    tokenRefreshRequestStatus[_tokenId] = 0;

    require(msg.value >= tokenRefreshPriceInETH, "insufficient funds");

    emit TokenRefreshRequested(_tokenId);
  }

  function tokenRefreshRequestStatusOf(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), "token does not exist");
    return tokenRefreshRequestStatus[_tokenId];
  }

  /**
   * ERC721A overrides
   */
  function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
    return baseURI;
  }

  function _afterTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 // quantity is always 1 for normal transfers
  ) internal virtual override(ERC721A) {
    if (from == address(0) || to == address(0)) {
      return; // do not change at mint or burn
    }
    tokenRefreshRequestStatus[startTokenId] = 1;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
           || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
  }

  /**
   * ADMIN FUNCTIONS
   */
  function activateTokenRefresh() external onlyOwner {
    require(tokenRefreshEndTs == 0, "Already activated");
    tokenRefreshEndTs = block.timestamp + 52 weeks;
    emit TokenRefreshActivated();
  }

  // NOTE: must be set to powers of 2
  function setCurrentUpgradeId(uint256 _currentUpgradeId) external onlyOwner {
    currentUpgradeId = _currentUpgradeId;
  }

  function setDataBlocksContract(address _dataBlocksContract) external onlyOwner {
    dataBlocksContract = _dataBlocksContract;
  }

  function setASHContractAddress(address _ashContract) external onlyOwner {
    ashContract = _ashContract;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function withdraw() external onlyOwner {
    require(_royaltyRecipient != address(0x0), "Must set royalty recipient");

    (bool os, ) = _royaltyRecipient.call{value: address(this).balance}("");
    require(os);
  }

  function withdrawERC20(address erc20_addr) external onlyOwner {
    require(_royaltyRecipient != address(0x0), "Must set royalty recipient");

    IERC20 erc20_int = IERC20(erc20_addr);
    uint256 balance = erc20_int.balanceOf(address(this));

    bool os = erc20_int.transfer(_royaltyRecipient, balance);
    require(os);
  }

  /**
   * ROYALTY FUNCTIONS
   */
  function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
    _royaltyRecipient = recipient;
    _royaltyBps = bps;
  }

  function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
    if (_royaltyRecipient != address(0x0)) {
      recipients = new address payable[](1);
      recipients[0] = _royaltyRecipient;
      bps = new uint256[](1);
      bps[0] = _royaltyBps;
    }
    return (recipients, bps);
  }

  function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
    if (_royaltyRecipient != address(0x0)) {
      recipients = new address payable[](1);
      recipients[0] = _royaltyRecipient;
    }
    return recipients;
  }

  function getFeeBps(uint256) external view returns (uint[] memory bps) {
    if (_royaltyRecipient != address(0x0)) {
      bps = new uint256[](1);
      bps[0] = _royaltyBps;
    }
    return bps;
  }

  function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
    return (_royaltyRecipient, value*_royaltyBps/10000);
  }
  
  receive() external payable {
  }
}