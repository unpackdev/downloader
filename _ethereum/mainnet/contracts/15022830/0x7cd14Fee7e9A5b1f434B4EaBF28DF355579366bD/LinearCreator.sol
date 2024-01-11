// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ILinearCreator.sol";
import "./LinearVesting.sol";

contract LinearCreator is ILinearCreator{
    address[] public override allVestings; // all vestings created
    
    address public override owner = msg.sender;
    
    modifier onlyOwner{
        require(owner == msg.sender, "!owner");
        _;
    }
    
    /**
     * @dev Get total number of vestings created
     */
    function allVestingsLength() public override view returns (uint) {
        return allVestings.length;
    }
    
    /**
     * @dev Create new vesting to distribute token
     * @param _token Token project address
     * @param _tgeDatetime TGE datetime in epoch
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function createVesting(
        address _token,
        uint32 _tgeDatetime,
        uint32 _tgeRatio_d2,
        uint32[2] calldata _startEndLinearDatetime
    ) public override onlyOwner returns(address vesting){
        vesting = address(new LinearVesting());

        allVestings.push(vesting);
        
        LinearVesting(vesting).initialize(
            _token,
            _tgeDatetime,
            _tgeRatio_d2,
            _startEndLinearDatetime
        );
        
        emit VestingCreated(vesting, allVestings.length - 1);
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) public override onlyOwner{
        require(_newOwner != address(0) && _newOwner != owner, "!good");
        owner = _newOwner;
    }
    
}