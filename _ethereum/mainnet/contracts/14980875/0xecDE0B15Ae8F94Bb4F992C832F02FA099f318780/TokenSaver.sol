// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";

contract TokenSaver is AccessControlEnumerableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant TOKEN_SAVER_ROLE = keccak256("TOKEN_SAVER_ROLE");

    event TokenSaved(
        address indexed by,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    modifier onlyTokenSaver() {
        require(
            hasRole(TOKEN_SAVER_ROLE, _msgSender()),
            "TokenSaver.onlyTokenSaver: permission denied"
        );
        _;
    }

    function __TokenSaver_init() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function saveToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyTokenSaver {
        IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        emit TokenSaved(_msgSender(), _receiver, _token, _amount);
    }
}
