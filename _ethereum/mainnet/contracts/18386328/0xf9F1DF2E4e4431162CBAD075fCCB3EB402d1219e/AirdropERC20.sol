// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*
            ██████                                                                                  
           ████████         █████████     ██████████     ███  ████         ███                      
            ██████        █████████████ ██████████████   ████ ██████      ████                      
              ██        ████████  ████ ██████    ██████  ████ ███████     ████                      
              ██       █████          █████        █████ ████ █████████   ████                      
              ██       █████          ████         █████ ████ ████ ██████ ████                      
             ████      █████          ████         █████ ████ ████  ██████████                      
            █████       █████         █████        █████ ████ ████    ████████                      
           ████████      █████████████ ████████████████  ████ ████     ███████                      
          ████  ████      █████████████  ████████████    ████ ████       █████                      
        █████    █████        █████          ████                                                   
      ██████      ██████                                                                            
    ██████         ███████                                                                          
  ████████          ████████           ███████████  █████████████████        ████  ████ ████████████
 ████████           █████████        █████████████  ███████████████████      ████ █████ ████████████
█████████           ██████████     ███████          █████        ████████    ████ █████ ████        
██████████         ████████████    █████            █████        █████████   ████ █████ ████        
██████████████   ██████████████    █████   ████████ ████████████ ████ ██████ ████ █████ ███████████ 
███████████████████████████████    █████   ████████ ██████████   ████  ██████████ █████ ██████████  
███████████████████████████████    ██████      ████ █████        ████    ████████ █████ ████        
 █████████████████████████████      ███████████████ ████████████ ████      ██████ █████ ████████████
  ██████████████████████████          █████████████ █████████████████       █████ █████ ████████████
 */

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

/**
 * @title AirdropERC20
 * @author @neuro_0x
 * @dev A contract for distributing ERC20 tokens to a list of recipients.
 */
contract AirdropERC20 is ReentrancyGuard {
    /// @dev The address of the native token (ETH).
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /////////////////////////////////////////////////////////////////
    //                           Events                            //
    /////////////////////////////////////////////////////////////////

    /// @dev Emitted when an failed airdrop occurs.
    event AirdropFailed(
        address indexed tokenAddress, address indexed tokenOwner, address indexed recipient, uint256 amount
    );

    /////////////////////////////////////////////////////////////////
    //                           Errors                            //
    /////////////////////////////////////////////////////////////////

    /// @notice Reverts when the token is not an ERC20 token.
    error NotERC20();

    /// @notice Reverts when there are no recipients.
    error NoRecipients();

    /// @notice Reverts when the token address is zero.
    error TokenAddressZero();

    /// @notice Reverts when the sender does not have enough balance.
    error InsufficientBalance();

    /// @notice Reverts when the sender does not have enough allowance.
    error InsufficientAllowance();

    /// @dev Details of amount and recipient for airdropped token.
    /// @param recipient The recipient of the tokens.
    /// @param amount The quantity of tokens to airdrop.
    struct AirdropContent {
        address recipient;
        uint256 amount;
    }

    /////////////////////////////////////////////////////////////////
    //                       Public/External                       //
    /////////////////////////////////////////////////////////////////

    /// @notice Allows the user to distribute ERC20 tokens to a list of addresses.
    /// @param tokenAddress The address of the token to be airdropped.
    /// @param tokenOwner The address of the token owner initiating the airdrop.
    /// @param contents A list of recipients and amounts for the airdrop.
    /// @dev needs Approval
    function airdrop(
        address tokenAddress,
        address tokenOwner,
        AirdropContent[] calldata contents
    )
        external
        payable
        nonReentrant
    {
        if (contents.length == 0) {
            revert NoRecipients();
        }

        if (tokenAddress == address(0)) {
            revert TokenAddressZero();
        }

        if (tokenAddress == NATIVE_TOKEN) {
            revert NotERC20();
        }

        uint256 len = contents.length;
        for (uint256 i = 0; i < len;) {
            // Attempt to transfer the specified amount of tokens to the recipient
            bool success =
                _transferCurrencyWithReturnVal(tokenAddress, tokenOwner, contents[i].recipient, contents[i].amount);

            if (!success) {
                // Log the failed transfer
                emit AirdropFailed(tokenAddress, tokenOwner, contents[i].recipient, contents[i].amount);
            }

            // Increment the counter
            unchecked {
                i = i + 1;
            }
        }
    }

    /////////////////////////////////////////////////////////////////
    //                      Private/Internal                       //
    /////////////////////////////////////////////////////////////////

    /// @dev Attempts to transfer the specified currency (either ERC20 or native) from the sender to the recipient.
    /// @param _currency The address of the currency to be transferred.
    /// @param _from The sender's address.
    /// @param _to The recipient's address.
    /// @param _amount The amount to be transferred.
    /// @return success A boolean indicating if the transfer was successful.
    function _transferCurrencyWithReturnVal(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    )
        private
        returns (bool success)
    {
        // If _amount is zero, return true
        if (_amount == 0) {
            success = true;
            return success;
        }

        // Attempt to transfer if the currency is an ERC20 token
        (bool success_, bytes memory data_) = // solhint-disable-next-line avoid-low-level-calls
         _currency.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _amount));

        success = success_;

        // If the transfer failed, check the allowance and balance
        if (!success || (data_.length != 0 && !abi.decode(data_, (bool)))) {
            success = false;

            if (IERC20(_currency).balanceOf(_from) < _amount) {
                revert InsufficientBalance();
            }

            if (IERC20(_currency).allowance(_from, address(this)) < _amount) {
                revert InsufficientAllowance();
            }
        }
    }

    /// @dev Safely transfers ERC20 tokens from the sender to the recipient.
    /// @param _currency The address of the ERC20 token to be transferred.
    /// @param _from The sender's address.
    /// @param _to The recipient's address.
    /// @param _amount The amount to be transferred.
    function _safeTransferERC20(address _currency, address _from, address _to, uint256 _amount) private {
        // if _from is _to, return
        if (_from == _to) {
            return;
        }

        // If _from is the contract, transfer the ERC20 token
        if (_from == address(this)) {
            SafeERC20.safeTransfer(IERC20(_currency), _to, _amount);
        } else {
            // Otherwise, transfer the ERC20 token via the allowance mechanism
            SafeERC20.safeTransferFrom(IERC20(_currency), _from, _to, _amount);
        }
    }
}
