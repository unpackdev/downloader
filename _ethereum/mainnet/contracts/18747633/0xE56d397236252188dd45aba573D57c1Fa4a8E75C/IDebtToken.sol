// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IAccessControl.sol";
import "./IERC165Upgradeable.sol";

import "./IDebtTokenStorage.sol";

interface IDebtToken is IDebtTokenStorage {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     **/
    event Mint(address indexed from, uint256 value);

    /**
     * @dev Emitted after DebtTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param value The amount being burned
     **/
    event Burn(address indexed from, uint256 value);

    /**
     * @dev contract initializer
     * @param _name The name of the ERC20 token.
     * @param _symbol The symbol of the ERC20 token.
     * @param _decimals The number of decimals for the ERC20 token.
     * @param _bucketsFactory Address of the buckets factory that will call the setBucket fucntion
     */
    function initialize(string memory _name, string memory _symbol, uint8 _decimals, address _bucketsFactory) external;

    /**
     * @dev Sets the bucket for the contract.
     * @param _bucket The address of the bucket to set.
     */
    function setBucket(IBucket _bucket) external;

    /**
     * @dev Sets the FeeDecreaser for current DebtToken.
     * @param _feeDecreaser The interest increaser address.
     */
    function setFeeDecreaser(IFeeExecutor _feeDecreaser) external;

    /**
     * @dev Sets the trader reward distributor contract address.
     * @param _traderRewardDistributor The address of the trader reward distributor contract.
     * Only the BIG_TIMELOCK_ADMIN role can call this function.
     */
    function setTraderRewardDistributor(IActivityRewardDistributor _traderRewardDistributor) external;

    /**
     * @dev Mints `amount` DebtTokens to `user`
     * @param _user The address receiving the minted tokens
     * @param _amount The amount of tokens getting minted
     * @param _index The current variableBorrowIndex
     */
    function mint(address _user, uint256 _amount, uint256 _index) external;

    /**
     * @dev Burns DebtTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param _user The owner of the DebtTokens, getting them burned
     * @param _amount The amount being burned
     * @param _index The current variableBorrowIndex
     **/
    function burn(address _user, uint256 _amount, uint256 _index) external;

    /**
     * @dev Burns a batch of tokens from multiple users.
     * @param _users An array of user addresses whose tokens will be burned.
     * @param _amounts An array of token amounts to be burned for each user.
     * @param _index The index used to calculate the scaled amounts.
     * @param _length The length of the user and amounts arrays.
     */
    function batchBurn(address[] memory _users, uint256[] memory _amounts, uint256 _index, uint256 _length) external;

    /**
     * @dev Returns the principal debt balance of the user
     * @param _user The address of the user.
     * @return The scaled balance of the user.
     */
    function scaledBalanceOf(address _user) external view returns (uint256);

    /**
     * @dev Returns the scaled total supply of debtToken.
     * @return The scaled total supply of the debtToken.
     */
    function scaledTotalSupply() external view returns (uint256);
}
