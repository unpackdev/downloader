//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./PythStructs.sol";
import "./PythErrors.sol";

import "./IPythExtended.sol";
import "./ISanctionsList.sol";

/**
 * @title LibertiV2Vault
 * @author The Libertify devs
 *
 * The vault allows depositing, withdrawing, and rebalancing assets.
 */
contract LibertiV2Vault is
    Initializable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct SwapDescription {
        address srcToken;
        address dstToken;
        uint256 amount;
        uint16 slippage;
        address to; // executor, aggregator
    }

    // Immutable list of tokens managed by the vault
    address[] public tokens;

    // Address of the sanctions list contract
    ISanctionsList private constant SANCTIONS_LIST =
        ISanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);

    // Address of the Pyth Network contract
    IPythExtended private immutable PYTH;

    // tokens managed by the vault must have a price feed, otherwise it is considered not managed by that vault: vault cannot be rebalanced to unmanaged token and unmanaged tokens can be rescued by contract owner
    mapping(address => bytes32) public tokenToPriceId;

    // Timestamp in seconds of the last rebalancing
    uint256 public prevRebalancing;

    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256[] amountsIn,
        uint256 amountOut
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 amountIn,
        uint256[] amountsOut
    );

    event Rebalance(address srcToken, address dstToken, uint256 amount, uint256 returnAmounts);

    error CooldownNotRefreshed();
    error DefunctVault();
    error HighSlippage();
    error IllegalOperation();
    error InputError();
    error NullAmount();
    error ReturnNotEnough();
    error SanctionedAddress();
    error FailedTransfer();

    /**
     * @notice Constructor to initialize the vault contract.
     */
    constructor(address _pythContract) {
        _disableInitializers();
        PYTH = IPythExtended(_pythContract);
    }

    /**
     * @notice Initializes a new vault contract.
     *
     * This function is used to set up the initial configuration of a vault contract when it is deployed.
     * It should be called only once during the creation of the contract, and the caller must be the owner
     * of the vault.
     *
     * @param _name The name of the vault. This is a human-readable name for the vault.
     * @param _symbol The symbol of the vault. This is typically a short code representing the vault.
     * @param _tokens An array of addresses representing the tokens that will be managed by the vault.
     * @param _amountsIn An array of initial amounts for each token specified in `_tokens`. The order of
     *                   amounts must correspond to the order of tokens in `_tokens`.
     * @param _owner The address to which ownership of the vault will be transferred. The caller of this
     *               function must be the current owner of the vault.
     *
     * Requirements:
     * - This function can only be called once, during the deployment of the contract.
     * - The caller must be the owner of the contract.
     * - The length of `_tokens` and `_amountsIn` arrays must be the same.
     *
     * Emits a `VaultInitialized` event upon successful initialization.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address[] calldata _tokens,
        uint256[] calldata _amountsIn,
        bytes32[] calldata _pricesId,
        address _owner
    ) external initializer {
        bool hasValue = false;
        if ((_tokens.length != _amountsIn.length) || (_tokens.length != _pricesId.length))
            revert InputError();
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_owner);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            tokens.push(token);
            if (0 < _amountsIn[i]) {
                IERC20Upgradeable(token).safeTransferFrom(_owner, address(this), _amountsIn[i]);
                hasValue = true;
            }
            if (!PYTH.priceFeedExists(_pricesId[i])) revert PythErrors.PriceFeedNotFound();
            tokenToPriceId[token] = _pricesId[i];
        }
        if (!hasValue) revert DefunctVault();
        _mint(_owner, 1 ether);
    }

    /**
     * @notice Deposits assets into the vault contract with specified maximum amounts.
     *
     * @param _maxAmountsIn An array of maximum deposit amounts for each asset.
     * @param _receiver The address that will receive the deposited assets and the corresponding shares.
     *
     * @return amountOut The total number of share tokens minted for the receiver.
     * @return amountsIn An array containing the actual amounts deposited for each asset.
     *
     * @dev This function allows users to deposit assets into the vault, receiving shares in return.
     * Users specify the maximum amounts they are willing to deposit for each asset in the `maxAmountsIn` array.
     * The function calculates the actual amounts to deposit based on the provided maximums and current asset balances.
     * The deposited assets are then distributed to the receiver, and the corresponding share tokens are minted.
     *
     * Requirements:
     * - The sender's address must not be on the sanctions list.
     * - The vault must be initialized (totalSupply() must be greater than zero).
     * - The length of `maxAmountsIn` array must be equal to the number of tokens managed by the vault.
     *
     * Emits a `Deposit` event upon successful deposit.
     *
     * Example usage:
     * ```
     * uint256[] memory maxDepositAmounts = [1000 ether, 2000 ether, ...]; // Specify maximum deposit amounts for each token.
     * address receiver = msg.sender; // Specify the address that will receive the deposited assets and shares.
     * (uint256 amountOut, uint256[] memory amountsIn) = myVault.deposit(maxDepositAmounts, receiver);
     * ```
     */
    function deposit(
        uint256[] calldata _maxAmountsIn,
        address _receiver
    ) external nonReentrant whenNotPaused returns (uint256 amountOut, uint256[] memory amountsIn) {
        if (SANCTIONS_LIST.isSanctioned(_msgSender())) revert SanctionedAddress();
        if (0 >= totalSupply()) revert DefunctVault();

        uint256 tokensLength = tokens.length;
        if (_maxAmountsIn.length != tokensLength) revert InputError();

        // Find the gcd from supplied amounts
        amountOut = type(uint256).max;
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20Upgradeable token = IERC20Upgradeable(tokens[i]);
            uint256 tokenBalance = token.balanceOf(address(this));
            if (0 < tokenBalance) {
                uint256 out = supply.mulDiv(_maxAmountsIn[i], tokenBalance); //  MathUpgradeable.Rounding.Down
                if (out < amountOut) amountOut = out;
            }
        }

        // Vault must have a positive balance for at least one managed asset
        if (amountOut >= type(uint256).max) revert DefunctVault();

        // Deposit all tokens in proportion of the gcd as calculated above
        amountsIn = new uint256[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20Upgradeable token = IERC20Upgradeable(tokens[i]);
            uint256 tokenBalance = token.balanceOf(address(this));
            if (0 < tokenBalance) {
                amountsIn[i] = tokenBalance.mulDiv(amountOut, supply, MathUpgradeable.Rounding.Up);
                token.safeTransferFrom(_msgSender(), address(this), amountsIn[i]);
            }
        }

        _mint(_receiver, amountOut);
        emit Deposit(_msgSender(), _receiver, amountsIn, amountOut);
    }

    /**
     * @notice Helper function to withdraw the balance of LP tokens owned by the sender.
     *
     * @return amountsOut An array containing the actual amounts distributed to the sender.
     *
     * @dev This function allows the sender to conveniently withdraw their entire balance of LP tokens
     * from the vault and receive the underlying assets. It internally calls the `withdraw` function,
     * specifying the sender's balance of share tokens as the `amountIn` and both the sender and receiver
     * as the same address (the sender).
     *
     * Example usage:
     * ```
     * uint256[] memory amountsDistributed = myVault.exit();
     * ```
     *
     * Note: This function assumes that the sender is both the owner of the share tokens and the intended
     * recipient of the withdrawn assets.
     */
    function exit() external returns (uint256[] memory) {
        uint256 amountIn = balanceOf(_msgSender());
        return withdraw(amountIn, _msgSender(), _msgSender());
    }

    /**
     * @notice Revokes a previous EIP-2612 permit by incrementing the nonce of the message sender.
     *
     * @dev This function allows the message sender to revoke a previously granted EIP-2612 permit by simply
     * incrementing their nonce. The nonce is used to uniquely identify permit approvals, and incrementing it
     * invalidates any previous approvals with the same nonce. Revoking a permit prevents the approved spender
     * from using the approval to spend the message sender's tokens.
     *
     * Example usage:
     * ```
     * myVault.revokePermit();
     * ```
     *
     * Requirements:
     * - The function can be called by any address, not limited to the owner.
     */
    function revokePermit() external {
        _useNonce(_msgSender());
    }

    /**
     * @notice Rebalances the vault's assets using off-chain swaps, ensuring values are within a specified tolerance.
     *
     * @param _swapData A list of calldata containing swap information to be executed by various aggregators.
     * @param _updateData Data required to update and confirm the price of assets on Pyth Network.
     *
     * @return returnAmounts An array containing the actual amounts returned by each swap in the list.
     *
     * @dev This function allows the owner of the vault to rebalance the assets managed by the vault using off-chain swaps.
     * The swaps are provided as `_swapData` and executed by various aggregators. It ensures that the value received
     * after each swap is within a specified tolerance, which is hardcoded to 1% (100 basis points).
     *
     * The function enforces the following constraints:
     * - The tokens swapped must have defined price feed IDs, indicating they are managed by the vault.
     * - The cooldown period between rebalances is 3 hours, preventing frequent rebalancing.
     * - The owner can only exploit a maximum of 1% of the vault's value every 3 hours.
     *
     * The `_updateData` parameter is used to update and confirm the prices of the assets on Pyth Network. Both `_swapData`
     * and `_updateData` are fetched off-chain.
     *
     * Requirements:
     * - Only the owner of the vault can call this function.
     * - The cooldown period of 3 hours must have passed since the last rebalance.
     * - The source and destination tokens of the swap must have defined price feed IDs, indicating they are managed by the vault.
     * - The slippage specified in the `SwapDescription` must not exceed 100 basis points (1%).
     * - The value received after each swap must be within the 1% tolerance.
     *
     * Emits a `Rebalance` event for each successful swap, providing details about the source token, destination token,
     * amount swapped, and the actual amount received.
     *
     * Example usage:
     * ```
     * bytes[] memory swapData = ...; // Specify the list of swap descriptions and data.
     * bytes[] memory updateData = ...; // Specify data for updating and confirming asset prices.
     * uint256[] memory returnAmounts = myVault.rebalance{value: feeAmount}(swapData, updateData);
     * ```
     */
    function rebalance(
        bytes[] calldata _swapData,
        bytes[] calldata _updateData
    ) external payable onlyOwner returns (uint256[] memory returnAmounts) {
        if (block.timestamp - prevRebalancing < 3 hours) revert CooldownNotRefreshed();
        prevRebalancing = block.timestamp;
        returnAmounts = new uint256[](_swapData.length);
        uint256 feeAmount = PYTH.getUpdateFee(_updateData);
        PYTH.updatePriceFeeds{value: feeAmount}(_updateData);
        if (msg.value > feeAmount) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(_msgSender()).call{value: msg.value - feeAmount}("");
            if (!success) revert FailedTransfer();
        }
        for (uint256 i = 0; i < _swapData.length; i++) {
            (SwapDescription memory desc, bytes memory data) = abi.decode(
                _swapData[i],
                (SwapDescription, bytes)
            );
            if (desc.slippage > 100) revert HighSlippage();
            uint256 dstBalance = IERC20Upgradeable(desc.dstToken).balanceOf(address(this));
            IERC20Upgradeable(desc.srcToken).safeIncreaseAllowance(desc.to, desc.amount);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = desc.to.call(data);
            if (!success) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(returndata, 32), mload(returndata))
                }
            }
            returnAmounts[i] =
                IERC20Upgradeable(desc.dstToken).balanceOf(address(this)) -
                dstBalance;
            (uint256 srcAmountInUsd, uint256 dstAmountInUsd) = getAmountsInUsd(
                desc,
                returnAmounts[i]
            );
            if (!isWithinTolerance(srcAmountInUsd, dstAmountInUsd, desc.slippage))
                revert ReturnNotEnough();
            emit Rebalance(desc.srcToken, desc.dstToken, desc.amount, returnAmounts[i]);
        }
    }

    /**
     * @notice Rescues ERC-20 tokens sent to the contract address and transfers them to the specified recipient.
     *
     * @dev This function allows the owner of the vault to rescue ERC-20 tokens that may have been mistakenly
     * sent to the vault's address. It transfers the rescued tokens to the specified recipient address.
     * This function cannot be used to withdraw user funds.
     *
     * @param _token The address of the ERC-20 token to be rescued.
     * @param _to The address to which the rescued tokens will be transferred.
     *
     * Requirements:
     * - Only the owner of the vault can call this function.
     * - The specified token must not be a known token managed by the vault (i.e., not in the list of bound tokens).
     */
    function rescueToken(address _token, address _to) external onlyOwner {
        if (PYTH.priceFeedExists(tokenToPriceId[_token])) revert IllegalOperation();
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        token.safeTransfer(_to, token.balanceOf(address(this)));
    }

    /**
     * @notice Rescues Ether sent to the contract address and transfers it to the specified recipient.
     *
     * @param _to The address to which the rescued Ether will be transferred.
     *
     * @dev This function allows the owner of the vault to rescue Ether that may have been mistakenly
     * sent to the vault's address. It transfers the rescued Ether to the specified recipient address.
     *
     * Requirements:
     * - Only the owner of the vault can call this function.
     */
    function rescueEth(address _to) external onlyOwner {
        if (address(0) != _to) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(_to).call{value: address(this).balance}("");
            if (!success) revert FailedTransfer();
        }
    }

    /**
     * @notice Pauses the contract, preventing certain functions from being executed.
     *
     * @dev This function allows the owner of the contract to pause it, effectively preventing the execution
     * of certain functions. When the contract is paused, some critical functions may be disabled to ensure
     * the safety and security of the contract's state. It helps prevent any unintended actions while the
     * contract is in an unstable state.
     *
     * Requirements:
     * - Only the owner of the contract can call this function.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing previously paused functions to be executed.
     *
     * @dev This function allows the owner of the contract to unpause it, enabling the execution of functions
     * that were previously paused. When the contract is unpause, the previously disabled functions become
     * available for use. It is used to restore normal functionality to the contract after it has been paused.
     *
     * Requirements:
     * - Only the owner of the contract can call this function.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Retrieves a list of addresses representing tokens managed by the vault.
     *
     * @return tokens An array containing addresses representing tokens managed by the vault.
     *
     * @dev This function provides read-only access to the list of tokens managed by the vault.
     * It allows users to query the tokens held within the vault without making any state changes.
     * The returned array will contain the addresses of all tokens currently managed by the vault.
     *
     * Example usage:
     * ```
     * address[] memory tokenList = myVault.getTokens();
     * for (uint256 i = 0; i < tokenList.length; i++) {
     *     // Process each token address in the list
     *     address tokenAddress = tokenList[i];
     *     // ... (perform actions on the token address)
     * }
     * ```
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @notice Checks if a token is managed by the vault.
     *
     * @param _token The address of the token to be checked for management by the vault.
     *
     * @return isManaged A boolean indicating whether the specified token is managed by the vault.
     *
     * @dev This function is a helper method that allows external parties to check whether a specific token is managed
     * by the vault. A token is considered managed if it has a defined price feed ID in the `tokenToPriceId` mapping.
     *
     * Example usage:
     * ```
     * address tokenAddress = ...; // Specify the address of the token to check.
     * bool isManaged = myVault.isBoundTokens(tokenAddress);
     * // isManaged will be true if the token is managed by the vault.
     * ```
     */
    function isBoundTokens(address _token) external view returns (bool) {
        return PYTH.priceFeedExists(tokenToPriceId[_token]);
    }

    /**
     * @notice Retrieves the proportional quantities of each asset managed by the vault based on a given quantity of share tokens.
     *
     * @param _amountIn The quantity of share tokens of the vault for which you want to calculate proportional asset amounts.
     *
     * @return amountsOut An array of uint256 values representing the quantity of each asset managed by the vault in proportion to
     *                    the `amountIn` and the total number of shares.
     *
     * @dev This function allows users to calculate the proportional quantities of assets held by the vault
     * based on a specified quantity of share tokens. The result is an array of uint256 values, where each
     * value represents the quantity of a specific asset held by the vault in proportion to the total number
     * of shares and the `amountIn` parameter.
     *
     * Example usage:
     * ```
     * uint256[] memory assetQuantities = myVault.getAmountsOut(amountOfShares);
     * for (uint256 i = 0; i < assetQuantities.length; i++) {
     *     // Process each asset quantity in the list
     *     uint256 assetQuantity = assetQuantities[i];
     *     // ... (perform actions with the asset quantity)
     * }
     * ```
     *
     * Requirements:
     * - The `amountIn` parameter must be greater than or equal to zero.
     * - The vault must have a non-zero total supply of shares.
     * - The length of the `amountsOut` array will be equal to the number of tokens managed by the vault.
     */
    function getAmountsOut(uint256 _amountIn) external view returns (uint256[] memory amountsOut) {
        uint256 tokensLength = tokens.length;
        amountsOut = new uint256[](tokensLength);
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20Upgradeable token = IERC20Upgradeable(tokens[i]);
            amountsOut[i] = 0 < _amountIn
                ? token.balanceOf(address(this)).mulDiv(_amountIn, supply) //  MathUpgradeable.Rounding.Down
                : 0;
        }
    }

    /**
     * @notice Withdraws assets from the vault and distributes them to specified recipients.
     *
     * @param _amountIn The number of share tokens to be withdrawn.
     * @param _receiver The address that will receive the withdrawn assets.
     * @param _owner The owner's address who initiates the withdrawal.
     *
     * @return amountsOut An array containing the actual amounts distributed to each recipient.
     *
     * @dev This function allows the owner of share tokens to withdraw assets from the vault and distribute
     * them to specified recipients. The owner must specify the `amountIn` of share tokens to be withdrawn,
     * and the assets will be distributed to the specified `receiver` address.
     *
     * If the sender is not the owner of the share tokens, they must have an allowance to spend the owner's
     * tokens on their behalf. The function calculates the actual amounts to distribute based on the share
     * tokens provided.
     *
     * Requirements:
     * - The `amountIn` parameter must be greater than zero.
     * - If the sender is not the owner of the share tokens, they must have an allowance to spend on behalf of
     *   the owner.
     * - The length of the `amountsOut` array will be equal to the number of tokens managed by the vault.
     *
     * Emits a `Withdraw` event upon successful withdrawal and distribution.
     *
     * Example usage:
     * ```
     * uint256 amountToWithdraw = 1000; // Specify the number of share tokens to withdraw.
     * address receiver = msg.sender; // Specify the address that will receive the withdrawn assets.
     * address owner = ...; // Specify the owner's address who initiates the withdrawal.
     * uint256[] memory amountsDistributed = myVault.withdraw(amountToWithdraw, receiver, owner);
     * ```
     */
    function withdraw(
        uint256 _amountIn,
        address _receiver,
        address _owner
    ) public nonReentrant returns (uint256[] memory amountsOut) {
        amountsOut = new uint256[](tokens.length);
        if (0 >= _amountIn) revert NullAmount();
        if (_msgSender() != _owner) _spendAllowance(_owner, _msgSender(), _amountIn);
        uint256 supply = totalSupply();
        _burn(_owner, _amountIn);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20Upgradeable token = IERC20Upgradeable(tokens[i]);
            uint256 tokenBalance = token.balanceOf(address(this));
            if (0 < tokenBalance) {
                uint256 amount = tokenBalance.mulDiv(_amountIn, supply); // MathUpgradeable.Rounding.Down
                token.safeTransfer(_receiver, amount);
                amountsOut[i] += amount;
            }
        }
        emit Withdraw(_msgSender(), _receiver, _owner, _amountIn, amountsOut);
    }

    /**
     * @notice Checks if two values are within a specified tolerance in basis points.
     *
     * @param _a The first value for comparison.
     * @param _b The second value for comparison.
     * @param _tolerance The tolerance in basis points (1 basis point = 0.01%).
     *
     * @return withinTolerance A boolean indicating whether the two values are within the specified tolerance.
     *
     * @dev This function allows you to check if two values are within a specified tolerance in basis points.
     * The tolerance is defined as the maximum allowed difference as a percentage of the larger of the two values.
     * If the difference between the two values is less than or equal to the allowed tolerance, the function returns true.
     *
     * Example usage:
     * ```
     * uint256 value1 = 100000;  // First value
     * uint256 value2 = 101000;  // Second value
     * uint256 tolerance = 100; // Tolerance of 1% (100 basis points)
     * bool withinTolerance = isWithinTolerance(value1, value2, tolerance);
     * // withinTolerance will be true since the difference is within the 1% tolerance.
     * ```
     */
    function isWithinTolerance(
        uint256 _a,
        uint256 _b,
        uint256 _tolerance
    ) public pure returns (bool) {
        uint256 maxDifference = (_tolerance * MathUpgradeable.max(_a, _b)) / 10000;
        if (_a >= _b) return _a - _b <= maxDifference;
        return _b - _a <= maxDifference;
    }

    /**
     * @notice Sanctioned addresses cannot deposit into a vault. Additionally, LP tokens
     * of the vault must not be transferred to a sanctioned address.
     *
     * @param {_from} The address from which tokens are being transferred.
     * @param _to The address to which tokens are being transferred.
     * @param {_amount} The amount of tokens being transferred.
     *
     * @dev This internal function is called before any token transfer within the vault. It ensures that
     * sanctioned addresses are not allowed to deposit into the vault, and it prevents LP tokens of the
     * vault from being transferred to sanctioned addresses.
     *
     * Requirements:
     * - The `to` address must not be a sanctioned address.
     */
    function _beforeTokenTransfer(address, address _to, uint256) internal view override {
        if (SANCTIONS_LIST.isSanctioned(_to)) revert SanctionedAddress();
    }

    /**
     * @notice Calculates the value in USD of the amount of the output token and the amount of the input token
     *         returned by a swap using Pyth Network oracles.
     *
     * @param _desc A struct containing swap description, including source and destination tokens.
     * @param _amountIn The amount of the input token to be swapped.
     *
     * @return srcAmountInUsd The value in USD of the source token amount before the swap.
     * @return dstAmountInUsd The value in USD of the destination token amount after the swap.
     *
     * @dev This private function is used to calculate the value in USD of the amount of the output token and the
     * amount of the input token returned by a swap. It relies on Pyth Network oracles to obtain price information.
     *
     * The function checks if the source and destination tokens have defined price feed IDs. If either of them
     * has an undefined price feed ID, it reverts with a `PriceFeedNotFound` error.
     *
     * The function fetches the prices of the source and destination tokens from Pyth Network and adjusts them
     * based on the token decimals to calculate the USD values of the tokens before and after the swap.
     *
     * Requirements:
     * - The source and destination tokens must have defined price feed IDs in the `tokenToPriceId` mapping.
     * - The source token's and destination token's decimals must be available through the
     *   `IERC20MetadataUpgradeable` interface.
     * - The `_desc.amount` must be the amount of the source token before the swap.
     */
    function getAmountsInUsd(
        SwapDescription memory _desc,
        uint256 _amountIn
    ) private view returns (uint256 srcAmountInUsd, uint256 dstAmountInUsd) {
        if (
            !PYTH.priceFeedExists(tokenToPriceId[_desc.srcToken]) ||
            !PYTH.priceFeedExists(tokenToPriceId[_desc.dstToken])
        ) revert PythErrors.PriceFeedNotFound();
        PythStructs.Price memory srcPrice = PYTH.getPrice(tokenToPriceId[_desc.srcToken]);
        PythStructs.Price memory dstPrice = PYTH.getPrice(tokenToPriceId[_desc.dstToken]);
        uint8 srcDecimals = IERC20MetadataUpgradeable(_desc.srcToken).decimals();
        uint8 dstDecimals = IERC20MetadataUpgradeable(_desc.dstToken).decimals();
        if (srcDecimals > dstDecimals) {
            srcAmountInUsd =
                (_desc.amount * SafeCastUpgradeable.toUint256(srcPrice.price)) /
                10 ** (srcDecimals - dstDecimals);
            dstAmountInUsd = _amountIn * SafeCastUpgradeable.toUint256(dstPrice.price);
        } else {
            srcAmountInUsd = _desc.amount * SafeCastUpgradeable.toUint256(srcPrice.price);
            dstAmountInUsd =
                (_amountIn * SafeCastUpgradeable.toUint256(dstPrice.price)) /
                (10 ** (dstDecimals - srcDecimals));
        }
    }
}
