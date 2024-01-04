pragma solidity ^0.6.0;

import "./DSProxyInterface.sol";
import "./SafeERC20.sol";

/// @title Pulls a specified amount of tokens from the EOA owner account to the proxy
contract PullTokensProxy {
    using SafeERC20 for ERC20;

    /// @notice Pulls a token from the proxyOwner -> proxy
    /// @dev Proxy owner must first give approve to the proxy address
    /// @param _tokenAddr Address of the ERC20 token
    /// @param _amount Amount of tokens which will be transfered to the proxy
    function pullTokens(address _tokenAddr, uint _amount) public {
        address proxyOwner = DSProxyInterface(address(this)).owner();

        ERC20(_tokenAddr).safeTransferFrom(proxyOwner, address(this), _amount);
    }
}
