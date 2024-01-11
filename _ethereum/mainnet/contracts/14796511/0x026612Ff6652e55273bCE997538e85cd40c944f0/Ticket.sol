// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ECDSA.sol";
import "./Ownable.sol";

import "./ITicket.sol";

error InvalidSignature();
error InvalidSpotId();
error InvalidSignerAddress();
error InvalidOperator();
error AlreadyMinted();

contract Ticket is Ownable, ITicket {
    using ECDSA for bytes32;

    // maximum value of an unsigned 256-bit integer
    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256[] private _claimGroups;
    address private _signer = address(0);

    address public operator;

   /**
    * Public view functions
    */

    function isValidSpot(uint256 spotId) public view returns (bool) {
        if (spotId >= _claimGroups.length * 256) revert InvalidSpotId();

        uint256 groupIndex = spotId / 256;
        uint256 spotIndex = spotId % 256;
        uint256 localGroup = _claimGroups[groupIndex];
        uint256 storedBit = (localGroup >> spotIndex) & uint256(1);

        return storedBit == 1;
    }

    function checkVerify(bytes calldata _signature, address user, uint256 spotId) external view returns(bool) {
        if (
            !_verify(
                keccak256(abi.encodePacked(user, spotId)),
                _signature
            )
        ) return false;
        else {
        return true;
        }
    }

    /**
    * Authorized functions
    */

    // this technique is adopted from https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0
    // it saves buyers from expensive SSTORE operations when marking an allowlist spot as "used"
    function claimAllowlistSpot(bytes calldata _signature, address user, uint256 spotId)
        external override
    {   
        if (msg.sender != operator) revert InvalidOperator();
        if (
            !_verify(
                keccak256(abi.encodePacked(user, spotId)),
                _signature
            )
        ) revert InvalidSignature();

        // make sure the spot ID can fit somewhere in the array
        // (ie, spotId of 1000 if claimGroups can only store 256 bytes, is invalid)
        if (spotId >= _claimGroups.length * 256) revert InvalidSpotId();

        uint256 groupIndex;
        uint256 spotIndex;
        uint256 localGroup;
        uint256 storedBit;

        unchecked {
            // which index of the claimGroups array the provided ID falls into
            // for ex, if the ID is 256, then we're in group[1]
            // (group[0] would be 0-255, group[1] would be 256-511, etc)
            groupIndex = spotId / 256;
            // which of the 256 bits in that group the ID falls into
            spotIndex = spotId % 256;
        }

        // assign the group we're interested into a temporary variable
        localGroup = _claimGroups[groupIndex];

        // shift the group bits to the right by the number of bits at the specified index
        // this puts the bit we care about at the rightmost position
        // bitwise AND the result with a 1 to zero-out everything except the bit being examined
        storedBit = (localGroup >> spotIndex) & uint256(1);
        // if we got a 0, then the spot is already claimed
        if (storedBit == 0) revert AlreadyMinted();

        // zero-out the bit at the specified index by shifting it back to its original spot, and then bitflip
        localGroup = localGroup & ~(uint256(1) << spotIndex);

        // store the modified group back into the array
        // this modified group will have the spot ID set to 1 at its corresponding index
        _claimGroups[groupIndex] = localGroup;
    }

    /**
     *  Only owner functions
     */

    function setOperator(address operator_) public onlyOwner {
        operator = operator_;
    }

    function setClaimGroups(uint256 numSlots) public onlyOwner {
        // fill claimGroups array with MAX_INTs. Each group accounts for 256 spots.
        uint256 slotCount = (numSlots / 256) + 1;
        uint256[] memory arr = new uint256[](slotCount);

        for (uint256 i; i < slotCount; i++) {
            arr[i] = MAX_INT;
        }

        _claimGroups = arr;
    }

    function setSigner(address signer_) public onlyOwner {
        _signer = signer_;
    }

    /**
     * Internal functions
     */

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        if (_signer == address(0)) revert InvalidSignerAddress();
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _signer;
    }
}