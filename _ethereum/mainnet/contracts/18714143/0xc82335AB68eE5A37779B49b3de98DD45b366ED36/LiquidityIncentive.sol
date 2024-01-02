// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Errors.sol";

contract LiquidityIncentive is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public constant NAME = "LiquidityIncentive";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function transferETH(address _to, uint256 _amount) external onlyOwner {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert Errors.SendETHFailed();
        }
    }

    function transferERC20(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    // --- Fallback function ---
    receive() external payable {}
}
