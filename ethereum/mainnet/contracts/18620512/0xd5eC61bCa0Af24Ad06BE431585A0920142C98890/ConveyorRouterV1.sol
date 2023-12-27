// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.21;

import "./ConveyorErrors.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ConveyorMath.sol";
import "./ConveyorSwapCallbacks.sol";
import "./IConveyorRouterV1.sol";

interface IConveyorMulticall {
    function executeMulticall(
        ConveyorRouterV1.SwapAggregatorMulticall calldata multicall
    ) external;
}

/// @title ConveyorRouterV1
/// @author 0xKitsune, 0xOsiris, Conveyor Labs
/// @notice Multicall contract for token Swaps.
contract ConveyorRouterV1 is IConveyorRouterV1 {
    using SafeERC20 for IERC20;

    address public CONVEYOR_MULTICALL;
    address public immutable WETH;

    address owner;
    address tempOwner;

    uint128 private constant AFFILIATE_PERCENT = 5534023222112865000;
    uint128 private constant REFERRAL_PERCENT = 5534023222112865000;

    /**
     * @notice Event that is emitted when ETH is withdrawn from the contract
     *
     */
    event Withdraw(address indexed receiver, uint256 amount);

    ///@notice Modifier function to only allow the owner of the contract to call specific functions
    ///@dev Functions with onlyOwner: withdraw
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert MsgSenderIsNotOwner();
        }

        _;
    }

    ///@notice Mapping from uint16 to affiliate address.
    mapping(uint16 => address) public affiliates;
    ///@notice Mapping from uint16 to referrer address.
    mapping(uint16 => address) public referrers;

    ///@notice Mapping from affiliate address to affiliate index.
    mapping(address => uint16) public affiliateIndex;
    ///@notice Mapping from referrer address to referrer index.
    mapping(address => uint16) public referrerIndex;

    ///@notice Current Nonce for affiliate addresses.
    uint16 public affiliateNonce;
    ///@notice Current Nonce for referrer addresses.
    uint16 public referrerNonce;

    ///@dev Deploys the ConveyorMulticall contract.
    ///@param _weth Address of Wrapped Native Asset.
    constructor(address _weth) payable {
        require(_weth != address(0), "WETH address is zero");
        CONVEYOR_MULTICALL = address(new ConveyorMulticall());
        WETH = _weth;
        owner = tx.origin;
    }

    ///@notice Struct for token to token swap data.
    struct TokenToTokenSwapData {
        address tokenIn;
        address tokenOut;
        uint112 amountIn;
        uint112 amountOutMin;
        uint16 affiliate;
        uint16 referrer;
    }

    ///@notice Struct for token to ETH swap data.
    struct TokenToEthSwapData {
        address tokenIn;
        uint112 amountIn;
        uint112 amountOutMin;
        uint16 affiliate;
        uint16 referrer;
    }

    ///@notice Struct for ETH to token swap data.
    struct EthToTokenSwapData {
        address tokenOut;
        uint112 amountOutMin;
        uint112 protocolFee;
        uint16 affiliate;
        uint16 referrer;
    }

    /// @notice Gas optimized Multicall struct
    struct SwapAggregatorMulticall {
        address tokenInDestination;
        Call[] calls;
    }

    /// @notice Call struct for token Swaps.
    /// @param target Address to call.
    /// @param callData Data to call.
    struct Call {
        address target;
        bytes callData;
    }

    /// @notice Swap tokens for tokens.
    /// @param swapData The swap data for the transaction.
    /// @param genericMulticall Multicall to be executed.
    function swapExactTokenForToken(
        TokenToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata genericMulticall
    ) public payable {
        ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
        IERC20(swapData.tokenIn).safeTransferFrom(
            msg.sender,
            genericMulticall.tokenInDestination,
            swapData.amountIn
        );

        ///@notice Get tokenOut balance of msg.sender.
        uint256 balanceBefore = IERC20(swapData.tokenOut).balanceOf(msg.sender);
        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = balanceBefore + swapData.amountOutMin;

        ///@notice Execute Multicall.
        IConveyorMulticall(CONVEYOR_MULTICALL).executeMulticall(
            genericMulticall
        );

        uint256 balanceAfter = IERC20(swapData.tokenOut).balanceOf(msg.sender);
        ///@notice Check if tokenOut balance of msg.sender is sufficient.
        if (balanceAfter < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - balanceAfter,
                swapData.amountOutMin
            );
        }
        if (swapData.affiliate & 0xFFFF != 0x0) {
            address affiliate = affiliates[swapData.affiliate >> 0x1];
            if (affiliate == address(0)) {
                revert AffiliateDoesNotExist();
            }
            _safeTransferETH(
                affiliate,
                ConveyorMath.mul64U(AFFILIATE_PERCENT, msg.value)
            );
        }
        ///@dev First bit of referrer is used to check if referrer exists
        if (swapData.referrer & 0xFFFF != 0x0) {
            address referrer = referrers[swapData.referrer >> 0x1];
            if (referrer == address(0)) {
                revert ReferrerDoesNotExist();
            }
            _safeTransferETH(
                referrer,
                ConveyorMath.mul64U(REFERRAL_PERCENT, msg.value)
            );
        }
    }

    /// @notice Swap ETH for tokens.
    /// @param swapData The swap data for the transaction.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactEthForToken(
        EthToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) public payable {
        if (swapData.protocolFee > msg.value) {
            revert InsufficientMsgValue();
        }

        ///@notice Cache the amountIn to save gas.
        uint256 amountIn = msg.value - swapData.protocolFee;

        ///@notice Deposit the msg.value-protocolFee into WETH.
        _depositEth(amountIn, WETH);

        ///@notice Transfer WETH from WETH to tokenInDestination address.
        IERC20(WETH).transfer(
            swapAggregatorMulticall.tokenInDestination,
            amountIn
        );

        ///@notice Get tokenOut balance of msg.sender.
        uint256 balanceBefore = IERC20(swapData.tokenOut).balanceOf(msg.sender);

        ///@notice Calculate tokenOut amount required.
        uint256 tokenOutAmountRequired = balanceBefore + swapData.amountOutMin;

        ///@notice Execute Multicall.
        IConveyorMulticall(CONVEYOR_MULTICALL).executeMulticall(
            swapAggregatorMulticall
        );

        ///@notice Get tokenOut balance of msg.sender after multicall execution.
        uint256 balanceAfter = IERC20(swapData.tokenOut).balanceOf(msg.sender);

        ///@notice Revert if tokenOut balance of msg.sender is insufficient.
        if (balanceAfter < tokenOutAmountRequired) {
            revert InsufficientOutputAmount(
                tokenOutAmountRequired - balanceAfter,
                swapData.amountOutMin
            );
        }
        if (swapData.affiliate & 0xFFFF != 0x0) {
            address affiliate = affiliates[swapData.affiliate >> 0x1];
            if (affiliate == address(0)) {
                revert AffiliateDoesNotExist();
            }
            _safeTransferETH(
                affiliate,
                ConveyorMath.mul64U(AFFILIATE_PERCENT, swapData.protocolFee)
            );
        }
        ///@dev First bit of referrer is used to check if referrer exists
        if (swapData.referrer & 0xFFFF != 0x0) {
            address referrer = referrers[swapData.referrer >> 0x1];
            if (referrer == address(0)) {
                revert ReferrerDoesNotExist();
            }
            _safeTransferETH(
                referrer,
                ConveyorMath.mul64U(REFERRAL_PERCENT, swapData.protocolFee)
            );
        }
    }

    /// @notice Swap tokens for ETH.
    /// @param swapData The swap data for the transaction.
    /// @param swapAggregatorMulticall Multicall to be executed.
    function swapExactTokenForEth(
        TokenToEthSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) public payable {
        ///@dev Ignore if the tokenInDestination is address(0).
        if (swapAggregatorMulticall.tokenInDestination != address(0)) {
            ///@notice Transfer tokenIn from msg.sender to tokenInDestination address.
            IERC20(swapData.tokenIn).safeTransferFrom(
                msg.sender,
                swapAggregatorMulticall.tokenInDestination,
                swapData.amountIn
            );
        }
        ///@notice Get ETH balance of msg.sender.
        uint256 balanceBefore = msg.sender.balance;

        ///@notice Calculate amountOutRequired.
        uint256 amountOutRequired = balanceBefore + swapData.amountOutMin;

        ///@notice Execute Multicall.
        IConveyorMulticall(CONVEYOR_MULTICALL).executeMulticall(
            swapAggregatorMulticall
        );

        ///@notice Get WETH balance of this contract.
        uint256 balanceWeth = IERC20(WETH).balanceOf(address(this));

        ///@notice Withdraw WETH from this contract.
        _withdrawEth(balanceWeth, WETH);

        ///@notice Transfer ETH to msg.sender.
        _safeTransferETH(msg.sender, balanceWeth);

        ///@notice Revert if Eth balance of the caller is insufficient.
        if (msg.sender.balance < amountOutRequired) {
            revert InsufficientOutputAmount(
                amountOutRequired - msg.sender.balance,
                swapData.amountOutMin
            );
        }
        if (swapData.affiliate & 0xFFFF != 0x0) {
            address affiliate = affiliates[swapData.affiliate >> 0x1];
            if (affiliate == address(0)) {
                revert AffiliateDoesNotExist();
            }
            _safeTransferETH(
                affiliate,
                ConveyorMath.mul64U(AFFILIATE_PERCENT, msg.value)
            );
        }
        ///@dev First bit of referrer is used to check if referrer exists
        if (swapData.referrer & 0xFFFF != 0x0) {
            address referrer = referrers[swapData.referrer >> 0x1];
            if (referrer == address(0)) {
                revert ReferrerDoesNotExist();
            }
            _safeTransferETH(
                referrer,
                ConveyorMath.mul64U(REFERRAL_PERCENT, msg.value)
            );
        }
    }

    /// @notice Quotes the amount of gas used for a optimized token to token swap.
    /// @dev This function should be used off chain through a static call.
    function quoteSwapExactTokenForToken(
        TokenToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed) {
        uint256 gasBefore;
        assembly {
            gasBefore := gas()
        }
        swapExactTokenForToken(swapData, swapAggregatorMulticall);
        assembly {
            gasConsumed := sub(gasBefore, gas())
        }
    }

    /// @notice Quotes the amount of gas used for a ETH to token swap.
    /// @dev This function should be used off chain through a static call.
    function quoteSwapExactEthForToken(
        EthToTokenSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed) {
        uint256 gasBefore;
        assembly {
            gasBefore := gas()
        }
        swapExactEthForToken(swapData, swapAggregatorMulticall);
        assembly {
            gasConsumed := sub(gasBefore, gas())
        }
    }

    /// @notice Quotes the amount of gas used for a token to ETH swap.
    /// @dev This function should be used off chain through a static call.
    function quoteSwapExactTokenForEth(
        TokenToEthSwapData calldata swapData,
        SwapAggregatorMulticall calldata swapAggregatorMulticall
    ) external payable returns (uint256 gasConsumed) {
        uint256 gasBefore;
        assembly {
            gasBefore := gas()
        }

        swapExactTokenForEth(swapData, swapAggregatorMulticall);
        assembly {
            gasConsumed := sub(gasBefore, gas())
        }
    }

    ///@notice Helper function to transfer ETH.
    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /// @notice Helper function to Withdraw ETH from WETH.
    function _withdrawEth(uint256 amount, address weth) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(
                0x0,
                shl(224, 0x2e1a7d4d) /* keccak256("withdraw(uint256)") */
            )
            mstore(4, amount)
            if iszero(
                call(
                    gas() /* gas */,
                    weth /* to */,
                    0 /* value */,
                    0 /* in */,
                    68 /* in size */,
                    0 /* out */,
                    0 /* out size */
                )
            ) {
                revert("Native Token Withdraw failed", amount)
            }
        }
    }

    /// @notice Helper function to Deposit ETH into WETH.
    function _depositEth(uint256 amount, address weth) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0, shl(224, 0xd0e30db0)) /* keccak256("deposit()") */
            if iszero(
                call(
                    gas() /* gas */,
                    weth /* to */,
                    amount /* value */,
                    0 /* in */,
                    0 /* in size */,
                    0 /* out */,
                    0 /* out size */
                )
            ) {
                revert("Native token deposit failed", amount)
            }
        }
    }

    /// @notice Withdraw ETH from this contract.
    function withdraw() external onlyOwner {
        _safeTransferETH(msg.sender, address(this).balance);
        emit Withdraw(msg.sender, address(this).balance);
    }

    ///@notice Function to confirm ownership transfer of the contract.
    function confirmTransferOwnership() external {
        if (msg.sender != tempOwner) {
            revert UnauthorizedCaller();
        }

        ///@notice Cleanup tempOwner storage.
        tempOwner = address(0);
        owner = msg.sender;
    }

    ///@notice Function to transfer ownership of the contract.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidAddress();
        }

        tempOwner = newOwner;
    }

    ///@notice Function to upgrade the ConveyorMulticall contract.
    function upgradeMulticall(
        bytes memory bytecode,
        bytes32 salt
    ) external payable onlyOwner returns (address) {
        assembly {
            let addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }

            sstore(CONVEYOR_MULTICALL.slot, addr)
        }

        return CONVEYOR_MULTICALL;
    }

    ///@notice Function to set affiliate address.
    function initializeAffiliate(address affiliateAddress) external onlyOwner {
        uint16 tempAffiliateNonce = affiliateNonce;
        affiliates[tempAffiliateNonce] = affiliateAddress;
        affiliateIndex[affiliateAddress] = tempAffiliateNonce;
        unchecked {
            tempAffiliateNonce++;
            require(
                tempAffiliateNonce < type(uint16).max >> 0x1,
                "Affiliate nonce overflow"
            );
            affiliateNonce = tempAffiliateNonce;
        }
    }

    ///@notice Function to set referrer mapping.
    function initializeReferrer() external payable {
        if (referrerIndex[msg.sender] != 0) {
            revert ReferrerAlreadyInitialized();
        }
        uint16 tempReferrerNonce = referrerNonce;
        referrers[tempReferrerNonce] = msg.sender;
        referrerIndex[msg.sender] = uint16(tempReferrerNonce);

        unchecked {
            tempReferrerNonce++;
            require(
                tempReferrerNonce < type(uint16).max >> 0x1,
                "Referrer nonce overflow"
            );
            referrerNonce = tempReferrerNonce;
        }
    }

    /// @notice Fallback receiver function.
    receive() external payable {}
}

/// @title ConveyorMulticall
/// @author 0xOsiris, 0xKitsune, Conveyor Labs
/// @notice Optimized multicall execution contract.
contract ConveyorMulticall is IConveyorMulticall, ConveyorSwapCallbacks {
    constructor() {}

    function executeMulticall(
        ConveyorRouterV1.SwapAggregatorMulticall calldata multicall
    ) external {
        for (uint256 i = 0; i < multicall.calls.length; ) {
            address target = multicall.calls[i].target;
            bytes calldata callData = multicall.calls[i].callData;
            assembly ("memory-safe") {
                let freeMemoryPointer := mload(0x40)
                calldatacopy(
                    freeMemoryPointer,
                    callData.offset,
                    callData.length
                )
                if iszero(
                    call(
                        gas(),
                        target,
                        0,
                        freeMemoryPointer,
                        callData.length,
                        0,
                        0
                    )
                ) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}
