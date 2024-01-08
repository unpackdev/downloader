// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract ChibiBridgeManager is Ownable, ReentrancyGuard, IERC721Receiver {
  event MultiBridged(address sender, uint[] _ids);
  event Bridged(address sender, uint _id);

  event ReverseMultiBridged(address receiver, uint[] _ids);
  event ReverseBridged(address receiver, uint _id);

  address public minter;
  uint256 public arrayLimit;
  uint private transferFee;
  IERC721Enumerable public ChibiNFT;

  constructor() {
    arrayLimit = 50;
  }

  modifier onlyMinter() {
    require(msg.sender == minter, "only minter allowed");
    _;
  }

  function setArrayLimit(uint256 _newLimit) public onlyOwner {
    require(_newLimit != 0, "invalid limit for multi-bridge");
    arrayLimit = _newLimit;
  }

  function setNFTAddress(address _chibiNFT) external onlyOwner {
    require(_chibiNFT != address(0), "invalid nft contract");
    ChibiNFT = IERC721Enumerable(_chibiNFT);
  }

  function setTransferFee() external payable onlyOwner {
    transferFee = msg.value;
  }

  function getTransferFee() public view returns(uint) {
    return transferFee;
  }

  function setMinter(address _minter) external onlyOwner {
    require(_minter != address(0), "invalid minter");
    minter = _minter;
  }

  function paybackMultiToken(address _receiver, uint256[] calldata _ids) public payable nonReentrant onlyMinter {
    require(_receiver != address(0), "invalid receiver");
    require(_ids.length <= arrayLimit, "Exceed maximum limit for single transaction");
    uint8 i = 0;
    for (i; i < _ids.length; i++) {
      ChibiNFT.safeTransferFrom(address(this), _receiver, _ids[i]);
    }
    emit ReverseMultiBridged(_receiver, _ids);
  }

  function paybackSingleToken(address _receiver, uint256 _id) public payable nonReentrant onlyMinter {
    require(_receiver != address(0), "invalid receiver");
    ChibiNFT.safeTransferFrom(address(this), _receiver, _id);
    emit ReverseBridged(_receiver, _id);
  }

  function bridgeSingleToken(uint256 _id) public payable nonReentrant {
    require(msg.value == transferFee, 'fee is not correct');
    ChibiNFT.safeTransferFrom(_msgSender(), address(this), _id);
    emit Bridged(_msgSender(), _id);
  }

  function bridgeMultiToken(uint256[] calldata _ids) public payable nonReentrant {
    require(msg.value == transferFee, 'fee is not correct');
    require(_ids.length <= arrayLimit, "Exceed maximum limit for single transaction");
    uint8 i = 0;
    for (i; i < _ids.length; i++) {
      ChibiNFT.safeTransferFrom(_msgSender(), address(this), _ids[i]);
    }
    emit MultiBridged(_msgSender(), _ids);
  }

  function withdrawAll() public payable onlyOwner {
    (bool sent,) = _msgSender().call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function onERC721Received(
      address,
      address,
      uint256,
      bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}
