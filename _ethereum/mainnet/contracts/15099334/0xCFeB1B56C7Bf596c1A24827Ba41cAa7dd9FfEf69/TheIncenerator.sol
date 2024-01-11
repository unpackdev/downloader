//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

// Contract by: @backseats_eth

contract TheIncinerator is Ownable {

  // The Jar Dude contract address
  ERC721A public jarDudeContract = ERC721A(0xB4711Bfa7D063200eCAB54529807B53A0d3C17CC);

  // 10_000 1s that we flip to 0s when a particular ID has been burned
  uint256[] _burnedIdSlots;

  // Phases allow us to define the burn rules around a particular burn event
  struct Phase {
    // Phase ID
    uint8 id;

    // How many an address can burn in this phase
    uint16 burnsPerAddress;

    // How many burn slots remain in this phase
    uint16 slotsRemaining;
  }

  // Maps the Phase ID to the address and how many tokens the address has burnt
  mapping (uint256 => mapping (address => uint256)) public burnCountForPhase;

  // An array of phases, sequentially. phases[0] will be Phase 0, phases[1] will be Phase 1, etc.
  Phase[] public phases;

  // A boolean that handles reentrancy
  bool private reentrancyLock;

  // Event

  event tokenBurned(uint256 indexed _id, address indexed _by);

  // Modifier

  // Prevents reentrancy attacks. Thanks LL.
  modifier reentrancyGuard {
      if (reentrancyLock) revert();

      reentrancyLock = true;
      _;
      reentrancyLock = false;
  }

  // Allows a user to burn their Jar Dude tokens and record the necessary information
  function burn(uint256[] calldata _ids) external reentrancyGuard() {
    require(jarDudeContract.isApprovedForAll(msg.sender, address(this)), "Not approved to burn Jar Dudes");
    Phase memory _currentPhase = phases[phases.length - 1];
    require(_currentPhase.slotsRemaining > 0, "Phase is over");
    uint256 length = _ids.length;

    // Note: The problem here is that someone can just move pieces to a new address and burn
    require(burnCountForPhase[_currentPhase.id][msg.sender] + length <= _currentPhase.burnsPerAddress, "Max burns per address hit");

    // Ensures that msg.sender's burns wouldn't exceed the remaining slot count
    require(_currentPhase.slotsRemaining - length >= 0, "Too many burns");

    for(uint256 i; i < length;) {
      uint256 id = _ids[i];
       // Flips the bit from 1 to 0 for that ID, to indicate that it has been burned
      _recordIdBurned(id);

      // ERC721A protects against sending to the burn address, so this is a workaround
      jarDudeContract.transferFrom(msg.sender, address(0x0000000000000000000000000000000000000001), id);

      // Emit a tokenBurned event
      emit tokenBurned(id, msg.sender);

      unchecked {
        // 1. Increment the burn count for the address for the phase
        ++burnCountForPhase[_currentPhase.id][msg.sender];

        // 2. Reduce the amount of burn slots for phase
        --_currentPhase.slotsRemaining;

        // 3. Increment the loop
        ++i;
      }
    }

    // Replace the last element of the phases array with the changes
    phases[phases.length - 1] = _currentPhase;
  }

  // Internal Functions

  /// @notice To check and Jar Dude Ids being burned
  /// @dev Returns error if id is larger than range or has been burned already
  /// @dev Uses bit manipulation in place of mapping
  /// @dev https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0
  /// @param _jarDudeId id of the token being burned
  function _recordIdBurned(uint256 _jarDudeId) internal {
    require(_jarDudeId < _burnedIdSlots.length * 256, "Invalid");

    uint256 storageOffset; // [][][]
    uint256 localGroup; // [][x][]
    uint256 offsetWithin256; // 0xF[x]FFF

    unchecked {
      storageOffset = _jarDudeId / 256;
      offsetWithin256 = _jarDudeId % 256;
    }
    localGroup = _burnedIdSlots[storageOffset];

    // [][x][] > 0x1111[x]1111 > 1
    require((localGroup >> offsetWithin256) & uint256(1) == 1, "Already burned");

    // [][x][] > 0x1111[x]1111 > (1) flip to (0)
    localGroup = localGroup & ~(uint256(1) << offsetWithin256);

    _burnedIdSlots[storageOffset] = localGroup;
  }

  // Ownable

  // Thanks @xtremetom. Credit: https://www.contractreader.io/contract/0x86c10d10eca1fca9daf87a279abccabe0063f247
  // This is a cheaper way of handlnig which IDs have been burned rather than using a mapping
  function setBurnSlotLength(uint256 num) external onlyOwner {
    // Prevents over-filling
    require(num <= 10_000, "Bad id");

    // Account for solidity rounding down
    uint256 slotCount = (num / 256) + 1;

    // Set each element in the slot to binaries of 1
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Create a temporary array based on number of slots required
    uint256[] memory arr = new uint256[](slotCount);

    // Fill each element with MAX_INT
    for (uint256 i; i < slotCount; i++) {
      arr[i] = MAX_INT;
    }

    _burnedIdSlots = arr;
  }

  // Creates a new phase with rules about total slots for Jar Dudes that can be burned and how many per address someone can burn
  // Note: if you want to make _burnPerAddress "unlimited", set it to the value of _totalSlots
  function createNewPhase(uint16 _burnsPerAddress, uint16 _totalSlots) external onlyOwner {
    require(_burnsPerAddress > 0 && _totalSlots > 0, "Must be > 0");
    require(_burnsPerAddress <= _totalSlots, "Size mismatch");

    Phase memory phase = Phase({
      id: uint8(phases.length),
      burnsPerAddress: _burnsPerAddress,
      slotsRemaining: _totalSlots
    });

    // Append the new phase to the phases array
    phases.push(phase);
  }

  /// @notice A convenience function to view the current phase's ID
  function currentPhaseId() view external returns (uint8) {
    return phases[phases.length - 1].id;
  }

  /// @notice A convenience function to view the number of Jar Dudes that can be burned per address for the current phase
  function currentPhaseBurnsPerAddress() view external returns (uint16) {
    return phases[phases.length - 1].burnsPerAddress;
  }

  /// @notice A convenience function to see how many more Jar Dudes can be burned this phase
  function currentPhaseSlotsRemaining() view external returns (uint16) {
    return phases[phases.length - 1].slotsRemaining;
  }

}
