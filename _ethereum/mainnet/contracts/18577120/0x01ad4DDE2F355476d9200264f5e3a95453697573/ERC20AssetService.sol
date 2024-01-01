// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// OpenZeppelin imports
import "./SafeERC20.sol";
import "./IERC20.sol";

// Local imports - Errors
import "./RaiseErrors.sol";

library ERC20AssetService {
    using SafeERC20 for IERC20;

    /// @dev Collect vested ERC20 to start a raise.
    /// @dev Validation: Requires startup to have enough ERC20 and provide allowance.
    /// @dev Events: Transfer(address from, address to, uint256 value).
    /// @param _token Address of ERC20
    /// @param _sender Address of startup to withdraw ERC20 from
    /// @param _escrow Address of cloned Escrow instance for raise
    /// @param _amount Amount of ERC20 to collect
    function collectVestedToken(address _token, address _sender, address _escrow, uint256 _amount) internal {
        // tx.members
        address self_ = address(this);

        // erc20
        IERC20 erc20_ = IERC20(_token);

        // allowance check
        uint256 allowance_ = erc20_.allowance(_sender, self_);

        // validate if allowance greater or equal amount
        if (allowance_ < _amount) {
            revert RaiseErrors.NotEnoughAllowance(_sender, self_, allowance_);
        }

        // vest erc20
        erc20_.safeTransferFrom(_sender, _escrow, _amount);
    }
}
