// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";


contract CommitteeProxy is Ownable {
  event CommitteeChanged(address indexed previousCommittee, address indexed newCommittee);
  event ExecuteTransaction(
    address indexed target,
    uint256 value,
    string signature,
    bytes data
  );

  address public committee;

  constructor(address committee_) public Ownable() {
    committee = committee_;
    emit CommitteeChanged(address(0), committee_);
  }

  function setCommittee(address committee_) external onlyOwner {
    emit CommitteeChanged(committee, committee_);
    committee = committee_;
  }

  modifier onlyCommittee {
    require(msg.sender == committee, "CommitteeProxy: caller is not the committee");
    _;
  }

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data
  )
    external
    payable
    onlyCommittee
    returns (bytes memory)
  {
    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }
    (bool success, bytes memory returnData) = target.call{value: value}(callData);

    require(
      success,
      "CommitteeProxy::executeTransaction: Transaction execution reverted"
    );
    emit ExecuteTransaction(target, value, signature, data);
    return returnData;
  }
}