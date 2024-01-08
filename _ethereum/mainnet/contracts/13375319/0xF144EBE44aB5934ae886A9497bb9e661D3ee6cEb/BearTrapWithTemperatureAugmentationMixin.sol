// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IKey is IERC721 {
  function getBlockNumber(
    uint256 tokenId
  )
    external
    view
    returns (uint256);
}

/**
 * @title BearTrapWithTemperatureAugmentationMixin
 * @author the-torn
 */
contract BearTrapWithTemperatureAugmentationMixin {

  address public constant LAVA = 0x000000000000000000000000000000000000dEaD;

  IERC721 public immutable BEAR_CONTRACT;
  IKey public immutable KEY_CONTRACT;
  uint256 public immutable TIME_AT_WHICH_WE_DROP_THE_BEAR_IN_THE_LAVA;

  uint256 public _bearId = 0;
  bool public _bearSaved = false;
  mapping(uint256 => address) public _lockedKeyOwner;

  constructor(
    IERC721 bearContract,
    IKey keyContract,
    uint256 ttd
  ) {
    BEAR_CONTRACT = bearContract;
    KEY_CONTRACT = keyContract;
    TIME_AT_WHICH_WE_DROP_THE_BEAR_IN_THE_LAVA = block.timestamp + ttd;
  }

  function tieUpTheBear(
    uint256 bearId
  )
    external
  {
    require(
      _bearId == 0,
      "Already trapped the bear"
    );
    require(
      BEAR_CONTRACT.ownerOf(bearId) == address(this),
      "Bear not received"
    );
    _bearId = bearId;
  }

  function saveBearWithKey(
    uint256 keyId
  )
    external
  {
    require(
      _bearId != 0,
      "There is no bear"
    );
    require(
      !_bearSaved,
      "Bear already saved"
    );
    uint256 keyNumber = KEY_CONTRACT.getBlockNumber(keyId);
    require(
      isValidKey(keyNumber),
      "Invalid key"
    );
    require(
      KEY_CONTRACT.ownerOf(keyId) == msg.sender,
      "Sender does not have the key"
    );
    _bearSaved = true;
    BEAR_CONTRACT.safeTransferFrom(address(this), msg.sender, _bearId);
  }

  function dropTheBear()
    external
  {
    require(
      block.timestamp >= TIME_AT_WHICH_WE_DROP_THE_BEAR_IN_THE_LAVA,
      "TTD has not elapsed"
    );
    BEAR_CONTRACT.safeTransferFrom(address(this), LAVA, _bearId);
  }

  function lockKey(
    uint256 keyId
  )
    external
  {
    uint256 keyNumber = KEY_CONTRACT.getBlockNumber(keyId);
    require(
      isValidKey(keyNumber),
      "Invalid key"
    );
    KEY_CONTRACT.safeTransferFrom(msg.sender, address(this), keyId);
    _lockedKeyOwner[keyId] = msg.sender;
  }

  function retrievePreviouslyLockedKeyOnlyIfTheBearIsGone(
    uint256 keyId
  )
    external
  {
    require(
      BEAR_CONTRACT.ownerOf(_bearId) != address(this),
      "Still got the bear"
    );
    require(
      _lockedKeyOwner[keyId] == msg.sender,
      "Not the sender's key"
    );
    delete _lockedKeyOwner[keyId];
    KEY_CONTRACT.safeTransferFrom(address(this), msg.sender, keyId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  )
    external
    pure
    returns(bytes4)
  {
    return 0x150b7a02;
  }

  function isValidKey(
    uint256 x
  )
    private
    view
    returns (bool)
  {
    uint256 z;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let p := mload(0x40)
      mstore(p, 0x20)
      mstore(add(p, 0x20), 0x20)
      mstore(add(p, 0x40), 0x20)
      mstore(add(p, 0x60), 0x02)
      mstore(add(p, 0x80), sub(x, 1))
      mstore(add(p, 0xa0), x)
      if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
        revert(0, 0)
      }
      z := mload(p)
    }
    return z == 1;
  }
}
