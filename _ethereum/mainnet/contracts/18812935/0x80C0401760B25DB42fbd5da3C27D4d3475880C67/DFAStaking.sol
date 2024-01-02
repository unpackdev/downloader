// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./IERC721A.sol";

import "./PausableUpgradeable.sol";
import "./AdminManagerUpgradable.sol";
import "./IERC721Receiver.sol";

contract DFAStaking is Initializable, IERC721Receiver, AdminManagerUpgradable, PausableUpgradeable {
    IERC721A public lcm;
    IERC721A public gcm;

    mapping(uint256 => address) public lcmOwnerOf;
    mapping(uint256 => address) public gcmOwnerOf;

    event Stake(address owner, uint256[] lcmIds, uint256[] gcmIds, uint256 timestamp);
    event Unstake(address owner, uint256[] lcmIds, uint256[] gcmIds, uint256 timestamp);

    function initialize(
        address lcm_,
        address gcm_
    ) initializer public {
        lcm = IERC721A(lcm_);
        gcm = IERC721A(gcm_);
        __AdminManager_init_unchained();
        __Pausable_init_unchained();        
    }

    function stake(uint256[] calldata lcmIds, uint256[] calldata gcmIds) external whenNotPaused {
        require(lcmIds.length > 0 || gcmIds.length > 0, "No tokens");

        for (uint256 i = 0; i < lcmIds.length; i++) {
            uint256 id = lcmIds[i];
            lcmOwnerOf[id] = msg.sender;
            lcm.transferFrom(msg.sender, address(this), id);
        }

        for (uint256 i = 0; i < gcmIds.length; i++) {
            uint256 id = gcmIds[i];
            gcmOwnerOf[id] = msg.sender;
            gcm.transferFrom(msg.sender, address(this), id);
        }

        emit Stake(msg.sender, lcmIds, gcmIds, block.timestamp);
    }

    function unstake(uint256[] calldata lcmIds, uint256[] calldata gcmIds) external whenNotPaused {
        require(lcmIds.length > 0 || gcmIds.length > 0, "No tokens");
        
        for (uint256 i = 0; i < lcmIds.length; i++) {
            uint256 id = lcmIds[i];
            require(lcmOwnerOf[id] == msg.sender, "Not owner");
            lcmOwnerOf[id] = address(0);
            lcm.transferFrom(address(this), msg.sender, id);
        }

        for (uint256 i = 0; i < gcmIds.length; i++) {
            uint256 id = gcmIds[i];
            require(gcmOwnerOf[id] == msg.sender, "Not owner");
            gcmOwnerOf[id] = address(0);
            gcm.transferFrom(address(this), msg.sender, id);
        }

        emit Unstake(msg.sender, lcmIds, gcmIds, block.timestamp);
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setTokens(address lcm_, address gcm_) external onlyAdmin {
        lcm = IERC721A(lcm_);
        gcm = IERC721A(gcm_);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}