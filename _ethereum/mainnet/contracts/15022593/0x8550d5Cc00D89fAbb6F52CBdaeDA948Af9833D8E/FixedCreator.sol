// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IFixedCreator.sol";
import "./FixedVesting.sol";

contract FixedCreator is IFixedCreator{
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
     * @param _datetime Vesting datetime in epoch
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function createVesting(
        address _token,
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) public override onlyOwner returns(address vesting){
        vesting = address(new FixedVesting());

        allVestings.push(vesting);
        
        FixedVesting(vesting).initialize(
            _token,
            _datetime,
            _ratio_d2
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