// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./IVoyBridge.sol";


contract XDCBridge is IVoyBridge, Pausable, AccessControl {
    address public voyToken;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event SwapStarted(address _user, uint256 _amount);
    event SwapReturned(address _user, uint256 _amount, string _xcdTxHash);

    constructor(address _voyToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

       voyToken = _voyToken;
    }

    function initiateSwap(address _user, uint256 _amount) external override whenNotPaused {
        require(msg.sender == voyToken, "Invalid caller");

        ERC20(voyToken).transferFrom(_user, address(this), _amount);
        emit SwapStarted(_user, _amount);
    }

    function returnSwap(address _user, uint256 _amount, string memory _xdcTxHash) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        ERC20(voyToken).transfer(_user, _amount);
        emit SwapReturned(_user, _amount, _xdcTxHash);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}