// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IStargateReceiver.sol";
import "./ITokenKeeper.sol";

import "./IERC20.sol";

import "./Error.sol";
import "./ERC20Utils.sol";

contract StargateReceiver is IStargateReceiver {
    address public immutable stargateRouter;
    address public immutable tokenKeeper;

    constructor(address _stargateRouter, address _tokenKeeper) {
        if (_stargateRouter == address(0)) revert Error.ZeroAddress();
        if (_tokenKeeper == address(0)) revert Error.ZeroAddress();

        stargateRouter = _stargateRouter;
        tokenKeeper = _tokenKeeper;
    }

    /// @inheritdoc IStargateReceiver
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 _amountLD,
        bytes memory _payload
    ) external {
        if (msg.sender != stargateRouter) {
            revert InvalidSender();
        }

        emit Received(_chainId, _srcAddress, _nonce, _token, _amountLD, _payload);

        address account = abi.decode(_payload, (address));

        ERC20Utils._approve(IERC20(_token), tokenKeeper, _amountLD);
        ITokenKeeper(tokenKeeper).transferFromStargateReceiver(account, _token, _amountLD);
    }
}
