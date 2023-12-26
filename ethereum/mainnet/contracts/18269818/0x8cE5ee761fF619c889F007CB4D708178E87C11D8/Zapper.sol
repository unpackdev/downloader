// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "./Address.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./ERC2771Context.sol";

import "./IWrappedNative.sol";
import "./IRTokenZapper.sol";
import "./IPermit2.sol";

struct ExecuteOutput {
    uint256[] dust;
}
contract ZapperExecutor {
    receive() external payable {}

    /** @dev Main endpoint to call
     * @param calls - Each call to execute
     */
    function execute(
        Call[] calldata calls,
        IERC20[] calldata tokens
    ) external returns (ExecuteOutput memory out) {
        uint256 len = calls.length;
        for (uint256 i; i < len; i++) {
            address target = calls[i].to;
            (bool success, bytes memory data) = target.call{
                value: calls[i].value
            }(abi.encodePacked(calls[i].data));
            require(success, string(data));
        }
        out.dust = new uint256[](tokens.length);
        for(uint256 i; i < tokens.length; i++) {
            out.dust[i] = tokens[i].balanceOf(address(this));
        }
    }

    /**   @dev Utility for minting max amount of rToken.
               Should only be used off-chain to calculate the exact
               amount of an rToken that can be minted
        * @param token - rToken to mint
        * @param recipient - Recipient of the rToken
     */
    function mintMaxRToken(
        FacadeRead facade,
        RToken token,
        address recipient
    ) external {
        uint256 maxIssueableAmount = facade.maxIssuable(token, address(this));
        token.issueTo(recipient, maxIssueableAmount);
    }

    /** @dev Utility for returning remaining funds back to user
     * @param tokens - Tokens to move out of the ZapperExecutor contract
     * @param destination - Recipient of the ERC20 transfers
     */
    function drainERC20s(IERC20[] calldata tokens, address destination) external {
        uint256 len = tokens.length;
        for (uint256 i; i < len; i++) {
            IERC20 token = tokens[i];
            uint256 balance = token.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            SafeERC20.safeTransfer(token, destination, balance);
        }
    }

    /** @dev Utility for setting up all neccesary approvals for Zap
     * @param tokens - Tokens to set up approvals
     * @param spenders - Spenders - i'th token will be approved for i'th spender
     */
    function setupApprovals(IERC20[] calldata tokens, address[] calldata spenders) external {
        require(tokens.length == spenders.length, "Invalid params");
        uint256 len = tokens.length;
        for (uint256 i; i < len; i++) {
            IERC20 token = tokens[i];
            address spender = spenders[i];

            uint256 allowance = token.allowance(address(this), spender);

            if (allowance != 0) {
                continue;
            }
            SafeERC20.safeApprove(token, spender, type(uint256).max);
        }
    }
}

struct ZapperOutput {
    uint256[] dust;
    uint256 amountOut;
    uint256 gasUsed;
}

contract Zapper is ReentrancyGuard {
    IWrappedNative internal immutable wrappedNative;
    IPermit2 internal immutable permit2;
    ZapperExecutor internal immutable zapperExecutor;

    constructor(
        IWrappedNative wrappedNative_,
        IPermit2 permit2_,
        ZapperExecutor executor_
    ) {
        wrappedNative = wrappedNative_;
        permit2 = permit2_;
        zapperExecutor = executor_;
    }

    function zapInner(ZapERC20Params calldata params) internal returns (ZapperOutput memory out) {
        uint256 initialBalance = params.tokenOut.balanceOf(msg.sender);
        // STEP 1: Execute
        out.dust = zapperExecutor.execute(
            params.commands,
            params.tokensUsedByZap
        ).dust;

        // STEP 2: Verify that the user has gotten the tokens they requested
        uint256 newBalance = params.tokenOut.balanceOf(msg.sender);
        require(newBalance > initialBalance, "INVALID_NEW_BALANCE");
        uint256 difference = newBalance - initialBalance;
        require(difference >= params.amountOut, "INSUFFICIENT_OUT");

        out.amountOut = difference;
        
    }

    receive() external payable {
        require(msg.sender == address(wrappedNative), "INVALID_CALLER");
    }

    function zapERC20(
        ZapERC20Params calldata params
    ) external nonReentrant returns (ZapperOutput memory out) {
        uint256 startGas = gasleft();
        require(params.amountIn != 0, "INVALID_INPUT_AMOUNT");
        require(params.amountOut != 0, "INVALID_OUTPUT_AMOUNT");
        SafeERC20.safeTransferFrom(
            params.tokenIn,
            msg.sender,
            address(zapperExecutor),
            params.amountIn
        );
        out = zapInner(params);
        out.gasUsed = startGas - gasleft();
    }

    function zapERC20WithPermit2(
        ZapERC20Params calldata params,
        PermitTransferFrom calldata permit,
        bytes calldata signature
    ) external nonReentrant returns (ZapperOutput memory out) {
        uint256 startGas = gasleft();
        require(params.amountIn != 0, "INVALID_INPUT_AMOUNT");
        require(params.amountOut != 0, "INVALID_OUTPUT_AMOUNT");

        permit2.permitTransferFrom(
            permit,
            SignatureTransferDetails({
                to: address(zapperExecutor),
                requestedAmount: params.amountIn
            }),
            msg.sender,
            signature
        );

        out = zapInner(params);
        out.gasUsed = startGas - gasleft();
    }

    function zapETH(
        ZapERC20Params calldata params
    ) external payable nonReentrant returns (ZapperOutput memory out) {
        uint256 startGas = gasleft();
        require(address(params.tokenIn) == address(wrappedNative), "INVALID_INPUT_TOKEN");
        require(params.amountIn == msg.value, "INVALID_INPUT_AMOUNT");
        require(msg.value != 0, "INVALID_INPUT_AMOUNT");
        require(params.amountOut != 0, "INVALID_OUTPUT_AMOUNT");
        wrappedNative.deposit{ value: msg.value }();
        SafeERC20.safeTransfer(
            IERC20(address(wrappedNative)),
            address(zapperExecutor),
            wrappedNative.balanceOf(address(this))
        );
        out = zapInner(params);
        out.gasUsed = startGas - gasleft();
    }
}
