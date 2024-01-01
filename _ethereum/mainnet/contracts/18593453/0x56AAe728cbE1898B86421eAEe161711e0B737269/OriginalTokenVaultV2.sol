// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ISigsVerifier.sol";
import "./IWETH.sol";
import "./PbPegged.sol";
import "./Pauser.sol";
import "./VolumeControl.sol";
import "./IBridgeAdminOracle.sol";
import "./DelayedTransfer.sol";


/**
 * @title the vault to deposit and withdraw original tokens
 * @dev Work together with PeggedTokenBridge contracts deployed at remote chains
 */
contract OriginalTokenVaultV2 is ReentrancyGuard, Pauser, VolumeControl, DelayedTransfer {
    using SafeERC20 for IERC20;
    
    IBridgeAdminOracle public bridgeAdminOracle;
    ISigsVerifier public immutable sigsVerifier;

    mapping(bytes32 => bool) public records;

    mapping(address => uint256) public minDeposit;
    mapping(address => uint256) public maxDeposit;

    event Deposited(
        bytes32 depositId,
        address depositor,
        address token,
        uint256 amount,
        uint64 mintChainId,
        address mintAccount,
        uint64 nonce
    );
    event Withdrawn(
        bytes32 withdrawId,
        address receiver,
        address token,
        uint256 amount,
        // ref_chain_id defines the reference chain ID, taking values of:
        // 1. The common case of burn-withdraw: the chain ID on which the corresponding burn happened;
        // 2. Pegbridge fee claim: zero / not applicable;
        // 3. Refund for wrong deposit: this chain ID on which the deposit happened
        uint64 refChainId,
        // ref_id defines a unique reference ID, taking values of:
        // 1. The common case of burn-withdraw: the burn ID on the remote chain;
        // 2. Pegbridge fee claim: a per-account nonce;
        // 3. Refund for wrong deposit: the deposit ID on this chain
        bytes32 refId,
        address burnAccount
    );
    event MinDepositUpdated(address token, uint256 amount);
    event MaxDepositUpdated(address token, uint256 amount);
    event FeeReceiverChanged(address newFeeReceiver);

    constructor(ISigsVerifier _sigsVerifier, address _bridgeAdminOracle) {
        sigsVerifier = _sigsVerifier;
        bridgeAdminOracle = IBridgeAdminOracle(_bridgeAdminOracle);
    }

    modifier checkFee(uint256 _value)
    {
        require(_value >= bridgeAdminOracle.getFee(), "fee not met");
        _;
    }

    modifier checkChain(uint64 _chainId)
    {
        require(bridgeAdminOracle.checkChain(_chainId), "chain not allowed");
        _;
    }

    modifier checkToken(address _token)
    {
        require(bridgeAdminOracle.checkToken(_token), "token not allowed");
        _;
    }

    /**
     * @notice Lock original tokens to trigger cross-chain mint of pegged tokens at a remote chain's PeggedTokenBridge.
     * @param _token The original token address.
     * @param _amount The amount to deposit.
     * @param _mintChainId The destination chain ID to mint tokens.
     * @param _mintAccount The destination account to receive the minted pegged tokens.
     * @param _nonce A number input to guarantee unique depositId. Can be timestamp in practice.
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external payable nonReentrant whenNotPaused checkFee(msg.value) checkChain(_mintChainId) checkToken(_token) returns (bytes32) {
        address payable feeReceiver = payable(bridgeAdminOracle.getFeeReceiver());
        feeReceiver.transfer(msg.value);
        bytes32 depId = _deposit(msg.sender, _token, _amount, _mintChainId, _mintAccount, _nonce);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(depId, msg.sender, _token, _amount, _mintChainId, _mintAccount, _nonce);

        return depId;
    }

    function _deposit(
        address _from,
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) private returns (bytes32) {
        require(_amount > minDeposit[_token], "amount too small");
        require(maxDeposit[_token] == 0 || _amount <= maxDeposit[_token], "amount too large");
        bytes32 depId = keccak256(
            // len = 20 + 20 + 32 + 8 + 20 + 8 + 8 + 20 = 136
            abi.encodePacked(
                _from,
                _token,
                _amount,
                _mintChainId,
                _mintAccount,    
                _nonce,
                uint64(block.chainid),
                address(this)
            )
        );
        require(records[depId] == false, "record exists");
        records[depId] = true;
        return depId;
    }

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external whenNotPaused returns (bytes32) {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Withdraw"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _request), _sigs, _signers, _powers);

        PbPegged.Withdraw memory request = PbPegged.decWithdraw(_request);

        bytes32 wdId = keccak256(
            // len = 20 + 20 + 32 + 20 + 8 + 32 + 20 = 152
            abi.encodePacked(
                request.receiver,
                request.token,
                request.amount,
                request.burnAccount,
                request.refChainId,
                request.refId,
                address(this)
            )
        );
        require(records[wdId] == false, "record exists");

        records[wdId] = true;
        _updateVolume(request.token, request.amount);
        uint256 delayThreshold = delayThresholds[request.token];
        if (delayThreshold > 0 && request.amount > delayThreshold) {
            _addDelayedTransfer(wdId, request.receiver, request.token, request.amount);
        } else {
            _sendToken(request.receiver, request.token, request.amount);
        }
        
        emit Withdrawn(
            wdId,
            request.receiver,
            request.token,
            request.amount,
            request.refChainId,
            request.refId,
            request.burnAccount
        );
        return wdId;
    }

    function executeDelayedTransfer(bytes32 id) external whenNotPaused {
        delayedTransfer memory transfer = _executeDelayedTransfer(id);
        _sendToken(transfer.receiver, transfer.token, transfer.amount);
    }

    function setMinDeposit(address[] calldata _tokens, uint256[] calldata _amounts) external onlyOwner {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minDeposit[_tokens[i]] = _amounts[i];
            emit MinDepositUpdated(_tokens[i], _amounts[i]);
        }
    }

    function setMaxDeposit(address[] calldata _tokens, uint256[] calldata _amounts) external onlyOwner {
        require(_tokens.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            maxDeposit[_tokens[i]] = _amounts[i];
            emit MaxDepositUpdated(_tokens[i], _amounts[i]);
        }
    }

    function _sendToken(
        address _receiver,
        address _token,
        uint256 _amount
    ) private {
        IERC20(_token).safeTransfer(_receiver, _amount);
    }

    receive() external payable {}
}
