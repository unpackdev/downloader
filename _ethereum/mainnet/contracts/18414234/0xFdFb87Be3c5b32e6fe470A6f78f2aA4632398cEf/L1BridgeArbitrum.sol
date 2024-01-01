// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

import "./IInbox.sol";
import "./IL1GatewayRouter.sol";

contract L1BridgeArbitrum is Ownable {
    /// @notice bips
    uint256 public FEE;

    event EtherDeposit(address from, address to, uint256 amount);
    event TokenDeposit(address from, address to, address l1Token, address l2Token, uint256 amount);

    constructor(uint256 _fee) Ownable() {
        FEE = _fee;
    }

    function initiateEtherDeposit(
        address payable _inbox,
        address _to,
        uint256 maxSubmissionCost,
        uint256 gasLimit,
        uint256 maxFeePerGas
    ) public payable {
        uint256 _amount = msg.value - maxSubmissionCost - gasLimit * maxFeePerGas;
        uint256 _fee = _amount * FEE / 10_000;
        uint256 _amountSubFee = _amount - _fee;
        uint256 _valueSubFee = msg.value - _fee;

        IInbox(_inbox).createRetryableTicket{value: _valueSubFee}(
            _to,
            _amountSubFee,
            maxSubmissionCost,
            _to, // excessFeeRefundAddress
            _to, // callValueRefundAddress
            gasLimit,
            maxFeePerGas,
            bytes("")
        );

        emit EtherDeposit(msg.sender, _to, _amount);
    }

    function initiateERC20Deposit(
        address payable _router,
        address _gateway,
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) public payable {
        IERC20 erc20 = IERC20(_l1Token);
        require(erc20.transferFrom(msg.sender, address(this), _amount), "!transferFrom");

        uint256 _fee = _amount * FEE / 10_000;
        uint256 _amountSubFee = _amount - _fee;

        erc20.approve(_gateway, _amountSubFee);
        IL1GatewayRouter(_router).outboundTransferCustomRefund{value: msg.value}(
            _l1Token, // _l1Token
            _to, // _refundTo
            _to, // _to
            _amountSubFee, // _amount
            _maxGas, // _maxGas
            _gasPriceBid, // _gasPriceBid,
            abi.encode(_maxSubmissionCost, bytes("")) // _data
        );
        erc20.approve(_gateway, 0);

        emit TokenDeposit(msg.sender, _to, _l1Token, _l2Token, _amountSubFee);
    }

    function withdrawEtherFees() public onlyOwner {
        (bool sent, bytes memory data) = owner().call{value: payable(address(this)).balance}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawERC20Fees(address _token) public onlyOwner {
        IERC20 erc20 = IERC20(_token);
        bool sent = erc20.transfer(owner(), erc20.balanceOf(address(this)));
        require(sent, "Failed to send token");
    }

    function setFee(uint256 _fee) public onlyOwner {
        FEE = _fee;
    }
}
