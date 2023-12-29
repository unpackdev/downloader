// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./LibBytes.sol";
import "./IOneTwoRouterFacet.sol";
import "./GenericErrors.sol";

contract Executor is AccessControl {
    address private diamond;
    bytes32 public constant EXECUTOR_ROLE = keccak256('EXECUTOR_ROLE');

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setDiamond(address _diamond) external onlyRole(DEFAULT_ADMIN_ROLE) {
        diamond = _diamond;
    }

    function executeReceiverSwap(
        bytes memory _payload,
        IERC20 _token,
        uint256 _amount
    ) external onlyRole(EXECUTOR_ROLE) {
        if(_token.balanceOf(address(this)) < _amount) revert InvalidAmount();

        uint256 legnth = _payload.length;

        if(legnth == 20) {
            address receiver = LibBytes.toAddress(_payload, 0);

            _token.transfer(receiver, _amount);
        } else if (legnth > 20) {
            address receiver = LibBytes.toAddress(_payload, 0);
            bytes memory payload = LibBytes.slice(_payload, 84, legnth - 84);
            bytes memory _calldata = abi.encode(payable(receiver), _amount);
        
            _token.approve(diamond, _amount);

            (bool success,) = diamond.call(
                abi.encodePacked(
                    IOneTwoRouterFacet.oneTwoSwap.selector, 
                    _calldata, 
                    payload
                )
            );

            require(success, "Can't swap");
        } else {
            revert InformationMismatch();
        }
    }
}

