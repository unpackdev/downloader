// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./IERC1155Receiver.sol";
import "./BoosterToken.sol";

contract BoosterEscrow is IERC1155Receiver {
  struct Boost {
    uint256 winIncrease;
    uint256 gasDecrease;
    uint256 price;
  }

  bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
  bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint...

  BoosterToken public boosterToken;
  mapping(address => uint256) public activeBoosters;

  event BoosterActivated(address indexed player, uint256 id);
  event BoosterDeactivated(address indexed player, uint256 id);

  constructor(address payable _boosterToken) public {
    require(_boosterToken != address(0x0), "Booster token should not be empty");
    boosterToken = BoosterToken(_boosterToken);
  }

  function activateBooster(uint256 _id) external {
    if (activeBoosters[msg.sender] != 0) {
      boosterToken.safeTransferFrom(address(this), msg.sender, activeBoosters[msg.sender], 1, "0x0");
    }
    boosterToken.safeTransferFrom(msg.sender, address(this), _id, 1, "0x0");
    activeBoosters[msg.sender] = _id;

    emit BoosterActivated(msg.sender, _id);
  }

  function deactivateBooster() external {
    require(activeBoosters[msg.sender] != 0, "Booster not activated");
    uint256 id = activeBoosters[msg.sender];
    activeBoosters[msg.sender] = 0;
    boosterToken.safeTransferFrom(address(this), msg.sender, id, 1, "0x0");

    emit BoosterActivated(msg.sender, id);
  }

  function activeBoosterId(address _account) external view returns (uint256) {
    return activeBoosters[_account];
  }

  function activeBooster(address _account) public view returns (uint256, uint256, uint256) {
    return boosterToken.getBooster(activeBoosters[_account]);
  }

  function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns(bytes4) {
    return ERC1155_ACCEPTED;
  }

  function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4) {
    return ERC1155_BATCH_ACCEPTED;
  }

  function supportsInterface(bytes4 interfaceID) public override view returns (bool) {
    return interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0; // ERC165 // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
  }
}