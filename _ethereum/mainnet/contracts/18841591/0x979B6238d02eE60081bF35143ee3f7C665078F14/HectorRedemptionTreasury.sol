// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ITokenVault.sol";
import "./IFNFT.sol";
import "./LockAccessControl.sol";

error INVALID_ADDRESS();
error INVALID_AMOUNT();
error INVALID_TOKEN();
error INVALID_RECIPIENT();
error INSUFFICIENT_FUND();

contract HectorRedemptionTreasury is LockAccessControl, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ======== STORAGE ======== */

    /// @notice Deposited tokens set
    EnumerableSet.AddressSet private tokensSet;


    /* ======== EVENTS ======== */

    event Deposited(address indexed who, address indexed token, uint256 amount);
    event SendRedemption(address indexed who, uint256 fnftid, uint256 amount);

    /* ======== INITIALIZATION ======== */
    constructor(address provider) LockAccessControl(provider) {}

    /* ======== POLICY FUNCTIONS ======== */

    function pause() external onlyModerator {
        _pause();
    }

    function unpause() external onlyModerator {
        _unpause();
    }

    /**
        @notice transfer redemption funds to user
        @param rnftid  fnft id
        @param _token  token address
        @param _to  recipient address
        @param _amount  amount to transfer
     */
    function transferRedemption(uint256 rnftid, address _token, address _to, uint256 _amount) external onlyModerator {   
        IRedemptionNFT fnft = getRNFT();

        if (_token == address(0)) revert INVALID_ADDRESS();
        if (_to == address(0)) revert INVALID_ADDRESS();     
        if (!tokensSet.contains(_token)) revert INVALID_TOKEN();
        if (fnft.ownerOf(rnftid) != _to || fnft.balanceOf(_to) == 0) revert INVALID_RECIPIENT();

        uint256 balance = IERC20(_token).balanceOf(address(this));

        if (balance < _amount) revert INSUFFICIENT_FUND();

        IERC20(_token).safeTransfer(_to, _amount);

        emit SendRedemption(_to, rnftid, _amount);
    }

    /**
        @notice withdraw all tokens
     */    
    function withdrawAll() external onlyModerator {
        uint256 length = tokensSet.length();

        for (uint256 i = 0; i < length; i++) {
            address token = tokensSet.at(0);
            uint256 balance = IERC20(token).balanceOf(address(this));

            if (balance > 0) {
                IERC20(token).safeTransfer(owner(), balance);
            }

            bool status = tokensSet.remove(token);
            if (!status) revert INVALID_ADDRESS();
        }
    }

    /**
        @notice Deposit token to treasury for redemption
        @param _token  token address
        @param _amount  amount to deposit
     */
    function deposit(address _token, uint256 _amount) external whenNotPaused onlyModerator {
        if (_token == address(0)) revert INVALID_ADDRESS();
        if (_amount == 0) revert INVALID_AMOUNT();

        bool status = tokensSet.add(_token);
        if (!status) revert INVALID_ADDRESS();

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposited(msg.sender, _token, _amount);
    }

}
