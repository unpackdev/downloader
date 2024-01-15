// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./ECDSA.sol";

import "./Edwone.sol";
import "./CloneableSanctuary.sol";

contract Pact is CloneableSanctuary {
  using ECDSA for bytes32;

  uint constant messagePrefix = 0x50616374 << 224;

  address private immutable sanctuaryImplementation;

  uint private next = 1;
  address private sanctuary;
  address[] private devotees = [address(0)];
  mapping(address => uint) public devoteeIndex;
  
  event Joined(address indexed devotee, uint indexed index);

  constructor(Edwone _edwone, address extractionChamber) CloneableSanctuary(extractionChamber, msg.sender, _edwone) {
    _edwone.setApprovalForAll(msg.sender, true);

    sanctuaryImplementation = address(new CloneableSanctuary(address(this), msg.sender, _edwone));
    sanctuary = address(this);
  }

  function join(bytes memory signature) external payable {
    bytes32 hash = bytes32(messagePrefix | uint160(msg.sender)).toEthSignedMessageHash();
    address signer = hash.recover(signature);

    require(signer == owner, "FORGERY: Who the hell do you think you are?");
    require(devoteeIndex[msg.sender] == 0, "CHILL: Already in the pact");
    require(edwone.isApprovedForAll(msg.sender, address(this)), "OKAY BUT: Approve this contract to send the worm");
    require(next == 1, "SORRY: Enrollment period is over");

    emit Joined(msg.sender, devotees.length);

    devoteeIndex[msg.sender] = devotees.length;
    devotees.push(msg.sender);
  }

  function execute(uint count) external {
    require(msg.sender == owner, "FEELS BAD: must be owner");
    require(count < type(uint160).max, "Easy there buddy");
    
    address holder = sanctuary;
    uint i = next;
    uint endBefore; 
    unchecked {
      endBefore = next + count;
      require(endBefore <= devotees.length, "OOPS: count is higher than remaining devotees");
    }

    while (i < endBefore) {
      address devotee = devotees[i];
      if (edwone.isApprovedForAll(devotee, address(this))) {
        edwone.transferFrom(holder, devotee, 0);
        holder = devotee;
      }

      unchecked {
        i++;
      }
    }

    address newSanctuary = Clones.clone(sanctuaryImplementation);
    CloneableSanctuary(newSanctuary).init();

    edwone.transferFrom(holder, newSanctuary, 0);
    next = i;
    sanctuary = newSanctuary;
  }

  function executeTo(address receipient) external {
    require(msg.sender == owner, "FEELS BAD: This address is not allowed to escort the worm");
    
    address holder = sanctuary;
    uint i = next;

    while (i < devotees.length) {
      address devotee = devotees[i];
      if (edwone.isApprovedForAll(devotee, address(this))) {
        edwone.transferFrom(holder, devotee, 0);
        holder = devotee;
      }

      unchecked {
        i++;
      }
    }

    edwone.transferFrom(holder, receipient, 0);
    next = i;
  }

  function escortWormTo(address receipient) external {
    require(msg.sender == owner, "FEELS BAD: This address is not allowed to escort the worm");
    require(next == devotees.length, "INCOMPLETE: All will receive their reward");

    edwone.transferFrom(sanctuary, receipient, 0);
  }

  function pactSize() external view returns (uint) {
    unchecked {
      return devotees.length - 1;
    }
  }

  function enrollmentOpen() external view returns (bool) {
    return next == 1;
  }
}
