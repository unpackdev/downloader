pragma solidity 0.5.12;

import "./Ownable.sol";
import "./RewardEscrow.sol";

contract VestingPusher is Ownable {

    RewardEscrow public rewardEscrow;

    constructor(address _rewardEscrow) public {
        Ownable.initialize(msg.sender);
        rewardEscrow = RewardEscrow(_rewardEscrow);
    }

    function addVesting(address[] calldata _receivers, uint256[] calldata _amounts) external onlyOwner {
        require(_receivers.length == _amounts.length, "ARRAY_LENGTH_MISMATCH");
        
        for(uint256 i = 0; i < _receivers.length; i ++) {
            // Tokens should already be in rewardEscrow contract
            rewardEscrow.appendVestingEntry(_receivers[i], _amounts[i]);
        }
    }
}