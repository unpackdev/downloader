// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IVirtualBalanceWrapper.sol";
import "./BaseReward.sol";

contract SupplyRewardFactory {
    event NewOwner(address indexed sender, address operator);
    event RemoveOwner(address indexed sender, address operator);
    event CreateReward(address pool, address rewardToken);

    mapping(address => bool) private owners;

    modifier onlyOwners() {
        require(
            isOwner(msg.sender),
            "SupplyRewardFactory: caller is not an owner"
        );
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address _newOwner) public onlyOwners {
        require(
            !isOwner(_newOwner),
            "SupplyRewardFactory: address is already owner"
        );

        owners[_newOwner] = true;

        emit NewOwner(msg.sender, _newOwner);
    }

    function addOwners(address[] calldata _newOwners) external onlyOwners {
        for (uint256 i = 0; i < _newOwners.length; i++) {
            addOwner(_newOwners[i]);
        }
    }

    function removeOwner(address _owner) external onlyOwners {
        require(isOwner(_owner), "SupplyRewardFactory: address is not owner");

        owners[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) public onlyOwners returns (address) {
        BaseReward pool = new BaseReward(
            _rewardToken,
            _virtualBalance,
            _owner
        );

        emit CreateReward(address(pool), _rewardToken);

        return address(pool);
    }
}
