// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";

contract GenArtPaymentProxy {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(address payee, uint256 amount);
    mapping(address => mapping(uint256 => uint256)) public receivedTokens;
    Payment private _payment;

    constructor(address[] memory payeeAddresses, uint256[] memory payeeShares) {
        require(
            payeeAddresses.length == payeeShares.length,
            "GenArtPaymentProxy: Invalid payees"
        );
        _payment = Payment(payeeAddresses, payeeShares);
    }

    function withdrawTokens(address tokenAddress, uint256 payeeIndex)
        public
        payable
    {
        address payee = _payment.payees[payeeIndex];
        require(
            payee == msg.sender,
            "GenArtPaymentProxy: Sender must be payee"
        );
        uint256 totalShares = getTotalShares();
        uint256 totalTokenBalance = getTotalTokenBalance(tokenAddress);
        uint256 tokenAmount = (totalTokenBalance *
            _payment.shares[payeeIndex]) /
            totalShares -
            receivedTokens[tokenAddress][payeeIndex];
        require(tokenAmount > 0, "GenArtPaymentProxy: zero balance");
        receivedTokens[tokenAddress][payeeIndex] += tokenAmount;
        IERC20(tokenAddress).transfer(payee, tokenAmount);
        emit IncomingPayment(payee, tokenAmount);
    }

    /**
     *@dev Get total shares
     */
    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        for (uint8 i; i < _payment.shares.length; i++) {
            unchecked {
                totalShares += _payment.shares[i];
            }
        }
        return totalShares;
    }

    function getTotalTokenBalance(address tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 totalTokenBalance = IERC20(tokenAddress).balanceOf(
            address(this)
        );
        for (uint8 i; i < _payment.payees.length; i++) {
            unchecked {
                totalTokenBalance += receivedTokens[tokenAddress][i];
            }
        }
        return totalTokenBalance;
    }

    function updatePayee(uint256 payeeIndex, address newPayee) public {
        address oldPayee = _payment.payees[payeeIndex];
        require(
            oldPayee == msg.sender,
            "GenArtPaymentProxy: sender is not current payee"
        );
        _payment.payees[payeeIndex] = newPayee;
    }

    receive() external payable {
        uint256 totalShares = getTotalShares();
        for (uint8 i; i < _payment.payees.length; i++) {
            address payee = _payment.payees[i];
            uint256 ethAmount = (msg.value * _payment.shares[i]) / totalShares;
            payable(payee).transfer(ethAmount);
            emit IncomingPayment(payee, ethAmount);
        }
    }
}
