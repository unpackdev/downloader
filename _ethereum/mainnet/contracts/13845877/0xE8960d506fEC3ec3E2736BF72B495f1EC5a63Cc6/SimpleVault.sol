//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
//import "./Ownable.sol";
import "./AccessibleCommon.sol";

//import "./console.sol";

contract SimpleVault is AccessibleCommon {
    using SafeERC20 for IERC20;

    address public tos;
    string public name;

    constructor(address tosAddress, string memory _name) {
        require(tosAddress != address(0), "SimpleVault: zero address");
        tos = tosAddress;
        name = _name;
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function claimTOS(address to, uint256 amount) external onlyOwner {
        require(
            IERC20(tos).balanceOf(address(this)) >= amount,
            "SimpleVault: insufficent"
        );
        IERC20(tos).transfer(to, amount);
    }

    function claimERC20(
        address _token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(
            IERC20(_token).balanceOf(address(this)) >= amount,
            "SimpleVault: insufficent"
        );
        IERC20(_token).safeTransfer(to, amount);
    }

    function balanceTOS() external view returns (uint256) {
        return IERC20(tos).balanceOf(address(this));
    }

    function balanceERC20(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
}
