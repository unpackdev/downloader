// SPDX-License-Identifier: MIT

/// @title OMNI Token V4 / Ethereum v1
/// @author Alfredo Lopez / Arthur Miranda / OMNI App 2021.10 */

pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./CirculatingSupply.sol";

/**
 * @title Claimable Methods
 * @dev Implementation of the claiming utils that can be useful for withdrawing
 * @dev accidentally sent tokens that are not used in bridge operations.
 */
contract Claimable is OwnableUpgradeable, CirculatingSupply {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;
	// Event when the Smart Contract receive Amount of Native or ERC20 tokens
	event ValueReceived(address indexed sender, uint256 indexed value);

	/// @notice Handle receive ether
	receive() external payable
	{
		emit ValueReceived(_msgSender(), msg.value);
	}

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to) public validAddress(_to) notBlacklisted(_to) onlyOwner() {
        if (_token == address(0)) {
            _claimNativeCoins(_to);
        } else {
            _claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function _claimNativeCoins(address _to) private {
        uint256 amount = address(this).balance;

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = _to.call{ value: amount }("");
        require(success, "ERC20: Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function _claimErc20Tokens(address _token, address _to) private {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }
}
