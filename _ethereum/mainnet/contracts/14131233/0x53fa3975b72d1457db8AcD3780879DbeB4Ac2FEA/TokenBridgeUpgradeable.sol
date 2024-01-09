// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ECDSAUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./CollectibleTokenUpgradeable.sol";
import "./ITokenFactoryERC721.sol";
import "./ITokenFactoryERC1155.sol";

contract TokenBridgeUpgradeable is
  AccessControlEnumerableUpgradeable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  using ECDSAUpgradeable for bytes32;

  bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

  bytes4 public constant INTERFACE_ID_IERC721 = type(IERC721Upgradeable).interfaceId;
  bytes4 public constant INTERFACE_ID_IERC1155 = type(IERC1155Upgradeable).interfaceId;

  event Imported(bytes4 indexed  interfaceId, address indexed tokenAddress, address indexed from, uint256 tokenId, uint256 amount);
  event Exported(bytes4 indexed  interfaceId, address indexed tokenAddress, address indexed to, uint256 tokenId, uint256 amount);

  mapping(string => bool) internal usedNonces;

  /***
   * Public functions
   */
   function initialize() initializer public {
       __AccessControlEnumerable_init();
       __Ownable_init();
       __ERC721Holder_init();
       __ERC1155Holder_init();

       _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
       _setupRole(MODERATOR_ROLE, msg.sender);
   }

  function onERC721Received(address, address from, uint256 tokenId, bytes memory) public virtual override(ERC721HolderUpgradeable) returns (bytes4) {
    address tokenAddress = msg.sender;
    emit Imported(INTERFACE_ID_IERC721, tokenAddress, from, tokenId, 1);
    return this.onERC721Received.selector;
  }

  function onERC1155Received(address, address from, uint256 tokenId, uint256 amount, bytes calldata) public virtual override(ERC1155HolderUpgradeable) returns (bytes4) {
    address tokenAddress = msg.sender;
    emit Imported(INTERFACE_ID_IERC1155, tokenAddress, from, tokenId, amount);
    return this.onERC1155Received.selector;
  }

  function invalidateNonce(string memory nonce) public virtual {
    require(hasRole(MODERATOR_ROLE, msg.sender), "TokenBridgeUpgradeable: must be moderator");

    if (!usedNonces[nonce])  usedNonces[nonce] = true;
  }

  function exportToken(bytes4 interfaceId, address tokenAddress, uint256 tokenId, uint256 amount, string memory nonce, uint256 expiration, bytes memory signature) public virtual {
    require(verifySignature(interfaceId, tokenAddress, tokenId, amount, nonce, expiration, "exportToken", signature), "TokenBridgeUpgradeable: invalid signature");
    
    address to = msg.sender;
    _exportToken(interfaceId, tokenAddress, to, tokenId, amount);
  }

  function mintCollectibleToken(bytes4 interfaceId, address tokenAddress, uint256 tokenId, string memory nonce, uint256 expiration, bytes memory signature) public virtual {
    uint256 amount = 1;
    require(verifySignature(interfaceId, tokenAddress, tokenId, amount, nonce, expiration, "mintCollectibleToken", signature), "TokenBridgeUpgradeable: invalid signature");

    address to = msg.sender;
    CollectibleTokenUpgradeable(tokenAddress).mint(to, tokenId, "");
  }

  function mintTokenFactory(bytes4 interfaceId, address tokenAddress, uint256 optionId, uint256 amount, string memory nonce, uint256 expiration, bytes memory signature) public virtual {
    require(verifySignature(interfaceId, tokenAddress, optionId, amount, nonce, expiration, "mintTokenFactory", signature), "TokenBridgeUpgradeable: invalid signature");

    address to = msg.sender;
    if (interfaceId == INTERFACE_ID_IERC721) {
      ITokenFactoryERC721(tokenAddress).mint(optionId, to);
    }
    else if (interfaceId == INTERFACE_ID_IERC1155) {
      ITokenFactoryERC1155(tokenAddress).mint(optionId, to, amount);
    }
    else {
      revert("TokenBridgeUpgradeable: token contract interface not supported");
    }
  }

  function verifySignature(bytes4 interfaceId, address tokenAddress, uint256 tokenId, uint256 amount, string memory nonce, uint256 expiration, string memory method, bytes memory signature) public virtual returns (bool) {
    require(!usedNonces[nonce], "TokenBridgeUpgradeable: nonce already used");
    usedNonces[nonce] = true;

    require(expiration > block.timestamp, "TokenBridgeUpgradeable: signature had expired");

    address to = msg.sender;

    bytes32 hash = hashToSign(interfaceId, tokenAddress, to, tokenId, amount, nonce, expiration, method);
    hash = ethSignedHash(hash);
    
    address signer = recoverSigner(hash, signature);
    require(signer != address(0) && hasRole(MODERATOR_ROLE, signer), "TokenBridgeUpgradeable: invalid signature");

    return true;
  }
  
  function hashToSign(bytes4 interfaceId, address tokenAddress, address to, uint256 tokenId, uint256 amount, string memory nonce, uint256 expiration, string memory method) public view virtual returns (bytes32) {
    uint256 chainId = block.chainid;
    address bridge = address(this);
    return keccak256(abi.encodePacked(interfaceId, tokenAddress, to, tokenId, amount, nonce, expiration, method, chainId, bridge));
  }

  function ethSignedHash(bytes32 hash) public view virtual returns (bytes32) {
    return hash.toEthSignedMessageHash();
  }

  function recoverSigner(bytes32 hash, bytes memory signature) public view virtual returns (address) {
    return hash.recover(signature);
  }

  function erc721TokenExists(address tokenAddress, uint256 tokenId) public view virtual returns (bool) {
    try IERC721Upgradeable(tokenAddress).ownerOf(tokenId) returns (address owner) {
      return owner != address(0);
    }
    catch Error(string memory reason) {
      if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("ERC721: owner query for nonexistent token"))) {
        return false;
      }
      else {
        revert(reason);
      }
    }
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC1155ReceiverUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /***
   * Internal functions
   */
  function _exportToken(bytes4 interfaceId, address tokenAddress, address to, uint256 tokenId, uint256 amount) internal virtual {
    address from = address(this);
    
    if (interfaceId == INTERFACE_ID_IERC721) {
      IERC721Upgradeable(tokenAddress).safeTransferFrom(from, to, tokenId);
    }
    else if (interfaceId == INTERFACE_ID_IERC1155) {
      IERC1155Upgradeable(tokenAddress).safeTransferFrom(from, to, tokenId, amount, "");
    }
    else {
      revert("TokenBridgeUpgradeable: token contract interface not supported");
    }

    emit Exported(interfaceId, tokenAddress, to, tokenId, amount);
  }

}
