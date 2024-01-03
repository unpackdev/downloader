// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./OFTV2.sol";
import "./SafeERC20.sol";

contract WASG is OFTV2 {
    IERC20 public asg;
    using SafeERC20 for IERC20;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(
        address _layerZeroEndpoint,
        uint8 _sharedDecimals,
        address _asg
    ) OFTV2("Wrapped ASG", "WASG", _sharedDecimals, _layerZeroEndpoint) {
        asg = IERC20(_asg);
    }

    function deposit(uint256 amount) public {
        require(asg.balanceOf(_msgSender()) >= amount, "WASG: exceed balance");
        _mint(_msgSender(), amount);
        asg.transferFrom(_msgSender(), address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "WASG: exceed balance");
        _burn(_msgSender(), amount);
        asg.transfer(_msgSender(), amount);
        emit Withdrawal(msg.sender, amount);
    }

    function withdrawTokens(IERC20 token, address recipient, uint256 amount) public onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.safeTransfer(recipient, amount);
    }
}
