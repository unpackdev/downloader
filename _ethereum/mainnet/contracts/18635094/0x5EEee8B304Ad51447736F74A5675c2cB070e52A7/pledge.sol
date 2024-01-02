// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.19;

import "./Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract PledgeAcceptor is Pausable, AccessControlEnumerable{
    using SafeERC20 for IERC20;
    event PledgeToken(address from, uint256 amount);
    event Pledge(address from, uint256 amount);

     constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pledgeToken(IERC20 token, uint256 _value) external {
        require(msg.sender != address(0));
        require(_value > 0);
        // Transfer ERC-20 tokens from msg.sender to the contract
        token.safeTransferFrom(_msgSender(), address(this), _value);
        emit PledgeToken(msg.sender, _value);
    }

    function pledge() external payable {
        require(msg.sender != address(0));
        require(msg.value > 0);
        emit Pledge(msg.sender, msg.value);
    }

    function withdrawToken(IERC20 token, uint256 _value) external{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Must have admin role to withdraw");
        require(_value > 0);
        // Transfer ERC-20 tokens from contract to msg.sender
        token.safeTransfer(msg.sender, _value);
    }

    function withdraw(uint256 _value) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Must have admin role to withdraw");
        require(_value > 0);
        require(address(this).balance >= _value);
        address payable to = payable(msg.sender);
        to.transfer(_value);
    }

    /* Dont accept eth*/  
    receive() external payable {
        revert("The contract does not accept direct payment, please use the pledge method.");
    }

    function pause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Must have admin role to pause");
        _pause();
    }

    function unpause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"Must have admin role to unpause");
        _unpause();
    }
}
