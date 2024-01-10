pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./CErc20PluginDelegate.sol";

contract CErc20PluginRewardsDelegate is CErc20PluginDelegate {
    /**
     * @notice Delegate interface to become the implementation
     * @param data The encoded arguments for becoming
     */
    function _becomeImplementation(bytes calldata data) external {
        require(msg.sender == address(this) || hasAdminRights());

        (address _plugin) = abi.decode(
            data,
            (address)
        );

        plugin = IERC4626(_plugin);
        EIP20Interface(underlying).approve(_plugin, uint256(-1));
    }

    /// @notice A reward token claim function 
    /// to be overriden for use cases where rewardToken needs to be pulled in
    function claim() external {}

    /// @notice token approval function
    function approve(address _token, address _spender) external {
        require(hasAdminRights(), "!admin");
        require(_token != underlying && 
                _token != address(plugin), "!");

        EIP20Interface(_token).approve(_spender, uint256(-1));
    }
}
