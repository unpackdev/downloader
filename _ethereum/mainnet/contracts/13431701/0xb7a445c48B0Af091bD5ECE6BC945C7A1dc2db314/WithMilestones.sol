// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ContractContext.sol";
import "./MilestoneContext.sol";
import "./ITreasury.sol";
import "./IEscrowDisputeManager.sol";

abstract contract WithMilestones is ContractContext, MilestoneContext, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string private constant ERROR_MILESTONE_EXITS = "Milestone exists";
    string private constant ERROR_FUNDING = "Funding failed";
    string private constant ERROR_FUNDED = "Funding not needed";
    string private constant ERROR_RELEASED = "Invalid release amount";
    string private constant ERROR_NOT_DISPUTER = "Not a party";
    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw";

    uint16 internal constant MILESTONE_INDEX_BASE = 100;

    uint256 private constant EMPTY_INT = 0;

    /**
     * @dev As payer or delegater allow payee to claim released amount of payment token.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amountToRelease amount of payment token to release from the milestone.
     */
    function releaseMilestone(bytes32 _cid, uint16 _index, uint _amountToRelease) public {
        require(msg.sender == contracts[_cid].payerDelegate || msg.sender == contracts[_cid].payer, ERROR_NOT_VALIDATOR);

        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        uint _releasedAmount = _m.releasedAmount + _amountToRelease;
        // Can pontentially pre-release the full amount before funding, so we check full amount instead of fundedAmount
        require(_amountToRelease > 0 && _m.amount >= _releasedAmount, ERROR_RELEASED);

        _releaseMilestone(_mid, _releasedAmount, _amountToRelease, msg.sender);
    }

    /**
     * @dev As payee allow payer or delegate to claim refunded amount from funded payment token.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amountToRefund amount of payment token to refund from funded milestone.
     */
    function cancelMilestone(bytes32 _cid, uint16 _index, uint _amountToRefund) public {
        require(msg.sender == contracts[_cid].payeeDelegate || msg.sender == contracts[_cid].payee, ERROR_NOT_VALIDATOR);

        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        require(_amountToRefund > 0 && milestones[_mid].fundedAmount >= milestones[_mid].claimedAmount + _amountToRefund, ERROR_RELEASED);

        uint _refundedAmount = milestones[_mid].refundedAmount + _amountToRefund;
        _cancelMilestone(_mid, _refundedAmount, _amountToRefund, msg.sender);
    }

    /**
     * @dev Withdraw payment token amount released by payer or arbiter.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * If milestone supports automatic releases by autoReleasedAt,
     * it will allow to withdraw funded amount without explicit release
     * from another party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     */
    function withdrawMilestone(bytes32 _cid, uint16 _index) public nonReentrant {
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        milestones[_mid].releasedAmount = 0;

        uint _withdrawn;
        uint _toWithdraw;
        uint _inEscrow = _m.fundedAmount - _m.claimedAmount;
        if (_m.releasedAmount == 0 && _inEscrow > 0 && isAutoReleaseAvailable(_mid, _m.escrowDisputeManager, _m.autoReleasedAt)) {
            _toWithdraw = _inEscrow;
            _releaseMilestone(_mid, _toWithdraw, _toWithdraw, msg.sender);
        } else {
            _toWithdraw = _m.releasedAmount;
        }
        _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.payeeAccount, _toWithdraw);
        emit WithdrawnMilestone(_mid, _m.payeeAccount, _withdrawn); 
    }

    /**
     * @dev Refund payment token amount released by payee or arbiter.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payee.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     */
    function refundMilestone(bytes32 _cid, uint16 _index) public nonReentrant {
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        milestones[_mid].refundedAmount = 0;
        uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.refundAccount, _m.refundedAmount);
        emit RefundedMilestone(_mid, _m.refundAccount, _withdrawn); 
    }

    /**
     * @dev Add new milestone for the existing contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @param _paymentToken Payment token for amount.
     * @param _treasury Address where the escrow funds will be stored (farming?).
     * @param _payeeAccount Address where payment should be recieved, should be the same as payee or vesting contract address.
     * @param _refundAccount Address where payment should be refunded, should be the same as payer or sponsor.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Amount to be paid in payment token for the milestone.
     */
    function _registerMilestone(
        bytes32 _cid,
        uint16 _index,
        address _paymentToken,
        address _treasury,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint256 _autoReleasedAt,
        uint256 _amount
    ) internal {
        bool _isPayer = msg.sender == contracts[_cid].payer;
        require(msg.sender == contracts[_cid].payee || _isPayer, ERROR_NOT_DISPUTER);

        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        require(milestones[_mid].amount == 0, ERROR_MILESTONE_EXITS);
        _registerMilestoneStorage(
            _mid,
            _paymentToken,
            _treasury,
            _payeeAccount,
            _refundAccount,
            _escrowDisputeManager,
            _autoReleasedAt,
            _amount
        );
        emit NewMilestone(_cid, _index, _mid, _paymentToken, _escrowDisputeManager, _autoReleasedAt, _amount);
        if (_index > MILESTONE_INDEX_BASE) {
            emit ChildMilestone(_cid, _index, _index / MILESTONE_INDEX_BASE, _mid);
        }
    }

    /**
     * @dev Add new milestone for the existing contract.
     *
     * @param _mid UID of contract's milestone.
     * @param _paymentToken Address of ERC20 token to be used as payment currency in this escrow.
     * @param _treasury Address where milestone funds are kept in escrow.
     * @param _payeeAccount Address where payment should be recieved, should be the same as payer or vesting contract address.
     * @param _refundAccount Address where payment should be refunded, should be the same as payer or sponsor.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Amount to be paid in payment token for the milestone.
     */
    function _registerMilestoneStorage(
        bytes32 _mid,
        address _paymentToken,
        address _treasury,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint256 _autoReleasedAt,
        uint256 _amount
    ) internal {
        milestones[_mid] = Milestone({
            paymentToken: IERC20(_paymentToken),
            treasury: _treasury,
            payeeAccount: _payeeAccount,
            escrowDisputeManager: IEscrowDisputeManager(_escrowDisputeManager),
            refundAccount: _refundAccount,
            autoReleasedAt: _autoReleasedAt,
            amount: _amount,
            fundedAmount: 0,
            releasedAmount: 0,
            refundedAmount: 0,
            claimedAmount: 0,
            revision: 0
        });
    }

    /**
     * @dev Fund milestone with payment token, partial funding is possible.
     * To increase the maximum funding amount, just add a new milestone.
     *
     * Anyone can fund milestone, payment token should be approved for this contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone index.
     * @param _amountToFund amount of payment token to fund the milestone.
     * @return false if it wasn't possible to transfer tokens.
     */
    function _fundMilestone(bytes32 _cid, uint16 _index, uint _amountToFund) internal returns(bool) {
        bytes32 _mid = EscrowUtilsLib.genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        uint _fundedAmount = _m.fundedAmount;
        require(_amountToFund > 0 && _m.amount >= (_fundedAmount + _amountToFund), ERROR_FUNDED);
        _m.paymentToken.safeTransferFrom(msg.sender, address(this), _amountToFund);

        if (_m.treasury != address(this)) {
            _m.paymentToken.safeApprove(_m.treasury, _amountToFund);
            require(ITreasury(_m.treasury).registerClaim(
                _cid,
                _m.refundAccount,
                _m.payeeAccount,
                address(_m.paymentToken),
                _amountToFund
            ), ERROR_FUNDING);
        }
        milestones[_mid].fundedAmount += _amountToFund;
        emit FundedMilestone(_mid, msg.sender, _amountToFund);
        return true;
    }

    /**
     * @dev Release payment for withdrawal by payee.
     *
     * @param _mid UID of contract's milestone.
     * @param _totalReleased Total amount of released payment token.
     * @param _amountToRelease Amount of payment token to release.
     * @param _releaser Address which released (payer or arbiter).
     */
    function _releaseMilestone(bytes32 _mid, uint _totalReleased, uint _amountToRelease, address _releaser) internal {
        milestones[_mid].releasedAmount = _totalReleased;
        emit ReleasedMilestone(_mid, _releaser, _amountToRelease);
    }

    /**
     * @dev Release payment for refund by payer.
     *
     * @param _mid UID of contract's milestone.
     * @param _totalRefunded Total amount of refunded payment token.
     * @param _amountToRefund Amount of payment token to refund.
     * @param _refunder Address which refunded (payee or arbiter).
     */
    function _cancelMilestone(bytes32 _mid, uint _totalRefunded, uint _amountToRefund, address _refunder) internal {
        milestones[_mid].refundedAmount = _totalRefunded;
        emit CanceledMilestone(_mid, _refunder, _amountToRefund);
    }

    /**
     * @dev Transfer released funds to payee or refund account.
     *
     * Make sure to reduce milestone releasedAmount or refundAmount
     * by _withdrawAmount before calling this low-level method.
     *
     * @param _cid Contract's IPFS cid.
     * @param _mid UID of contract's milestone.
     * @param _m Milestone data.
     * @param _account Address where payment is withdrawn.
     * @param _withdrawAmount Amount of released or refunded payment token.
     * @return withdrawn amount
     */
    function _withdrawMilestone(bytes32 _cid, bytes32 _mid, Milestone memory _m, address _account, uint _withdrawAmount) internal returns(uint) {
        uint _leftAmount = _m.fundedAmount - _m.claimedAmount;
        if (_leftAmount < _withdrawAmount) _withdrawAmount = _leftAmount;
        require(_withdrawAmount > 0, ERROR_NO_MONEY);

        milestones[_mid].claimedAmount = _m.claimedAmount + _withdrawAmount;
        if (_m.treasury == address(this)) {
            _m.paymentToken.safeTransfer(_account, _withdrawAmount);
        } else {
            require(ITreasury(_m.treasury).requestWithdraw(
                _cid,
                _account,
                address(_m.paymentToken),
                _withdrawAmount
            ), ERROR_FUNDING);
        }
        return _withdrawAmount;
    }

    /**
     * @dev Check if auto release of milestone funds is available
     * and maturity date has been reached.
     *
     * Also checks if there were no active or past disputes for this milestone.
     *
     * @param _mid UID of contract's milestone.
     * @param _escrowDisputeManager Smart contract which manages the disputes.
     * @param _autoReleasedAt UNIX timestamp for maturity date.
     * @return true if funds can be withdrawn.
     */
    function isAutoReleaseAvailable(
        bytes32 _mid,
        IEscrowDisputeManager _escrowDisputeManager,
        uint _autoReleasedAt
    ) public view returns (bool) {
        return _autoReleasedAt > 0 && block.timestamp > _autoReleasedAt
            && !_escrowDisputeManager.hasSettlementDispute(_mid)
            && _escrowDisputeManager.resolutions(_mid) == EMPTY_INT;
    }
}
