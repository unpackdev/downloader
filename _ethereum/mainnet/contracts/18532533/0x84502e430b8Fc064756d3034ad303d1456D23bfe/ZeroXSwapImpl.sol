// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/**
 * @title ISocketGateway
 * @notice Interface for SocketGateway functions.
 * @dev functions can be added here for invocation from external contracts or off-chain
 * @author Socket dot tech.
 */
interface ISocketGateway {
    /**
     * @notice Request-struct for controllerRequests
     * @dev ensure the value for data is generated using the function-selectors defined in the controllerImplementation contracts
     */
    struct SocketControllerRequest {
        // controllerId is the id mapped to the controllerAddress
        uint32 controllerId;
        // transactionImplData generated off-chain or by caller using function-selector of the controllerContract
        bytes data;
    }

    // @notice view to get owner-address
    function owner() external view returns (address);
}

error CelerRefundNotReady();
error OnlySocketDeployer();
error OnlySocketGatewayOwner();
error OnlySocketGateway();
error OnlyOwner();
error OnlyNominee();
error TransferIdExists();
error TransferIdDoesnotExist();
error Address0Provided();
error SwapFailed();
error UnsupportedInterfaceId();
error InvalidCelerRefund();
error CelerAlreadyRefunded();
error IncorrectBridgeRatios();
error ZeroAddressNotAllowed();
error ArrayLengthMismatch();
error PartialSwapsNotAllowed();

/**
 * @title Abstract Implementation Contract.
 * @notice All Swap Implementation will follow this interface.
 * @author Socket dot tech.
 */
