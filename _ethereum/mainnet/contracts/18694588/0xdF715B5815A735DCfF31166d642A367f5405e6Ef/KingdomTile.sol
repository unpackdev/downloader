// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./LinkTokenInterface.sol";
import "./IRouterClient.sol";
import "./Client.sol";
import "./IERC721A.sol";
import "./IERC2981.sol";
import "./ECDSA.sol";
import "./String.sol";
import "./Roles.sol";
import "./ERC721.sol";
import "./CCIPReceiver.sol";

contract KingdomTiles is Roles, ERC721, CCIPReceiver, IERC2981 {
  using Bits for bytes32;

  error BridgeToUnknownCollection();
  error NotEnoughLink();
  error UnauthorizedMint();
  error TokenIsNotLocked();
  error WithdrawFailed();

  event MessageSent(bytes32 messageId);
  event MetadataUpdate(uint256 _tokenId);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
  event RoyaltiesUpdated(uint64 indexed feeBps, address indexed recipient);

  mapping(bytes32 => bool) private _sisterCollections;
  bytes32 private _royaltyConfig;

  constructor(address _router, address _link, string memory uri) CCIPReceiver(_router, _link) {
    _baseURI = uri;
    _setRole(msg.sender, 0, true);
    LinkTokenInterface(linkToken).approve(router, type(uint256).max);
    _royaltyConfig = _pack(500, address(this));
  }

  function unlockToken(uint256 tokenId, address to) external onlyRole(0) {
    if (_owner[tokenId] != address(this)) {
      revert TokenIsNotLocked();
    }
    IERC721A(address(this)).transferFrom(address(this), to, tokenId);
  }

  function setCCIPRouter(address newRouter) external onlyRole(0) {
    _setRouter(newRouter);
  }

  function setRoyaltiesConfig(uint64 feeBps, address recipient) external onlyRole(0) {
    _royaltyConfig = _pack(feeBps, recipient);
    emit RoyaltiesUpdated(feeBps, recipient);
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165.
      interfaceId == 0x80ac58cd || // ERC721.
      interfaceId == 0x5b5e139f || // ERC721Metadata
      interfaceId == 0x2a55205a || // ERC2981
      interfaceId == 0x85572ffb; // CCIPReceiver
  }

  function setBaseURI(string calldata uri) external onlyRole(0) {
    _setBaseURI(uri);
    emit BatchMetadataUpdate(0, type(uint256).max);
  }

  function setSister(uint64 chainSelector, address collection, bool status) external onlyRole(0) {
    bytes32 id = _pack(chainSelector, collection);
    _sisterCollections[id] = status;
  }

  function mint(address to, uint256 tokenId, bytes calldata signature) external payable {
    _verifySignature(tokenId, to, msg.value, signature);
    _safeMint(to, tokenId);
  }

  function bridge(uint256 tokenId, address toAddress, uint64 toChain, address toSister) external {
    if (!_isSister(toChain, toSister)) {
      revert BridgeToUnknownCollection();
    }
    transferFrom(msg.sender, address(this), tokenId);
    bytes32 data = _pack(uint64(tokenId), toAddress);
    Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
      receiver: abi.encode(toSister),
      data: abi.encodePacked(data),
      tokenAmounts: new Client.EVMTokenAmount[](0),
      extraArgs: "",
      feeToken: linkToken
    });

    uint256 fee = IRouterClient(router).getFee(
      toChain,
      message
    );

    if (LinkTokenInterface(linkToken).balanceOf(address(this)) < fee) {
      revert NotEnoughLink();
    }

    bytes32 messageId;

    messageId = IRouterClient(router).ccipSend(
      toChain,
      message
    );

    emit MetadataUpdate(tokenId);
    emit MessageSent(messageId);
  }

  function _ccipReceive(
    Client.Any2EVMMessage memory message
  ) internal override {
    address sender = abi.decode(message.sender, (address));
    require(_isSister(message.sourceChainSelector, sender), "Untrusted bridge");
    (uint64 tokenId64, address bridger) = _unpack(message.data);
    uint256 tokenId = uint256(tokenId64);
    address tokenOwner = _owner[tokenId];
    if (tokenOwner == address(0)) {
      _safeMint(bridger, tokenId);
      return;
    }
    if (tokenOwner == address(this)) {
      IERC721A(address(this)).transferFrom(address(this), bridger, tokenId);
      emit MetadataUpdate(tokenId);
    }
  }

  function _isSister(uint64 chainSelector, address collection) internal view returns(bool) {
    bytes32 id = _pack(chainSelector, collection);
    return _sisterCollections[id];
  }

  function _pack(uint64 num, address addr) internal pure returns(bytes32 id) {
    assembly {
      id := or(addr, shl(160, num))
    }
  }

  function _unpack(bytes memory data) internal pure returns(uint64 num, address addr) {
    assembly {
      let b32 := mload(add(data, 32))
      addr := and(b32, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      num := shr(160, b32)
    }
  }

  function _unpack32(bytes32 data) internal pure returns(uint64 num, address addr) {
    assembly {
      addr := and(data, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      num := shr(160, data)
    }
  }

  function _verifySignature(uint256 tokenId, address minter, uint256 value, bytes calldata signature) internal view {
    bytes32 signedMessage = ECDSA.toEthSignedMessageHash(
      keccak256(
        abi.encodePacked(
          tokenId,
          minter,
          block.chainid,
          value
        )
      )
    );
    address signer = ECDSA.recover(signedMessage, signature);
    if (!_hasRole(signer, 1)) {
      revert UnauthorizedMint();
    }
  }

  function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
    (uint64 feeBps, address receiver) = _unpack32(_royaltyConfig);
    return (receiver, uint256(salePrice * feeBps) / 10000);
  }

  function withdrawToken(address token, address to) external onlyRole(0) {
    uint256 amount = LinkTokenInterface(token).balanceOf(address(this));
    LinkTokenInterface(linkToken).transfer(to, amount);
  }

  function withdraw() external onlyRole(0) {
    uint256 amount = address(this).balance;
    (bool success, ) = msg.sender.call{ value: amount }("");
    if (!success) {
      revert WithdrawFailed();
    }
  }
}
