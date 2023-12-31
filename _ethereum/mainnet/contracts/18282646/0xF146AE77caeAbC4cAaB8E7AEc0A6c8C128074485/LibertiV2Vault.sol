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

    error BadReceiver();
    error DefunctVault();
    error InputError();
    error UnknownToken();
    error SanctionedAddress();
    error ZeroValue();
    error FailedTransfer();
    error WrongfulOperation();

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

    struct SwapDescription {
        IERC20Upgradeable srcToken;
        IERC20Upgradeable dstToken;
        address srcReceiver; // from
        address dstReceiver; // to
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    // Immutable list of tokens managed by the vault
    address[] public tokens;

    // Mapping to track whether a token is bound to the vault
    mapping(address => bool) public isBoundTokens;

    // Address of the 1inch Aggregator V5 Router contract
    address private constant AGGREGATION_ROUTER_V5 =
        address(0x1111111254EEB25477B68fb85Ed929f73A960582);

    // Address of the sanctions list contract
    ISanctionsList private constant SANCTIONS_LIST =
        ISanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);

    /**
     * @notice Constructor to initialize the vault contract.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Handle incoming ether.
     */
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
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
        address _owner
    ) external initializer {
        if (_tokens.length != _amountsIn.length) revert InputError();
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_owner);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            tokens.push(token);
            isBoundTokens[token] = true;
            IERC20Upgradeable(token).safeTransferFrom(_owner, address(this), _amountsIn[i]);
        }
        _mint(_owner, 1 ether);
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
            amountsOut[i] = token.balanceOf(address(this)).mulDiv(_amountIn, supply); //  MathUpgradeable.Rounding.Down
        }
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

        // Find the gcd from supplied amounts
        amountOut = type(uint256).max;
        uint256 supply = totalSupply();
        uint256 tokensLength = tokens.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20Upgradeable token = IERC20Upgradeable(tokens[i]);
            uint tokenBalance = token.balanceOf(address(this));
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
            uint tokenBalance = token.balanceOf(address(this));
            if (0 < tokenBalance) {
                amountsIn[i] = tokenBalance.mulDiv(amountOut, supply, MathUpgradeable.Rounding.Up);
                token.safeTransferFrom(_msgSender(), address(this), amountsIn[i]);
            }
        }

        _mint(_receiver, amountOut);
        emit Deposit(_msgSender(), _receiver, amountsIn, amountOut);
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
        if (0 >= _amountIn) revert ZeroValue();
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
     * @notice Rebalances the vault by executing a list of swaps generated off-chain using the 1inch Aggregator V5 protocol.
     *
     * @param _data A list of calldata assembled by the 1inch Aggregation V5 API for performing swaps.
     *
     * @return returnAmounts An array containing the actual amounts returned by each swap in the list.
     *
     * @dev This function allows the owner of the vault to rebalance the assets managed by the vault by executing
     * a list of swaps. The swaps are generated off-chain using the 1inch Aggregator V5 protocol and are provided
     * as `data`. Each swap description in `data` specifies the source token, destination token, and amount to be
     * swapped.
     *
     * The function iterates through the list of swaps, performs each swap, and records the actual amounts returned
     * by the swaps in the `returnAmounts` array.
     *
     * Requirements:
     * - Only the owner of the vault can call this function.
     * - The `data` parameter must contain valid swap descriptions generated using the 1inch Aggregator V5 protocol.
     * - The destination of each swap must be in favor of the vault, and the destination token must be a known token
     *   managed by the vault.
     *
     * Emits a `Rebalance` event for each swap, providing details about the source token, destination token, amount
     * swapped, and the actual amount returned.
     *
     * Example usage:
     * ```
     * bytes[] memory swapData = ...; // Specify the list of swap descriptions generated off-chain.
     * uint256[] memory returnAmounts = myVault.rebalance(swapData);
     * ```
     */
    function rebalance(
        bytes[] calldata _data
    ) external onlyOwner returns (uint256[] memory returnAmounts) {
        returnAmounts = new uint256[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            (, SwapDescription memory desc, ) = abi.decode(
                _data[i][4:],
                (address, SwapDescription, bytes)
            );
            // We don't check source token as long as destination of the swap is in favor of the vault.
            if (desc.dstReceiver != address(this)) revert BadReceiver();
            if (!isBoundTokens[address(desc.dstToken)]) revert UnknownToken();
            desc.srcToken.safeIncreaseAllowance(AGGREGATION_ROUTER_V5, desc.amount);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returndata) = AGGREGATION_ROUTER_V5.call(_data[i]);
            if (!success) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(returndata, 32), mload(returndata))
                }
            }
            (returnAmounts[i], ) = abi.decode(returndata, (uint256, uint256));
            emit Rebalance(
                address(desc.srcToken),
                address(desc.dstToken),
                desc.amount,
                returnAmounts[i]
            );
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
        if (isBoundTokens[_token]) revert WrongfulOperation();
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
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
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
}
