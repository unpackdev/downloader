//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ITokensApprover.sol";
import "./ISwapV2Router.sol";
import "./IGasStationTokensStore.sol";
import "./IExchange.sol";
import "./FeePayerGuard.sol";

import "./LondonTxSupport.sol";
//import "./LegacyTxSupport.sol";

contract GasStation is Ownable, FeePayerGuard, LondonTxSupport {

    using SafeMath for uint256;

    IExchange public exchange;

    IGasStationTokensStore public feeTokensStore;

    ITokensApprover public approver;

    bytes32 public DOMAIN_SEPARATOR;
    // Commission as a percentage of the transaction fee, for processing one transaction.
    uint256 public txRelayFeePercent;
    // Post call gas limit (Prevents overspending of gas)
    uint256 public maxPostCallGasUsage = 350000;
    // Gas usage by tokens
    mapping(address => uint256) postCallGasUsage;

    event GasStationTxExecuted(
        address indexed from,
        address to,
        address feeToken,
        uint256 totalFeeInTokens,
        uint256 txRelayFeeInEth
    );
    event GasStationExchangeUpdated(address indexed newExchange);
    event GasStationFeeTokensStoreUpdated(address indexed newFeeTokensStore);
    event GasStationApproverUpdated(address indexed newApprover);
    event GasStationTxRelayFeePercentUpdated(uint256 newTxRelayFeePercent);
    event GasStationMaxPostCallGasUsageUpdated(uint256 newMaxPostCallGasUsage);

    constructor(address _exchange, address _feeTokensStore, address _approver, address _feePayer, uint256 _txRelayFeePercent) {
        exchange = IExchange(_exchange);
        feeTokensStore = IGasStationTokensStore(_feeTokensStore);
        approver = ITokensApprover(_approver);
        txRelayFeePercent = _txRelayFeePercent;

        if (_feePayer != address(0)) {
            feePayers[_feePayer] = true;
        }

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function setExchange(address _exchange) external onlyOwner {
        exchange = IExchange(_exchange);
        emit GasStationExchangeUpdated(_exchange);
    }

    function setFeeTokensStore(IGasStationTokensStore _feeTokensStore) external onlyOwner {
        feeTokensStore = _feeTokensStore;
        emit GasStationFeeTokensStoreUpdated(address(_feeTokensStore));
    }

    function setApprover(ITokensApprover _approver) external onlyOwner {
        approver = _approver;
        emit GasStationApproverUpdated(address(_approver));
    }

    function setTxRelayFeePercent(uint256 _txRelayFeePercent) external onlyOwner {
        txRelayFeePercent = _txRelayFeePercent;
        emit GasStationTxRelayFeePercentUpdated(_txRelayFeePercent);
    }

    function setMaxPostCallGasUsage(uint256 _maxPostCallGasUsage) external onlyOwner {
        maxPostCallGasUsage = _maxPostCallGasUsage;
        emit GasStationMaxPostCallGasUsageUpdated(_maxPostCallGasUsage);
    }

    function getEstimatedPostCallGas(address _token) external view returns (uint256) {
        require(feeTokensStore.isAllowedToken(_token), "Fee token not supported");
        return _getEstimatedPostCallGas(_token);
    }
    /**
     * @notice Perform a transaction, take payment for gas with tokens, and exchange tokens back to ETH
     */
    function sendTransaction(TxRequest calldata _tx, TxFee calldata _fee, bytes calldata _sign) external onlyFeePayer {
        uint256 initialGas = gasleft();
        address txSender = _tx.from;
        IERC20 token = IERC20(_fee.token);

        // Verify sign and fee token
        _verify(_tx, _sign);
        require(feeTokensStore.isAllowedToken(address(token)), "Fee token not supported");

        // Execute user's transaction
        _call(txSender, _tx.to, _tx.value, _tx.data);

        // Total gas usage for call.
        uint256 callGasUsed = initialGas.sub(gasleft());
        uint256 estimatedGasUsed = callGasUsed.add(_getEstimatedPostCallGas(address(token)));
        require(estimatedGasUsed < _tx.gas, "Not enough gas");

        // Approve fee token with permit method
        _permit(_fee.token, _fee.approvalData);

        // We calculate and collect tokens to pay for the transaction
        (uint256 maxFeeInEth,) = _calculateCharge(_tx.gas, txRelayFeePercent, _tx);
        uint256 maxFeeInTokens = exchange.getEstimatedTokensForETH(token, maxFeeInEth);
        require(token.transferFrom(txSender, address(exchange), maxFeeInTokens), "Transfer fee failed");

        // Exchange user's tokens to ETH and emit executed event
        (uint256 totalFeeInEth, uint256 txRelayFeeInEth) = _calculateCharge(estimatedGasUsed, txRelayFeePercent, _tx);
        uint256 spentTokens = exchange.swapTokensToETH(token, totalFeeInEth, maxFeeInTokens, msg.sender, txSender);
        emit GasStationTxExecuted(txSender, _tx.to, _fee.token, spentTokens, txRelayFeeInEth);

        // We check the gas consumption, and save it for calculation in the following transactions
        _setUpEstimatedPostCallGas(_fee.token, initialGas.sub(gasleft()).sub(callGasUsed));
    }
    /**
     * @notice Executes a transaction.
     * @dev Used to calculate the gas required to complete the transaction.
     */
    function execute(address from, address to, uint256 value, bytes calldata data) external onlyFeePayer {
        _call(from, to, value, data);
    }

    function _permit(address token, bytes calldata approvalData) internal {
        if (approvalData.length > 0 && approver.hasConfigured(token)) {
            (bool success,) = approver.callPermit(token, approvalData);
            require(success, "Permit Method Call Error");
        }
    }

    function _call(address from, address to, uint256 value, bytes calldata data) internal {
        bytes memory callData = abi.encodePacked(data, from);
        (bool success,) = to.call{value : value}(callData);

        require(success, "Transaction Call Error");
    }

    function _verify(TxRequest calldata _tx, bytes calldata _sign) internal {
        require(_tx.deadline == 0 || _tx.deadline > block.timestamp, "Request expired");
        require(nonces[_tx.from]++ == _tx.nonce, "Nonce mismatch");

        address signer = _getSigner(DOMAIN_SEPARATOR, _tx, _sign);

        require(signer != address(0) && signer == _tx.from, 'Invalid signature');
    }

    function _getEstimatedPostCallGas(address _token) internal view returns (uint256) {
        return postCallGasUsage[_token] > 0 ? postCallGasUsage[_token] : maxPostCallGasUsage;
    }

    function _setUpEstimatedPostCallGas(address _token, uint256 _postCallGasUsed) internal {
        require(_postCallGasUsed < maxPostCallGasUsage, "Post call gas overspending");
        postCallGasUsage[_token] = _max(postCallGasUsage[_token], _postCallGasUsed);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
