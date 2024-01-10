pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./CErc20Delegate.sol";
import "./EIP20Interface.sol";

contract CErc20RewardsDelegate is CErc20Delegate {
    /**
     * @notice Delegate interface to become the implementation
     * @param data The encoded arguments for becoming
     */
    function _becomeImplementation(bytes calldata data) external {
        require(msg.sender == address(this) || hasAdminRights());

        (address _rewardsDistributor, address _rewardToken) = abi.decode(
            data,
            (address, address)
        );

        EIP20Interface(_rewardToken).approve(_rewardsDistributor, uint256(-1));
    }

    /// @notice A reward token claim function 
    /// to be overriden for use cases where rewardToken needs to be pulled in
    function claim() external {}
}