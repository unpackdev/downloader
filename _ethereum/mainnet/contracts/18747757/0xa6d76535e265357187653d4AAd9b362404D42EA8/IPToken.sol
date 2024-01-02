// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IERC20Upgradeable.sol";
import "./IAccessControl.sol";
import "./IERC165Upgradeable.sol";

import "./IPTokenStorage.sol";

interface IPToken is IPTokenStorage {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     */
    event Mint(address indexed from, uint256 value);

    /**
     * @dev Emitted after pTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param value The amount being burned
     */
    event Burn(address indexed from, uint256 value);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param amount The amount being transferred
     * @param index The new liquidity index of the reserve
     */
    event BalanceTransfer(address indexed from, address indexed to, uint256 amount, uint256 index);

    event LockDeposit(address indexed user, uint256 indexed id, uint256 deadline, uint256 amount);
    event UnlockDeposit(address indexed user, uint256 indexed id);

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
     * @dev Sets the InterestIncreaser for current PToken.
     * @param _interestIncreaser The interest increaser address.
     */
    function setInterestIncreaser(IFeeExecutor _interestIncreaser) external;

    /**
     * @dev Sets the lender reward distributor contract address.
     * @param _lenderRewardDistributor The address of the lender reward distributor contract.
     */
    function setLenderRewardDistributor(IActivityRewardDistributor _lenderRewardDistributor) external;

    /**
     * @notice Locks a deposit for a specified user.
     * @param _user The address of the user for whom the deposit is being locked.
     * @param _amount The amount to be locked as a deposit.
     * @param _duration The duration for which the deposit will be locked.
     * @dev This function can only be called externally and overrides the corresponding function in the parent contract.
     * @dev The user must not be blacklisted.
     */
    function lockDeposit(address _user, uint256 _amount, uint256 _duration) external;

    /**
     * @dev Unlocks a specific deposit.
     * @param _depositId The ID of the deposit to be unlocked.
     */
    function unlockDeposit(uint256 _depositId) external;

    /**
     * @dev Mints `amount` pTokens to `user`
     * @param _user The address receiving the minted tokens
     * @param _amount The amount of tokens getting minted
     * @param _index The current liquidityIndex
     * @return Minted amount of PTokens
     */
    function mint(address _user, uint256 _amount, uint256 _index) external returns (uint256);

    /**
     * @dev Mints pTokens to the reserve address
     * Compared to the normal mint, we don't revert when the amountScaled is equal to the zero. Additional checks were also removed
     * Only callable by the Bucket
     * @param _reserve The address of the reserve
     * @param _amount The amount of tokens getting minted
     * @param _index The current liquidityIndex
     */
    function mintToReserve(address _reserve, uint256 _amount, uint256 _index) external;

    /**
     * @dev Burns pTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param _user The owner of the pTokens, getting them burned
     * @param _amount The amount of underlying token being returned to receiver
     * @param _index The current liquidityIndex
     * @return Burned amount of PTokens
     */
    function burn(address _user, uint256 _amount, uint256 _index) external returns (uint256);

    /**
     * @dev Returns the scaled balance of the user.
     * @param _user The owner of pToken
     * @return The scaled balances of the user
     */
    function scaledBalanceOf(address _user) external view returns (uint256);

    /**
     * @dev Returns available balance of the user.
     * @param _user The owner of pToken
     * @return The available balance of the user
     */
    function availableBalanceOf(address _user) external view returns (uint256);

    /**
     * @dev Returns locked deposits and balance of user
     * @param _user The owner of locked deposits
     * @return Structure with deposits and total locked balance of user
     */
    function getUserLockedBalance(address _user) external view returns (LockedBalance memory);

    /**
     * @dev Returns the scaled total supply of pToken.
     * @return The scaled total supply of the pToken.
     */
    function scaledTotalSupply() external view returns (uint256);

    /**
     * @dev Function to get a deposit index in user's deposit array.
     * @param id Deposit id.
     * @return index Deposit index in user's 'deposit' array.
     */
    function getDepositIndexById(uint256 id) external returns (uint256 index);
}
