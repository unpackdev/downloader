// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC1155Holder.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./NFT1155.sol";


contract Sale1155 is ERC1155Holder, Ownable {
  event CancelSellToken(uint256 indexed tokenId, uint256 amount);
  event SetReceiver(address receiver);
  event UpdatePrice(uint256 _tokenId, uint256 _price);

  struct AskEntry {
      uint256 tokenId;
      uint256 price;
      bool exist;
  }

  NFT1155 public nft;
  mapping(uint256 => AskEntry) private asks;
  uint256[] public tokenIds;
  address receiver;


  constructor(address _nft) {
    require(_nft != address(0) && _nft != address(this));
    nft = NFT1155(_nft);
    receiver = _msgSender();
  }

  function setAsk(uint256 _tokenId, uint256 _price) internal {
    AskEntry storage askEntry = asks[_tokenId];

    askEntry.tokenId = _tokenId;
    askEntry.price = _price;
    askEntry.exist = true;

    tokenIds.push(_tokenId);
  }


  function addNewToken(uint256 _tokenId, uint256 _price, uint256 _quatity) external onlyOwner {
    require(_price > 0, 'price must be granter than zero');
    require(_quatity > 0, 'quatity must be granter than zero');

    nft.safeTransferFrom(address(msg.sender), address(this), _tokenId, _quatity, '0x');
    if(!asks[_tokenId].exist){
      setAsk(_tokenId, _price);
    }
  }

  function addNewTokenBatch(
    uint256[] memory _tokenIds,
    uint256[] memory _price,
    uint256[] memory _quatities
  ) external onlyOwner {
    require(_tokenIds.length == _price.length, "ERC1155: ids and price length mismatch");
    require(_tokenIds.length == _quatities.length, "ERC1155: ids and quatity length mismatch");

    nft.safeBatchTransferFrom(address(msg.sender), address(this), _tokenIds, _quatities, '0x');

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      if(!asks[_tokenIds[i]].exist){
        setAsk(_tokenIds[i], _price[i]);
      }
    }
  }

  function updateTokenPrice(uint256 _tokenId, uint256 _price) external onlyOwner {
    require(_price > 0, 'price must be granter than zero');
    AskEntry storage askEntry = asks[_tokenId];
    askEntry.price = _price;
    emit UpdatePrice(_tokenId,_price);
  }

  function cancelSellToken(uint256 _tokenId) external onlyOwner {
    AskEntry storage askEntry = asks[_tokenId];
    require(askEntry.exist, 'not in sell book');
    uint256 balance = nft.balanceOf(address(this), _tokenId);
    require(balance > 0, 'no token exist');

    nft.safeTransferFrom(address(this), owner(), _tokenId, balance, '0x');
    emit CancelSellToken(_tokenId, balance);
  }

  function buyToken(uint256 _tokenId) public payable {
    require(msg.sender != address(0) && msg.sender != address(this), 'wrong sender');
    uint256 balance = nft.balanceOf(address(this), _tokenId);
    require(balance > 0, 'out of stock');

    AskEntry storage askEntry = asks[_tokenId];
    require(msg.value == askEntry.price, 'balance too low');

    (bool sent, ) = payable(receiver).call{value: msg.value}("");
    require(sent, "Failed to send Ether");

    nft.safeTransferFrom(address(this), msg.sender, askEntry.tokenId, 1, '0x');
  }

  function getAsks(uint256 _tokenId) view external returns(uint256, uint256, uint256) {
    uint256 balance = nft.balanceOf(address(this), _tokenId);
    return (asks[_tokenId].tokenId, asks[_tokenId].price, balance);
  }

  function setReceiver(address _address) external onlyOwner{
    require(_address != address(0) && _address != address(this), 'wrong receiver');
    receiver = _address;
    emit SetReceiver(_address);
  }
}
