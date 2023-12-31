// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ILiquityHandler.sol";
import "./ErrorLib.sol";
import "./Messaging.sol";
import "./TroveHandler.sol";

/// @title TroveHandler contract.
/// @author Spaceshard team 2023.
contract LiquityHandler is
    ILiquityHandler,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Messaging,
    TroveHandler
{
    /// @notice The function selector we have to call on L2 to consume the L1 message.
    uint256 public constant L2_HANDLER_SELECTOR =
        0x10e13e50cb99b6b3c8270ec6e16acfccbe1164a629d74b43549567a77593aff;

    /// @notice The liquity L2 trove contract address.
    uint256 public l2Trove;

    /// @notice Starknet ETH bridge address.
    address public l1ETHBridge;

    /// @notice Starknet LUSD bridge address.
    address public l1LUSDBridge;

    /// @notice The LUSD address.
    address public lusd;

    /// @notice The L2 Eth contract.
    uint256 public l2ETHBridge;

    /// @notice The L2 LUSD contract.
    uint256 public l2LUSDBridge;

    /// @notice The amount of ETH fees the l1 liquity contract has to call response_handler function on L2.
    uint256 public l2HandlerGasFee;

    /// @notice The amount of ETH fees the l1 liquity contract has to pay to execute the transaction on L2.
    uint256 public l2BridgeEthFee;

    /// @notice The relayer L1 address.
    address public relayer;

    /// @notice stop borrows.
    bool public canBorrow;

    /// @notice Allows to execyte batches in.
    uint256 public batchCounter;

    /// @notice Store the l2 message payload.
    ResponsePayload public messagePayload;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initialier the contract state.
    /// @param _troveManager troveManager address
    /// @param _sortedTroves sortedTroves address
    /// @param _borrowerOperations borrowerOperations address
    /// @param _starknetCore starknetCore address
    /// @param _l1ETHBridge l1ETHBridge address
    /// @param _l2ETHBridge l2ETHBridge address
    /// @param _l1LUSDBridge l1LUSDBridge address
    /// @param _l2LUSDBridge l2LUSDBridge address
    /// @param _initialICRPerc initialICRPerc address
    /// @param _relayer relayer address
    /// @param _lusd lusd address
    function initialize(
        address _troveManager,
        address _sortedTroves,
        address _borrowerOperations,
        address _starknetCore,
        address _l1ETHBridge,
        uint256 _l2ETHBridge,
        address _l1LUSDBridge,
        uint256 _l2LUSDBridge,
        uint256 _initialICRPerc,
        address _relayer,
        address _lusd
    ) public payable initializer {
        __Pausable_init();
        __Ownable_init();
        initializeMessaging(_starknetCore);
        initializeTroveHandler(_troveManager, _sortedTroves, _borrowerOperations, _initialICRPerc);
        relayer = _relayer;
        l1ETHBridge = _l1ETHBridge;
        l2ETHBridge = _l2ETHBridge;
        l1LUSDBridge = _l1LUSDBridge;
        l2LUSDBridge = _l2LUSDBridge;
        lusd = _lusd;
        canBorrow = true;
    }

    /// @notice execute a batch.
    /// @dev In phase 2 this could be made permissionless.
    /// @param _payload the payload data.
    /// @param _l2BridgeEthFee max fee to borrow.
    /// @param _maxFees max fee to borrow.
    function executeBatch(
        RequestPayload calldata _payload,
        uint256 _l2BridgeEthFee,
        uint64 _maxFees
    ) external payable nonReentrant whenNotPaused {
        if (batchCounter + 1 != _payload.nonce) revert ErrorLib.InvalidBatchNonce();
        if (msg.sender != relayer) revert ErrorLib.NotRelayer();

        uint256 l2TroveMem = l2Trove;
        // Consume the message sent from the L2 trove.
        _consumeL2Message(l2TroveMem, _getRequestMessageData(_payload));

        // Withdraw tokens from Starknet bridges.
        _withdrawTokensFromBridges(_payload.amountETH, _payload.amountLUSD);

        // Get the trove status.
        Status troveStatus = getTroveStatus();

        // If the trove has been liquidated, the batch is returned to L2 to refund users.
        if (troveStatus != Status.active) {
            _sendBackBatchWithoutProcessing(_payload, _l2BridgeEthFee);
            return;
        }

        uint256 amountLUSDOut = 0;
        uint256 amountETHOut = 0;
        // Store canBorrow in memory to save gas.
        bool canBorrowMem = canBorrow;

        (uint256 troveDebt, uint256 troveColl, , ) = troveManager.getEntireDebtAndColl(
            address(this)
        );

        // If a redistribution has taken place, borrowing is disabled and users can only repay their debts.
        if (totalSupply() != troveDebt && _payload.amountETH > 0) {
            if (canBorrowMem) {
                canBorrow = false;
                canBorrowMem = false;
            }
            amountETHOut = _payload.amountETH;
            emit DisableBorrow(_payload.nonce, _payload.amountETH);
        }

        (TroveAction action, uint256 actionInput) = getActionInputs(
            canBorrowMem,
            _payload.amountETH,
            _payload.amountLUSD,
            troveDebt,
            troveColl
        );

        if (action == TroveAction.BORROW && canBorrowMem && _payload.amountETH > 0) {
            uint256 amountLUSDBorrowed = _borrow(actionInput, _maxFees);
            amountLUSDOut = amountLUSDBorrowed + _payload.amountLUSD;
            amountETHOut = _payload.amountETH - actionInput;
        } else if (action == TroveAction.REPAY && _payload.amountLUSD > 0) {
            uint256 collateral = _repay(actionInput);
            amountETHOut += collateral + (canBorrowMem ? _payload.amountETH : 0);
            amountLUSDOut = _payload.amountLUSD - actionInput;
        } else {
            amountETHOut = _payload.amountETH;
            amountLUSDOut = _payload.amountLUSD;
        }

        if (amountLUSDOut > 0) {
            IERC20(lusd).approve(l1LUSDBridge, amountLUSDOut);
            depositToBridgeToken(l1LUSDBridge, l2TroveMem, amountLUSDOut, _l2BridgeEthFee);
        }

        if (amountETHOut > 0) {
            depositToBridgeToken(
                l1ETHBridge,
                l2TroveMem,
                amountETHOut,
                amountETHOut + _l2BridgeEthFee
            );
        }

        (troveDebt, , , ) = troveManager.getEntireDebtAndColl(address(this));

        messagePayload = ResponsePayload({
            nonce: _payload.nonce,
            amountLUSD: amountLUSDOut,
            totalSupply: totalSupply() - initialSupply,
            totalTroveDebt: troveDebt - initialSupply,
            amountETH: amountETHOut,
            closed: 0x0
        });

        emit BatchProcessed(
            _payload.nonce,
            amountLUSDOut,
            totalSupply() - initialSupply,
            troveDebt - initialSupply,
            amountETHOut,
            0x0
        );
    }

    /// @notice Admin function used to create a trove on liquity core contract.
    /// @param _maxFees max fee to pay.
    function openTrove(uint256 _maxFees) external payable onlyOwner {
        (address upperHint, address lowerHint) = _getHints();
        _openTrove(lusd, upperHint, lowerHint, _maxFees);
    }

    /// @notice Admin function used to close a trove on liquity core contract.
    function closeTrove() external payable onlyOwner {
        _closeTrove(lusd);
    }

    /// @notice Admin function used to recover tokens that where accidentiliy transferred to this address.
    /// @param _token The address of the token to recover.
    /// @param _to The address to send the tokens to.
    function recoverTokens(address _token, address _to) external onlyOwner {
        if (_token == address(0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        }
    }

    /// @notice Admin function used to pause the contract in the case of an emergency.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Admin function used to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Set relayer address.
    /// @param _newRelayer relayer address.
    function setRelayer(address _newRelayer) external onlyOwner {
        relayer = _newRelayer;
        emit SetRelayer(_newRelayer);
    }

    /// @notice set trove address.
    /// @param _l2Trove The liquity L2 trove.
    function setL2TroveAddress(uint256 _l2Trove) external onlyOwner {
        l2Trove = _l2Trove;
    }

    /// @notice set trove address.
    /// @param _l1LUSDBridge The lusd bridge on L1.
    /// @param _l2LUSDBridge The lusd bridge on L2.
    function setLUSDBridge(address _l1LUSDBridge, uint256 _l2LUSDBridge) external onlyOwner {
        l2LUSDBridge = _l2LUSDBridge;
        l1LUSDBridge = _l1LUSDBridge;
    }

    function _getRequestMessageData(
        RequestPayload memory _payload
    ) internal pure returns (uint256[] memory data) {
        (uint256 lowNonce, uint256 highNonce) = u256(_payload.nonce);
        (uint256 lowAmountETH, uint256 highAmountETH) = u256(_payload.amountETH);
        (uint256 lowAmountLUSD, uint256 highAmountLUSD) = u256(_payload.amountLUSD);
        data = new uint256[](6);
        data[0] = lowNonce;
        data[1] = highNonce;
        data[2] = lowAmountETH;
        data[3] = highAmountETH;
        data[4] = lowAmountLUSD;
        data[5] = highAmountLUSD;
    }

    function _getResponseMessageData(
        ResponsePayload memory _payload
    ) internal pure returns (uint256[] memory data) {
        (uint256 lowNonce, uint256 highNonce) = u256(_payload.nonce);
        (uint256 lowAmountLUSD, uint256 highAmountLUSD) = u256(_payload.amountLUSD);
        (uint256 lowAmountETH, uint256 highAmountETH) = u256(_payload.amountETH);
        (uint256 lowTotalSupply, uint256 highTotalSupply) = u256(_payload.totalSupply);
        (uint256 lowTotalTroveDebt, uint256 highTotalTroveDebt) = u256(_payload.totalTroveDebt);
        data = new uint256[](11);
        data[0] = lowNonce;
        data[1] = highNonce;
        data[2] = lowAmountLUSD;
        data[3] = highAmountLUSD;
        data[4] = lowTotalSupply;
        data[5] = highTotalSupply;
        data[6] = lowTotalTroveDebt;
        data[7] = highTotalTroveDebt;
        data[8] = lowAmountETH;
        data[9] = highAmountETH;
        data[10] = _payload.closed;
    }

    function _withdrawTokensFromBridges(uint256 _amountETH, uint256 _amountLUSD) private {
        if (_amountETH > 0) {
            _withdrawTokenFromBridge(l1ETHBridge, l2ETHBridge, address(this), _amountETH);
        }

        if (_amountLUSD > 0) {
            _withdrawTokenFromBridge(l1LUSDBridge, l2LUSDBridge, address(this), _amountLUSD);
        }
    }

    function _sendBackBatchWithoutProcessing(
        RequestPayload calldata _payload,
        uint256 _l2BridgeEthFee
    ) private {
        uint256 l2TroveMem = l2Trove;
        if (_payload.amountLUSD > 0) {
            IERC20(lusd).approve(l1LUSDBridge, _payload.amountLUSD);
            depositToBridgeToken(l1LUSDBridge, l2TroveMem, _payload.amountLUSD, _l2BridgeEthFee);
        }

        if (_payload.amountETH > 0) {
            depositToBridgeToken(
                l1ETHBridge,
                l2TroveMem,
                _payload.amountETH,
                _payload.amountETH + _l2BridgeEthFee
            );
        }

        messagePayload = ResponsePayload({
            nonce: _payload.nonce,
            amountLUSD: 0,
            totalSupply: 0,
            totalTroveDebt: 0,
            amountETH: 0,
            closed: 0x1
        });

        emit BatchProcessed(_payload.nonce, 0, 0, 0, 0, 0x1);
    }

    /// @notice Allows to calculate which action we have to call `borrow`, `repay` or swap in place.
    /// @param _canBorrow if borrowing is enabled.
    /// @param _amountETH amount ETH
    /// @param _amountLUSD amount LUSD
    /// @param _troveDebt amount trove debt
    /// @param _troveColl amount trove collaterals
    /// @return action the actions that should be triggered.
    /// @return actionAmountInput the actions input amount.
    function getActionInputs(
        bool _canBorrow,
        uint256 _amountETH,
        uint256 _amountLUSD,
        uint256 _troveDebt,
        uint256 _troveColl
    ) public returns (TroveAction action, uint256 actionAmountInput) {
        if (!_canBorrow) {
            action = TroveAction.REPAY;
            actionAmountInput = _amountLUSD;
            return (action, actionAmountInput);
        }

        uint256 amountLUSDToBorrow = computeAmtToBorrow(_amountETH);
        if (amountLUSDToBorrow < _amountLUSD) {
            // No need to borrow as the current LUSD attached can cover the borrowing.
            // Call repay only.
            action = TroveAction.REPAY;
            actionAmountInput = _amountLUSD - amountLUSDToBorrow;
        } else if (amountLUSDToBorrow > _amountLUSD) {
            // No need to repay as the current ETH attached can cover the repaying.
            // Call borrow only.
            uint256 amountETHRepay = computeCollateralAmountOut(
                _amountLUSD,
                _troveDebt,
                _troveColl
            );
            action = TroveAction.BORROW;
            actionAmountInput = _amountETH - amountETHRepay;
        } else {
            action = TroveAction.NONE;
            actionAmountInput = 0;
        }
    }

    /// @notice Allows the admin to send the message again to L2.
    /// @param _resend if true resend the message to L2.
    function sendMessageToL2(bool _resend) external payable {
        ResponsePayload memory messagePayloadMem = messagePayload;
        if (_resend && messagePayloadMem.nonce != batchCounter) revert ErrorLib.Resend();
        if (!_resend) {
            if (messagePayloadMem.nonce != batchCounter + 1) revert ErrorLib.InvalidBatchNonce();
            batchCounter++;
        }

        _sendMessageToL2(
            l2Trove,
            L2_HANDLER_SELECTOR,
            _getResponseMessageData(
                ResponsePayload({
                    nonce: messagePayloadMem.nonce,
                    amountLUSD: messagePayloadMem.amountLUSD,
                    totalSupply: messagePayloadMem.totalSupply,
                    totalTroveDebt: messagePayloadMem.totalTroveDebt,
                    amountETH: messagePayloadMem.amountETH,
                    closed: messagePayloadMem.closed
                })
            ),
            msg.value
        );
    }
}
