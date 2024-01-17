// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./DruzhbaStateMachine.sol";

contract Druzhba is DruzhbaStateMachine {
    using Address for address;
    
    string public constant VERSION = "3.0";

    constructor(uint256 chainId, address admin, address signer) DruzhbaStateMachine(chainId, admin, signer) {}

    function _transfer(address token, address _to, uint256 _value) internal override {
        SafeERC20.safeTransfer(IERC20(token), _to, _value);
    }

    function _transferFrom(address token, address _from, address _to, uint256 _value) internal override {
        SafeERC20.safeTransferFrom(IERC20(token), _from, _to, _value);
    }
}

