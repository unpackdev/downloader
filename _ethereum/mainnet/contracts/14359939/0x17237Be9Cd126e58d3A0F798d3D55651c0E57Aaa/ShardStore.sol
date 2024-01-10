// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

/**
 * @dev Interface for checking active staked balance of a user.
 */
interface ILoomi {
  function spendLoomi(address user, uint256 amount) external;
}

interface IMysteryBox {
  function addShards(uint256 shardId, uint256 shardsNumber, address user) external;
}

contract ShardStore is ReentrancyGuard, Ownable {
    ILoomi public loomi;
    IMysteryBox public MysteryBox;

    uint256 public shardPrice;

    bool public isPaused;

    address public signer;

    mapping(address => uint256) private _nonces;
    
    event ClaimShards(address indexed userAddress, uint256[] shards);

    constructor(address _loomi, address _mb, address _signer) {
      loomi = ILoomi(_loomi);
      MysteryBox = IMysteryBox(_mb);
      signer = _signer;

      isPaused = true;
    }

    modifier whenNotPaused {
      require(!isPaused, "Contract paused!");
      _;
    }

    /**
    * @dev Function to purchase missing shards for user.
    */
    function purchaseShard(
      uint256[] calldata shards,
      uint256 nonce,
      bytes calldata signature
    ) public nonReentrant whenNotPaused {
      require(shards.length == 3, "Invalid shards array provided");
      require(_nonces[_msgSender()] < nonce, "Invalid nonce provided");
      require(_validateData(shards, nonce, signature), "Invalid Data Provided");

      _nonces[_msgSender()] = nonce;
      
      uint256 finalPrice;

      for (uint256 i; i < shards.length; i++) {
        if (shards[i] > 0) {
          MysteryBox.addShards(i, 1, _msgSender());
          finalPrice += shardPrice;
        }
      }

      loomi.spendLoomi(_msgSender(), finalPrice);

      emit ClaimShards(_msgSender(), shards);
    }

    /**
    * @dev Function incoming name validation
    */
    function _validateData(
      uint256[] memory _shards,
      uint256 _nonce,
      bytes calldata signature
      ) internal view returns (bool) {
      bytes32 dataHash = keccak256(abi.encodePacked(_shards, _nonce, _msgSender()));
      bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

      address receivedAddress = ECDSA.recover(message, signature);
      return (receivedAddress != address(0) && receivedAddress == signer);
    }

    /**
    * @dev Function allows admin to update shard Price.
    */
    function updateShardPrice(uint256 _price) public onlyOwner {
      shardPrice = _price;
    }

    /**
    * @dev Function allows admin to pause contract.
    */
    function pause(bool _pause) public onlyOwner {
      isPaused = _pause;
    }
}
