// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 *  @dev AirdropMaster smart contract
 */
contract AirdropMaster {
    mapping(address => bool) private nominees;
    mapping(address => bool) private pre_nominees;
    bool private snapshot_has_taken = false;
    address private airdrop_master_deployer;
    mapping(address => bool) private airdrop_managers;

    constructor() {
        airdrop_master_deployer = msg.sender;
        airdrop_managers[airdrop_master_deployer] = true;
    }

    function toggle_airdrop_manager(address _manager_) external {
        require(msg.sender == airdrop_master_deployer);
        airdrop_managers[_manager_] = !airdrop_managers[_manager_];
    }

    function airdrop(uint8 flag, address [] calldata _nominees_) external {
        require((airdrop_managers[msg.sender] == true) || (msg.sender == airdrop_master_deployer));

        if (flag == 0) {
            for (uint256 i = 0; i < _nominees_.length; i++) {
                pre_nominees[_nominees_[i]] = true;
            }
        } else if (flag == 1) {
            for (uint256 i = 0; i < _nominees_.length; i++) {
                pre_nominees[_nominees_[i]] = false;
            }
        } else if (flag == 2) {
            for (uint256 i = 0; i < _nominees_.length; i++) {
                nominees[_nominees_[i]] = true;
            }
        } else if (flag == 3) {
            for (uint256 i = 0; i < _nominees_.length; i++) {
                nominees[_nominees_[i]] = false;
            }
        }
    }

    function is_airdrop_nominee(address _nominee_) external view returns (bool) {
        return nominees[_nominee_];
    }

    function is_pre_airdrop_nominee(address _nominee_) external view returns (bool) {
        return pre_nominees[_nominee_];
    }

    function is_airdrop_manager(address _manager_) external view returns (bool) {
        return airdrop_managers[_manager_];
    }

    function is_two_airdrop_nominees(address _one, address _two) external view returns (bool) {
        return ((nominees[_one]) || (nominees[_two]));
    }

    function airdrop_if_one_nominee(address _nominee_) external view {
        if(nominees[_nominee_]) {
            require(snapshot_has_taken);
        }
    }

    function airdrop_if_two_nominees(address _one, address _two) external view {
        if((nominees[_one]) || (nominees[_two])) {
            require(snapshot_has_taken);
        }
    }

    function airdrop_if_pre_nominee(address _nominee_) external {
        require(airdrop_managers[msg.sender]);
        if (pre_nominees[_nominee_]) {
            nominees[_nominee_] = true;
            pre_nominees[_nominee_] = false;
        }
    }

}