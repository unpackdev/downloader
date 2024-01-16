// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ImplBase.sol";
import "./errors.sol";
import "./optimism.sol";

/**
// @title Native Optimism Bridge Implementation.
// @author Socket Technology.
*/
contract NativeOptimismImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    L1StandardBridge  public bridgeProxy = L1StandardBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1); 

    /**
    // @notice We set all the required addresses in the constructor while deploying the contract.
    // These will be constant addresses.
    // @dev Please use the Proxy addresses and not the implementation addresses while setting these 
    // @param _registry address of the registry contract that calls this contract
    */
    constructor(
        address _registry
    ) ImplBase(_registry) {}


    /**
    // @param _amount amount to be sent.
    // @param _from sending address.
    // @param _receiverAddress receiving address.
    // @param _token address of the token to be bridged to optimism.
     */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256,
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {

        (   
            address _l2Token,
            uint32 _l2Gas,
            bytes memory _data
        ) = abi.decode(_extraData, (address, uint32, bytes));


        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            bridgeProxy.depositETHTo{value: _amount}(_receiverAddress, _l2Gas, _data);
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20 token = IERC20(_token);
        // set allowance for erc20 predicate
        token.safeTransferFrom(_from, address(this), _amount);
        token.safeIncreaseAllowance(address(bridgeProxy), _amount);

        // deposit into standard bridge
        bridgeProxy.depositERC20To(_token, _l2Token, _receiverAddress, _amount, _l2Gas, _data);
    }
}