abstract contract SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketDeployFactory;

    /// @notice FunctionSelector used to delegatecall to the performAction function of swap-router-implementation
    bytes4 public immutable SWAP_FUNCTION_SELECTOR =
        bytes4(
            keccak256("performAction(address,address,uint256,address,bytes)")
        );

    /// @notice FunctionSelector used to delegatecall to the performActionWithIn function of swap-router-implementation
    bytes4 public immutable SWAP_WITHIN_FUNCTION_SELECTOR =
        bytes4(keccak256("performActionWithIn(address,address,uint256,bytes)"));

    /****************************************
     *               EVENTS                 *
     ****************************************/

    event SocketSwapTokens(
        address fromToken,
        address toToken,
        uint256 buyAmount,
        uint256 sellAmount,
        bytes32 routeName,
        address receiver,
        bytes32 metadata
    );

    /**
     * @notice Construct the base for all SwapImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     */
    constructor(address _socketGateway, address _socketDeployFactory) {
        socketGateway = _socketGateway;
        socketDeployFactory = _socketDeployFactory;
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketDeployFactory() {
        if (msg.sender != socketDeployFactory) {
            revert OnlySocketDeployer();
        }
        _;
    }

    /****************************************
     *    RESTRICTED FUNCTIONS              *
     ****************************************/

    /**
     * @notice function to rescue the ERC20 tokens in the Swap-Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the  Swap-Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    function killme() external isSocketDeployFactory {
        selfdestruct(payable(msg.sender));
    }

    /******************************
     *    VIRTUAL FUNCTIONS       *
     *****************************/

    /**
     * @notice function to swap tokens on the chain
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param  toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param receiverAddress recipient address of toToken
     * @param data encoded value of properties in the swapData Struct
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes32 metadata,
        bytes memory data
    ) external payable virtual returns (uint256);

    /**
     * @notice function to swapWith - swaps tokens on the chain to socketGateway as recipient
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes32 metadata,
        bytes memory swapExtraData
    ) external payable virtual returns (uint256, address);
}

bytes32 constant ACROSS = keccak256("Across");

bytes32 constant ANYSWAP = keccak256("Anyswap");

bytes32 constant CBRIDGE = keccak256("CBridge");

bytes32 constant HOP = keccak256("Hop");

bytes32 constant HYPHEN = keccak256("Hyphen");

bytes32 constant NATIVE_OPTIMISM = keccak256("NativeOptimism");

bytes32 constant NATIVE_ARBITRUM = keccak256("NativeArbitrum");

bytes32 constant NATIVE_POLYGON = keccak256("NativePolygon");

bytes32 constant REFUEL = keccak256("Refuel");

bytes32 constant STARGATE = keccak256("Stargate");

bytes32 constant ONEINCH = keccak256("OneInch");

bytes32 constant ZEROX = keccak256("Zerox");

bytes32 constant RAINBOW = keccak256("Rainbow");

bytes32 constant CCTP = keccak256("cctp");

bytes32 constant CONNEXT = keccak256("Connext");

bytes32 constant SYNAPSE = keccak256("Synapse");

bytes32 constant ZKSYNC = keccak256("ZkSync");

bytes32 constant SYMBIOSIS = keccak256("Symbiosis");

/**
 * @title ZeroX-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via ZeroX-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of ZeroX-Swap-Implementation
 * @author Socket dot tech.
 */
contract ZeroXSwapImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable ZeroXIdentifier = ZEROX;

    /// @notice unique name to identify the router, used to emit event upon successful bridging
    bytes32 public immutable NAME = keccak256("Zerox-Router");

    /// @notice address of ZeroX-Exchange-Proxy to swap the tokens on Chain
    address payable public immutable zeroXExchangeProxy;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @notice ZeroXExchangeProxy contract is payable to allow ethereum swaps
    /// @dev ensure _zeroXExchangeProxy are set properly for the chainId in which the contract is being deployed
    constructor(
        address _zeroXExchangeProxy,
        address _socketGateway,
        address _socketDeployFactory
    ) SwapImplBase(_socketGateway, _socketDeployFactory) {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     * @dev This is called only when there is a request for a swap.
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken is to be swapped
     * @param amount amount to be swapped
     * @param receiverAddress address of toToken recipient
     * @param swapExtraData data required for zeroX Exchange to get the swap done
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes32 metadata,
        bytes calldata swapExtraData
    ) external payable override returns (uint256) {
        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        uint256 _initialBalanceTokenIn;
        uint256 _finalBalanceTokenIn;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20(fromToken).safeTransferFrom(
                msg.sender,
                socketGateway,
                amount
            );
            ERC20(fromToken).safeApprove(zeroXExchangeProxy, amount);
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = ERC20(toToken).balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenIn = ERC20(fromToken).balanceOf(socketGateway);
        } else {
            _initialBalanceTokenIn = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapExtraData);

            if (!success) {
                revert SwapFailed();
            }
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapExtraData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenIn = ERC20(fromToken).balanceOf(socketGateway);
        } else {
            _finalBalanceTokenIn = address(this).balance;
        }
        if (_finalBalanceTokenIn > _initialBalanceTokenIn - amount)
            revert PartialSwapsNotAllowed();

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = ERC20(toToken).balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toToken == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            ERC20(toToken).transfer(receiverAddress, returnAmount);
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            ZeroXIdentifier,
            receiverAddress,
            metadata
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes32 metadata,
        bytes calldata swapExtraData
    ) external payable override returns (uint256, address) {
        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        uint256 _initialBalanceTokenIn;
        uint256 _finalBalanceTokenIn;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            ERC20(fromToken).safeApprove(zeroXExchangeProxy, amount);
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = ERC20(toToken).balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenIn = ERC20(fromToken).balanceOf(socketGateway);
        } else {
            _initialBalanceTokenIn = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapExtraData);

            if (!success) {
                revert SwapFailed();
            }
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapExtraData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenIn = ERC20(fromToken).balanceOf(socketGateway);
        } else {
            _finalBalanceTokenIn = address(this).balance;
        }
        if (_finalBalanceTokenIn > _initialBalanceTokenIn - amount)
            revert PartialSwapsNotAllowed();

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = ERC20(toToken).balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            _finalBalanceTokenOut - _initialBalanceTokenOut,
            amount,
            ZeroXIdentifier,
            socketGateway,
            metadata
        );

        return (_finalBalanceTokenOut - _initialBalanceTokenOut, toToken);
    }
}