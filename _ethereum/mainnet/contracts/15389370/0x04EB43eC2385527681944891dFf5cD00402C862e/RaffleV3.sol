//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauserUpgradeable.sol";

import "./RaffleV2.sol";

contract RaffleV3 is RaffleV2 {
    ERC1155PresetMinterPauserUpgradeable public key;
    mapping(uint256 => bool) private _claimed;
    bool public keyClaimLive;

    function initializeV3() public reinitializer(3) {}

    function keyClaim(
        uint256[] calldata ids_
    )
        external
        whenNotPaused
        nonReentrant
    {
        require(keyClaimLive, "Not live");
        uint256 length = ids_.length;
        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids_[i];
            require(_tokenToOwner[current] == msg.sender, "Not Owner");
            require(!isClaimed(current), "Already claimed");
            _claimed[current] = true;
        }
        key.mint(
            msg.sender,
            1,
            length,
            ""
        );
    }

    function setKey(ERC1155PresetMinterPauserUpgradeable key_) external onlyOwner {
        key = key_;
    }

    function isClaimed(uint256 id) public view returns (bool) {
        return _claimed[id];
    }

    function toggleKeyClaim() external onlyOwner {
        keyClaimLive = !keyClaimLive;
    }
}