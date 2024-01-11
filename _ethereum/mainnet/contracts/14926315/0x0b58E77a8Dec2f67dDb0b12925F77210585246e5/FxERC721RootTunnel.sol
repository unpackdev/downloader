// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./FxCommonTypes.sol";
import "./FxBaseRootTunnel.sol";

contract FxERC721RootTunnel is FxBaseRootTunnel, FxCommonTypes, IERC721Receiver {
  ////////////////////////////////////////////////////////////////////////////////
  // EVENTS
  ////////////////////////////////////////////////////////////////////////////////
  event Withdraw(address indexed rootToken, address indexed user, uint256[] tokenIds);
  event Deposit(address indexed rootToken, address indexed user, uint256[] tokenIds);

  ////////////////////////////////////////////////////////////////////////////////
  // GENERAL
  ////////////////////////////////////////////////////////////////////////////////
  mapping(address => address) public rootToChildTokens;

  constructor(
    address checkpointManager_,
    address fxRoot_,
    address childTunnel_
  ) FxBaseRootTunnel(checkpointManager_, fxRoot_) {
    fxChildTunnel = childTunnel_;
  }

  function mapToken(address rootToken_, address childToken_) external onlyOwner {
    rootToChildTokens[rootToken_] = childToken_;
  }

  function setFxChildTunnel(address childTunnel_) public override onlyOwner {
    fxChildTunnel = childTunnel_;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // TO CHILD
  ////////////////////////////////////////////////////////////////////////////////
  function deposit(address rootToken_, uint256[] calldata tokenIds_)
    public
    isMapped(rootToken_)
  {
    require(tokenIds_.length <= BATCH_LIMIT, "RootTunnel: batch limit");

    address childToken = rootToChildTokens[rootToken_];
    IERC721 rootToken = IERC721(rootToken_);

    for (uint256 i = 0; i < tokenIds_.length; ++i) {
      uint256 tokenId = tokenIds_[i];
      rootToken.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    bytes memory message = abi.encode(childToken, msg.sender, tokenIds_);
    message = abi.encode(DEPOSIT, message);
    _sendMessageToChild(message);

    emit Deposit(rootToken_, msg.sender, tokenIds_);
  }

  ////////////////////////////////////////////////////////////////////////////////
  // FROM CHILD
  ////////////////////////////////////////////////////////////////////////////////
  function _withdraw(bytes memory data_) internal {
    (address _rootToken, address user, uint256[] memory tokenIds) = abi.decode(
      data_,
      (address, address, uint256[])
    );

    IERC721 rootToken = IERC721(_rootToken);
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      rootToken.safeTransferFrom(address(this), user, tokenId);
    }

    emit Withdraw(_rootToken, user, tokenIds);
  }

  function _processMessageFromChild(bytes memory data_) internal override {
    (bytes32 syncType, bytes memory syncData) = abi.decode(data_, (bytes32, bytes));

    if (syncType == WITHDRAW) {
      _withdraw(syncData);
    } else {
      revert("RootTunnel: invalid sync");
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  // MISC
  ////////////////////////////////////////////////////////////////////////////////
  modifier isMapped(address rootToken_) {
    require(
      rootToChildTokens[rootToken_] != address(0x0),
      "RootTunel: token not mapped"
    );
    _;
  }

  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256, /* tokenId */
    bytes calldata /* data */
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
