// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";

contract MBytesERC20 is ERC20, Ownable {

    address rewardsAddress;

    constructor() ERC20("Moon Chip Byte", "MBYTE") { }

    /**
     * @dev Rewards the owner of moonchips NFTs from Rewards Contract
     * @param _to address from reward
     * @param _amount amount to reward
     * `msg.sender` must be the the rewards contract
     */
    function rewardMbytes(address _to, uint256 _amount)
        external
    {
        require(rewardsAddress != address(0x0), "Rewards contract address is not set");
        require(msg.sender == rewardsAddress, "Only rewards contract can give out rewards");
        _mint(_to, _amount);
    }

    /**
     * @dev Sets the moonchip rewards address
     * @param _rewardsAddress The mbytes address
     */
    function setRewardsAddress(address _rewardsAddress) public onlyOwner {
        rewardsAddress = _rewardsAddress;
    }

}
