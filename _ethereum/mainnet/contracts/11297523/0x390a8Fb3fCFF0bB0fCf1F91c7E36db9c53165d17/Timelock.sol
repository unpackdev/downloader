// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Timelock.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Modifications were made to support an IDChain/xDAI address as admin using the Arbitrary Message Bridge (AMB)
// Also did linting so it looks nicer

pragma solidity 0.6.6;

import "./SafeMath.sol";
import "./IAMB.sol";

contract Timelock {
  using SafeMath for uint256;

  modifier onlyAdmin(address admin_) {
    address actualSender = amb.messageSender();
    uint256 sourceL2ChainID = amb.messageSourceChainId();
    require(
      actualSender == admin_,
      "Timelock::onlyAdmin: L2 call must come from admin."
    );
    require(
      sourceL2ChainID == l2ChainID,
      "Timelock::onlyAdmin: L2 call must come from correct chain."
    );
    require(
      msg.sender == address(amb),
      "Timelock::onlyAdmin: L1 call must come from AMB."
    );
    _;
  }

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event NewAMB(address indexed newAMB);
  event NewL2ChainID(uint256 indexed newL2ChainID);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  uint256 public constant GRACE_PERIOD = 14 days;
  uint256 public constant MINIMUM_DELAY = 2 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;
  bool public admin_initialized;
  IAMB public amb;
  uint256 public l2ChainID;

  mapping(bytes32 => bool) public queuedTransactions;

  constructor(
    address admin_,
    uint256 delay_,
    address amb_,
    uint256 l2ChainID_
  ) public {
    require(
      delay_ >= MINIMUM_DELAY,
      "Timelock::constructor: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "Timelock::constructor: Delay must not exceed maximum delay."
    );

    admin = admin_;
    delay = delay_;
    admin_initialized = false;
    amb = IAMB(amb_);
    l2ChainID = l2ChainID_;
  }

  receive() external payable {}

  function setDelay(uint256 delay_) public {
    require(
      msg.sender == address(this),
      "Timelock::setDelay: Call must come from Timelock."
    );
    require(
      delay_ >= MINIMUM_DELAY,
      "Timelock::setDelay: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "Timelock::setDelay: Delay must not exceed maximum delay."
    );
    delay = delay_;

    emit NewDelay(delay_);
  }

  function setAMB(address amb_) public {
    require(
      msg.sender == address(this),
      "Timelock::setAMB: Call must come from Timelock."
    );
    require(amb_ != address(0), "Timelock::setAMB: AMB must be non zero.");
    amb = IAMB(amb_);

    emit NewAMB(amb_);
  }

  function setL2ChainID(uint256 l2ChainID_) public {
    require(
      msg.sender == address(this),
      "Timelock::setL2ChainID: Call must come from Timelock."
    );
    l2ChainID = l2ChainID_;

    emit NewL2ChainID(l2ChainID_);
  }

  function acceptAdmin() public onlyAdmin(pendingAdmin) {
    admin = pendingAdmin;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    // allows one time setting of admin for deployment purposes
    if (admin_initialized) {
      require(
        msg.sender == address(this),
        "Timelock::setPendingAdmin: Call must come from Timelock."
      );
    } else {
      require(
        msg.sender == admin,
        "Timelock::setPendingAdmin: First call must come from admin."
      );
      admin_initialized = true;
    }
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin_);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external onlyAdmin(admin) returns (bytes32) {
    require(
      eta >= getBlockTimestamp().add(delay),
      "Timelock::queueTransaction: Estimated execution block must satisfy delay."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external onlyAdmin(admin) {
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable onlyAdmin(admin) returns (bytes memory) {
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash],
      "Timelock::executeTransaction: Transaction hasn't been queued."
    );
    require(
      getBlockTimestamp() >= eta,
      "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
    );
    require(
      getBlockTimestamp() <= eta.add(GRACE_PERIOD),
      "Timelock::executeTransaction: Transaction is stale."
    );

    queuedTransactions[txHash] = false;

    bool success;
    bytes memory returnData;
    if (bytes(signature).length == 0) {
      // solium-disable-next-line security/no-call-value
      (success, returnData) = target.call{ value: value }(data);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, returnData) = target.call{ value: value }(
        abi.encodePacked(bytes4(keccak256(bytes(signature))), data)
      );
    }

    require(
      success,
      "Timelock::executeTransaction: Transaction execution reverted."
    );

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}
