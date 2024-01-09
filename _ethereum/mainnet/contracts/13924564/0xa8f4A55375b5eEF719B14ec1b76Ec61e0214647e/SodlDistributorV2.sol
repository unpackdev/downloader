pragma solidity ^0.8.4;

//SPDX-License-Identifier: Unlicense

import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./Ownable.sol";
import "./SODLDAO.sol";
import "./SodlDistributor.sol";

contract SodlDistributorV2 is Ownable {
  address public immutable token;
  address public immutable v1Address;
  mapping(bytes32 => uint256) public claimedMap;

  event Claimed(address account, uint256 amount, bytes32 txHash);

  constructor(address token_, address v1Address_) {
    token = token_;
    v1Address = v1Address_;
  }

  using ECDSA for bytes32;

  function toHex16(bytes16 data) internal pure returns (bytes32 result) {
    result =
      (bytes32(data) &
        0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
      ((bytes32(data) &
        0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
        64);
    result =
      (result &
        0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
      ((result &
        0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
        32);
    result =
      (result &
        0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
      ((result &
        0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
        16);
    result =
      (result &
        0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
      ((result &
        0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
        8);
    result =
      ((result &
        0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
        4) |
      ((result &
        0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
        8);
    result = bytes32(
      0x3030303030303030303030303030303030303030303030303030303030303030 +
        uint256(result) +
        (((uint256(result) +
          0x0606060606060606060606060606060606060606060606060606060606060606) >>
          4) &
          0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
        7
    );
  }

  function bytes32ToString(bytes32 data) public pure returns (string memory) {
    return
      _toLower(
        string(
          abi.encodePacked(
            "0x",
            toHex16(bytes16(data)),
            toHex16(bytes16(data << 128))
          )
        )
      );
  }

  function _lower(bytes1 _b1) private pure returns (bytes1) {
    if (_b1 >= 0x41 && _b1 <= 0x5A) {
      return bytes1(uint8(_b1) + 32);
    }

    return _b1;
  }

  function _toLower(string memory _base) internal pure returns (string memory) {
    bytes memory _baseBytes = bytes(_base);
    for (uint256 i = 0; i < _baseBytes.length; i++) {
      _baseBytes[i] = _lower(_baseBytes[i]);
    }
    return string(_baseBytes);
  }

  function claimMulti(
    bytes32[] memory txHashes,
    uint256[] memory amounts,
    uint256 blockNumber,
    bytes memory signature
  ) public {
    require(txHashes.length == amounts.length, "Invalid txHashes and amounts");
    require(block.number < blockNumber, "Invalid blockNumber");

    bytes32 message = keccak256(
      abi.encodePacked(txHashes, amounts, blockNumber, msg.sender)
    );

    address signer = message.toEthSignedMessageHash().recover(signature);
    require(signer == owner(), "Invalid signature");

    for (uint256 index = 0; index < amounts.length; index++) {
      if (isClaimed(txHashes[index]) == false) {
        claimedMap[txHashes[index]] = amounts[index];
        SODLDAO(token).mint(msg.sender, amounts[index]);

        emit Claimed(msg.sender, amounts[index], txHashes[index]);
      }
    }
  }

  function isClaimed(bytes32 txHash) public view returns (bool) {
    if (claimedMap[txHash] > 0) {
      return true;
    } else {
      return SodlDistributor(v1Address).isClaimed(bytes32ToString(txHash));
    }
  }

  function claimedAmount(bytes32 txHash) public view returns (uint256) {
    if (claimedMap[txHash] > 0) {
      return claimedMap[txHash];
    } else {
      return SodlDistributor(v1Address).claimedAmount(bytes32ToString(txHash));
    }
  }
}
