pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Factory.sol";
import "./TransferHelper.sol";
import "./ECDSA.sol";

import "./UniswapV2Library.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract UniswapV2Router03 {
    using SafeMath for uint256;

    address public factory;
    address public WETH;
    address public destroyer; // Has the power to kill this contract.

    /**
     * @notice Parameters for refunding the gas payer
     */
    struct GasPayerRefund {
        address payable gasPayer; // Gas payer
        uint256 gasOverhead; // Overhead of transaction (21k + some extra)
    }

    /**
     * @notice Handles the replay protection for the meta-tx
     */
    struct ReplayProtection {
        address signer; // Signer of meta-tx
        uint256 nonce; // Only used once
        bytes signature; // Signature of swap & gas refund.
    }

    // Checks for a unique hash
    mapping(bytes32 => bool) public signedHash;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH, address _destroyer) public {
        factory = _factory;
        WETH = _WETH;
        destroyer = _destroyer;
    }

    function _checkSignature(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline,
        GasPayerRefund memory gasRefund,
        ReplayProtection memory replayProtection
    ) internal {
        // We sign the swap information (amount in, amount out, path, to, deadline),
        // We sign the signer's address to guarantee only they can store this hash,
        // We sign the chainID to make sure it is for this fork of the blockchain,
        // We sign the target contract (this) to make sure it is only used here.
        bytes32 h = keccak256(
            abi.encode(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline,
                gasRefund,
                replayProtection.signer,
                replayProtection.nonce,
                getChainID(),
                address(this)
            )
        );
        require(signedHash[h] == false, "Hash must be unique.");
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(h), replayProtection.signature); // about 3k

        require(signer == replayProtection.signer, "Signer must have signed this message");
        signedHash[h] = true; // Hash can no longer be used. // 20k gas 
    }

    /**
     * Get Ethereum Chain ID
     * */
    function getChainID() public pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    // It costs approximately 35k gas to include ETH refund and the meta-transaction verify sig. 
    function metaSwapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline,
        GasPayerRefund memory gasRefund,
        ReplayProtection memory replayProtection
    ) public ensure(deadline) returns (uint256[] memory amounts) {

        // Tracks gas used. 
        uint gasUsedTracker = gasleft() + gasRefund.gasOverhead;

        // Reverts if it fails to check the signature.
        // About 25k gas in total due to storing hash. We can reduce it to 10k gas with bitflip (e.g. 20k -> 5k for storage)
        _checkSignature(amountIn, amountOutMin, path, to, deadline, gasRefund, replayProtection);

        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            replayProtection.signer,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        // Work out how much ETH to send to user and to the broker
        gasUsedTracker = gasUsedTracker - gasleft();
        uint256 toRefund = tx.gasprice * gasUsedTracker;
        uint256 sendToSigner = amounts[amounts.length - 1] - toRefund; // Remove refund
        
        // Prevents any overflow problems with "sendToSigner". 
        require(amounts[amounts.length - 1] > toRefund, "Cannot refund as transfer is too small.");

        // Most funds to the sender
        TransferHelper.safeTransferETH(to, sendToSigner);
        // ~10k gas to refund the gas payer
        TransferHelper.safeTransferETH(gasRefund.gasPayer, toRefund); 
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public virtual pure returns (uint256 amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    // Permit() requires infinite approval to this contract.
    // If there is any unforeseen bug, then we can just destroy the contract.
    function destroy() public {
        require(msg.sender == destroyer, "Only destroyer can self-destruct");
        selfdestruct(msg.sender);
    }
}
