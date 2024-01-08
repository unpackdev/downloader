// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./NutBerryCore.sol";

/// @notice Includes Deposit & Withdraw functionality
// Audit-1: ok
contract NutBerryTokenBridge is NutBerryCore {
  event Deposit(address owner, address token, uint256 value, uint256 tokenType);
  event Withdraw(address owner, address token, uint256 value);

  /// @dev Checks if the contract at `token` implements `ownerOf(uint)`.
  /// This function saves the result on first run and returns the token type from storage
  /// on subsequent invocations.
  /// Intended to be used in a L1 context.
  /// @return tokenType Either `1` for ERC-20 or `2` for ERC-721 like contracts (NFTs).
  function _probeTokenType (address token, uint256 tokenId) internal returns (uint256 tokenType) {
    uint256 key = _L1_TOKEN_TYPE_KEY(token);
    assembly {
      tokenType := sload(key)

      if iszero(tokenType) {
        // defaults to ERC-20
        tokenType := 1

        // call ownerOf(tokenId)
        mstore(0, 0x6352211e)
        mstore(32, tokenId)
        // Note: if there is less than 60k gas available,
        // this will either succeed or fail.
        // If it fails because there wasn't enough gas left,
        // then the current call context will highly likely fail too.
        let success := staticcall(60000, token, 28, 36, 0, 0)
        // ownerOf() should return a 32 bytes value
        if and(success, eq(returndatasize(), 32)) {
          tokenType := 2
        }
        // save the result
        sstore(key, tokenType)
      }
    }
  }

  /// @dev Loads token type from storage for `token`.
  /// Intended to be used in a L2 context.
  function _getTokenType (address token) internal virtual returns (uint256) {
    uint256 key = _TOKEN_TYPE_KEY(token);
    return _sload(key);
  }

  /// @dev Saves the token type for `token`.
  /// Intended to be used in a L2 context.
  function _setTokenType (address token, uint256 tokenType) internal virtual {
    uint256 key = _TOKEN_TYPE_KEY(token);
    _sstore(key, tokenType);
  }

  /// @dev Deposit `token` and value (`amountOrId`) into bridge.
  /// @param token The ERC-20/ERC-721 token address.
  /// @param amountOrId Amount or the token id.
  /// @param receiver The account who receives the token(s).
  function deposit (address token, uint256 amountOrId, address receiver) external {
    uint256 pending = pendingHeight() + 1;
    _setPendingHeight(pending);

    uint256 tokenType = _probeTokenType(token, amountOrId);
    bytes32 blockHash;
    assembly {
      // deposit block - header

      // 32 bytes nonce
      mstore(128, pending)
      // 32 bytes block type
      mstore(160, 1)
      // 32 bytes timestamp
      mstore(192, timestamp())

      // 20 byte receiver
      mstore(224, shl(96, receiver))
      // 20 byte token
      mstore(244, shl(96, token))
      // 32 byte amount or token id
      mstore(264, amountOrId)
      // 32 byte token type
      mstore(296, tokenType)
      blockHash := keccak256(128, 200)
    }

    _setBlockHash(pending, blockHash);
    emit Deposit(receiver, token, amountOrId, tokenType);

    assembly {
      // transferFrom
      mstore(0, 0x23b872dd)
      mstore(32, caller())
      mstore(64, address())
      mstore(96, amountOrId)
      let success := call(gas(), token, 0, 28, 100, 0, 32)
      if iszero(success) {
        revert(0, 0)
      }
      // some (old) ERC-20 contracts or ERC-721 do not have a return value.
      // those who do return a non-negative value.
      if returndatasize() {
        if iszero(mload(0)) {
          revert(0, 0)
        }
      }
      stop()
    }
  }

  /// @dev Withdraw `token` and `tokenId` from bridge.
  /// `tokenId` is ignored if `token` is not a ERC-721.
  /// @param owner address of the account to withdraw from and to.
  /// @param token address of the token.
  /// @param tokenId ERC-721 token id.
  function withdraw (address owner, address token, uint256 tokenId) external {
    require(owner != address(0));

    uint256 val;
    uint256 tokenType = _probeTokenType(token, tokenId);

    if (tokenType == 1) {
      val = getERC20Exit(token, owner);
      _setERC20Exit(token, owner, 0);
    } else {
      address exitOwner = getERC721Exit(token, tokenId);
      if (owner != exitOwner) {
        revert();
      }
      val = tokenId;
      _setERC721Exit(token, address(0), val);
    }

    emit Withdraw(owner, token, val);

    assembly {
      // use transfer() for ERC-20's instead of transferFrom,
      // some token contracts check for allowance even if caller() == owner of tokens
      if eq(tokenType, 1) {
        // transfer(...)
        mstore(0, 0xa9059cbb)
        mstore(32, owner)
        mstore(64, val)
        let success := call(gas(), token, 0, 28, 68, 0, 32)
        if iszero(success) {
          revert(0, 0)
        }
        // some (old) contracts do not have a return value.
        // those who do return a non-negative value.
        if returndatasize() {
          if iszero(mload(0)) {
            revert(0, 0)
          }
        }
        stop()
      }

      // else use transferFrom
      mstore(0, 0x23b872dd)
      mstore(32, address())
      mstore(64, owner)
      mstore(96, val)
      let success := call(gas(), token, 0, 28, 100, 0, 0)
      if iszero(success) {
        revert(0, 0)
      }
      stop()
    }
  }

  function _hashERC20Exit (address target, address owner) internal pure returns (bytes32 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0x409d98be992cf6feb2d0dd08517cea5626d092a062b587294f77c8867ee9ecae)
      mstore(32, target)
      mstore(64, owner)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _hashERC721Exit (address target, uint256 tokenId) internal pure returns (bytes32 ret) {
    assembly {
      let backup := mload(64)
      mstore(0, 0xed93405f54628300c204dec35dc26ea0937dddc7eef817a80d167cf6034b6abe)
      mstore(32, target)
      mstore(64, tokenId)
      ret := keccak256(0, 96)
      mstore(64, backup)
    }
  }

  function _L1_TOKEN_TYPE_KEY (address token) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x9e605931b4eb546bb835cd7af4f2eb8c79ca4254e07a7c8807e14ea0c9b99084)
      mstore(32, token)
      ret := keccak256(0, 64)
    }
  }

  function _TOKEN_TYPE_KEY (address token) internal pure returns (uint256 ret) {
    assembly {
      mstore(0, 0x7e9dc5694c1711234663ad3120e3efc70aeefda23e219929e3785ccf356431ff)
      mstore(32, token)
      ret := keccak256(0, 64)
    }
  }

  function _incrementExit (address target, address owner, uint256 value) internal {
    NutBerryCore._incrementStorageL1(_hashERC20Exit(target, owner), value);
  }

  function getERC20Exit (address target, address owner) public view returns (uint256) {
    return NutBerryCore._getStorageL1(_hashERC20Exit(target, owner));
  }

  function _setERC20Exit (address target, address owner, uint256 value) internal {
    NutBerryCore._setStorageL1(_hashERC20Exit(target, owner), value);
  }

  function getERC721Exit (address target, uint256 tokenId) public view returns (address) {
    return address(NutBerryCore._getStorageL1(_hashERC721Exit(target, tokenId)));
  }

  function _setERC721Exit (address target, address owner, uint256 tokenId) internal {
    NutBerryCore._setStorageL1(_hashERC721Exit(target, tokenId), uint256(owner));
  }

  /// @dev SLOAD in a L2 context. Must be implemented by consumers of this contract.
  function _sload (uint256 key) internal virtual returns (uint256 ret) {
  }

  /// @dev SSTORE in a L2 context. Must be implemented by consumers of this contract.
  function _sstore (uint256 key, uint256 value) internal virtual {
  }
}
