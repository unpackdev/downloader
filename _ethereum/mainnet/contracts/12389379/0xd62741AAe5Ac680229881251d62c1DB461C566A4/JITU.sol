// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.4;

import "./LiquidityPool.sol";

interface Wallet {
    function preempt(address _liquidator, address _repayToken, uint _repayAmount, address _cTokenCollateral) external;

    function underwrite(address _token, uint256 _amount) external;
    function reclaim() external; 

    function checkBufferValue(address _token, uint256 _amount) external;
}

/// @dev this contract extends KeeperDAO's LiquidityPool contract, and users would be able 
///      to deposit supported tokens to this contract. 
/// @dev this contract allows whitelisted keepers to add buffer to compound positions that 
///      are slightly above water, so that in the case they go underwater the keepers can
///      preempt a liquidation.
/// @dev the behaviour of the whitelisted keepers is controlled by the token economics of 
///      KeeperDAO.
contract JITU is LiquidityPoolV3 {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct BufferProvided {
        address token;
        uint256 amount;
    }

    mapping (address=>BufferProvided[]) buffer;
    mapping (address=>bool) isWhitelistedKeeper;

    modifier onlyWhitelistedKeeper() {
        require(isWhitelistedKeeper[msg.sender], "JITU: caller is not a whitelisted keeper");
        _;
    }

    /// @notice whitelist the given keeper, add to the keeper
    ///         whitelist.
    /// @param _keeper the address of the keeper
    function whitelist(address _keeper) external onlyOperator {
        isWhitelistedKeeper[_keeper] = true;
    }

    /// @notice blacklist the given keeper, remove from the keeper
    ///         whitelist.
    /// @param _keeper the address of the keeper
    function blacklist(address _keeper) external onlyOperator {
        isWhitelistedKeeper[_keeper] = false;
    }

    /// @notice underwrite the given wallet, with the given amount of
    ///         compound tokens
    ///
    /// @param _wallet the address of the compound wallet
    /// @param _token the address of the ERC20 token
    /// @param _amount the amount of ERC20 tokens
    function underwrite(address _wallet, address _token, uint256 _amount) external onlyWhitelistedKeeper nonReentrant whenNotPaused {
        // This function reverts if the buffer being provided exceeds 
        // the max buffer value (which is 25% of the total compound 
        // position).
        Wallet(_wallet).checkBufferValue(_token, _amount);
        ERC20(_token).safeIncreaseAllowance(_wallet, _amount);
        Wallet(_wallet).underwrite(_token, _amount);

        loanedAmount[_token] = loanedAmount[_token].add(_amount);
        buffer[_wallet].push(BufferProvided(_token, _amount));
    }

    /// @notice reclaim the given amount of compound tokens
    ///          from the given wallet 
    ///
    /// @param _wallet the address of the compound wallet
    function reclaim(address _wallet) external onlyWhitelistedKeeper nonReentrant whenNotPaused {
        Wallet(_wallet).reclaim();
        BufferProvided[] memory buffers = buffer[_wallet];
        delete(buffer[_wallet]);
        for (uint i = 0; i < buffers.length; i++) {
            BufferProvided memory bufferProvided = buffers[i];
            loanedAmount[bufferProvided.token] 
                = loanedAmount[bufferProvided.token].sub(bufferProvided.amount);
        }
    }

    /// @notice preempt a liquidation that does a liquidation
    ///         without considering the buffer provided by JITU
    ///
    /// @param _wallet the address of the compound wallet
    /// @param _repayToken the address of the token that needs to be repaid
    /// @param _repayAmount the amount of the token that needs to be repaid
    /// @param _cTokenCollateral the compound token that the user would 
    ///         receive for repaying the loan
    function preempt(Wallet _wallet, address _repayToken, uint _repayAmount, address _cTokenCollateral) external onlyWhitelistedKeeper nonReentrant whenNotPaused {
        _wallet.preempt(msg.sender, _repayToken, _repayAmount, _cTokenCollateral);
    }
}