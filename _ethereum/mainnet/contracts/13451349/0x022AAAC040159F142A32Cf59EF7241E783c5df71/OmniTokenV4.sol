// SPDX-License-Identifier: ISC

/// @title OMNI Token V4 / Ethereum v1
/// @author Alfredo Lopez / Arthur Miranda / OMNI App 2021.10 */

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Claimable.sol";
import "./Math.sol";


contract OmniTokenV4 is Initializable, Math, Claimable, PausableUpgradeable, ERC20PermitUpgradeable {
	using AddressUpgradeable for address;
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;
	// Constant Max Total Supply of OMNI Social Media Network
 	uint256 private constant _maxTotalSupply = 638_888_889 * (uint256(10) ** uint256(18));

	function initialize() initializer() public {
		__Ownable_init();
		__ERC20_init_unchained('OMNI Token', 'OAI');
		__Pausable_init_unchained();
		__ERC20Permit_init('OMNI Token');

		// Mint Total Supply
		mint(getMaxTotalSupply());

	}

	/**
     * @dev This Method permit getting Maximun total Supply .
     * See {ERC20-_burn}.
     */
	function getMaxTotalSupply() public pure returns (uint256) {
		return _maxTotalSupply;
	}

	/**
     * @dev Implementation / Instance of TransferMany of Parsiq Token.
	 * @dev This method permitr to habdle AirDrop process with a reduce cost of gas in at least 30%
     * @param recipients Array of Address to receive the Tokens in AirDrop process
	 * @param amounts Array of Amounts of token to receive
     * See {https://github.com/parsiq/parsiq-bsc-token/blob/main/contracts/ParsiqToken.sol}.
     */

	function transferMany(address[] calldata recipients, uint256[] calldata amounts)
        external
	    onlyOwner()
		whenNotPaused()
    {
        require(recipients.length == amounts.length, "ERC20 OMN: Wrong array length");

        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
			address recipient = recipients[i];
			require(recipient != address(0), "ERC20: transfer to the zero address");
			require(!isBlacklisted(recipient), "ERC20 OMN: recipient account is blacklisted");
			require(amounts[i] != 0, "ERC20 OMN: total amount token is zero");
            total = total.add(amounts[i]);
        }

	    _balances[msg.sender] = _balances[msg.sender].sub(total, "ERC20: transfer amount exceeds balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(msg.sender, recipient, amount);
        }
    }

	/**
     * @dev Circulating Supply Method for Calculated based on Wallets of OMNI Foundation
     */
	function circulatingSupply() public view returns (uint256 result) {
		uint256 index = omni_wallets.length;
		result = totalSupply().sub(balanceOf(owner()));
		for (uint256 i=0; i < index ; i++ ) {
			if ((omni_wallets[i] != address(0)) && (result != 0)) {
				result -= balanceOf(omni_wallets[i]);
			}
		}
	}

	/**
     * @dev Method to permit to get the Exactly Unix Epoch of Token Generate Event
     */
	function getReleaseTime() public pure returns (uint256) {
        return 1626440400; // "Friday, 16 July 2021 13:00:00 GMT"
    }

    /**
     * @dev Auxiliary Method to permit to get the Last Exactly Unix Epoch of Blockchain timestamp
     */
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

	/**
     * @dev Implementation / Instance of paused methods() in the ERC20.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC20Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

	/**
     * @dev Destroys `amount` tokens from the caller.
     * @param amount Amount token to burn
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }


	/**
     * @dev Override the Hook of Open Zeppelin for checking before execute the method transfer/transferFrom/mint/burn.
	 * @param sender Addres of Sender of the token
	 * @param recipient Address of Receptor of the token
     * @param amount Amount token to transfer/transferFrom/mint/burn
     * See {ERC20 Upgradeable}.
     */
	function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual override notBlacklisted(sender) {
		require(!isBlacklisted(recipient), "ERC20 OMN: recipient account is blacklisted");
		// Permit the Owner execute token transfer/mint/burn while paused contract
		if (_msgSender() != owner()) {
			require(!paused(), "ERC20 OMN: token transfer/mint/burn while paused");
		}
        super._beforeTokenTransfer(sender, recipient, amount);
    }

	/**
     * @dev Creates `amount` new tokens for `to`.
	 * @param _amount Amount Token to mint
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `OWNER`.
		 * - After upgrade the SmartContract and Eliminate this method
     */
    function mint( uint256 _amount) public onlyOwner() {
		require(getMaxTotalSupply() >= totalSupply().add(_amount), "ERC20: Can't Mint, it exceeds the maximum supply ");
        _mint(owner(), _amount);
    }
}
