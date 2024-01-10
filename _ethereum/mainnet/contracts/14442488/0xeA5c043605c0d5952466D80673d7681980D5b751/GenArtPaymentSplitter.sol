// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtPaymentSplitter.sol";

contract GenArtPaymentSplitter is GenArtAccess, IGenArtPaymentSplitter {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(
        address collection,
        uint256 paymentType,
        address payee,
        uint256 amount
    );

    mapping(address => uint256) public _balances;
    mapping(address => Payment) private _payments;
    mapping(address => Payment) private _paymentsRoyalties;

    /**
     * @dev Throws if called by any account other than the owner, admin or collection contract.
     */
    modifier onlyCollectionContractOrAdmin(bool isCollection) {
        address sender = _msgSender();
        require(
            isCollection || (owner() == sender) || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitter: invalid arguments"
        );

        _payments[collection] = Payment(payees, shares);
    }

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitter: invalid arguments"
        );
        _paymentsRoyalties[collection] = Payment(payees, shares);
    }

    function sanityCheck(address collection, uint8 paymentType) internal view {
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        require(
            payment.payees.length > 0,
            "GenArtPaymentSplitter: payment not found for collection"
        );
    }

    function splitPayment(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(_payments[msg.sender].payees.length > 0)
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 0);
        for (uint8 i; i < _payments[collection].payees.length; i++) {
            address payee = _payments[collection].payees[i];
            uint256 ethAmount = (msg.value * _payments[collection].shares[i]) /
                totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 ethAmount = (msg.value *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 1, payee, ethAmount);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentsRoyalties
     */
    function getTotalSharesOfCollection(address collection, uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        sanityCheck(collection, paymentType);
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) public override {
        uint256 amount = _balances[account];
        require(amount > 0, "GenArtPaymentSplitter: no funds to release");
        _balances[account] = 0;
        payable(account).transfer(amount);
    }

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) public override {
        sanityCheck(collection, paymentType);
        Payment storage payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        address oldPayee = payment.payees[payeeIndex];
        require(
            oldPayee == _msgSender(),
            "GenArtPaymentSplitter: sender is not current payee"
        );
        payment.payees[payeeIndex] = newPayee;
    }

    function getBalanceForAccount(address account)
        public
        view
        returns (uint256)
    {
        return _balances[account];
    }

    function emergencyWithdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}
