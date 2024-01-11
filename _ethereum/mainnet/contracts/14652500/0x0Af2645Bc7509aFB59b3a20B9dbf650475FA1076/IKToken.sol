// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IScaledBalanceToken.sol";
import "./IInitializableKToken.sol";

interface IKToken is IERC20Upgradeable, IScaledBalanceToken, IInitializableKToken {
	
    /**
    * @dev Emitted after the mint action
    * @param from The address performing the mint
    * @param value The amount being
    * @param index The new liquidity index of the reserve
    **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
    * @dev Mints `amount` kTokens to `user`
    * @param user The address receiving the minted tokens
    * @param amount The amount of tokens getting minted
    * @param index The new liquidity index of the reserve
    * @return `true` if the the previous balance of the user was 0
    */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
    * @dev Emitted after kTokens are burned
    * @param from The owner of the kTokens, getting them burned
    * @param target The address that will receive the underlying
    * @param value The amount being burned
    * @param index The new liquidity index of the reserve
    **/
    event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

    /**
    * @dev Emitted during the transfer action
    * @param from The user whose tokens are being transferred
    * @param to The recipient
    * @param value The amount being transferred
    * @param index The new liquidity index of the reserve
    **/
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
    * @dev Burns kTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
    * @param user The owner of the kTokens, getting them burned
    * @param receiverOfUnderlying The address that will receive the underlying
    * @param amount The amount being burned
    * @param index The new liquidity index of the reserve
    **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
    * @dev Mints kTokens to the reserve treasury
    * @param amount The amount of tokens getting minted
    * @param index The new liquidity index of the reserve
    */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
    * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
    * assets in borrow(), withdraw() and flashLoan()
    * @param user The recipient of the underlying
    * @param amount The amount getting transferred
    * @return The amount transferred
    **/
    function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

    /**
    * @dev Invoked to execute actions on the kToken side after a repayment.
    * @param user The user executing the repayment
    * @param amount The amount getting repaid
    **/
    function handleRepayment(address user, uint256 amount) external;

    /**
    * @dev Returns the address of the underlying asset of this kToken (E.g. USDT for kUSDT)
    **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}