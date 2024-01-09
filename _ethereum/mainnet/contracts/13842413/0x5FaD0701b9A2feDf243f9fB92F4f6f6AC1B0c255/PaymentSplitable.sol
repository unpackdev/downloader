// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./BaseCollection.sol";

contract PaymentSplitable is BaseCollection {
    uint256 public constant TOTAL_SHARES = 1e18; // 100% // to avoid rounding errors
    uint256 public constant MAX_PAYEES = 6; // maximum number payees that can be added
    uint256 public NFTIFY_SHARES; // share of NFTify
    address public NFTIFY_RECEIVER_ADDRESS; // address of NFTIFY to receive shares

    struct Payee {
        uint256 shares;
        uint256 amountReleased;
    }

    uint256 public totalReleased; // total amount of payment release

    // Payee State
    mapping(address => Payee) public payees; // mapping of address of payee to Payee struct
    mapping(uint256 => address) public payeeAddress; // mapping of payeeId to payee address
    uint256 public totalPayees; // total number of payees

    /**
     * @dev setup payment splitting details for collection
     * @param _nftify address of nftify beneficicary address
     * @param _nftifyShares percentage share of nftfify, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     * @param _payees array of payee address
     * @param _shares array of payee shares, index for both arrays should match for a payee
     */
    function setupPaymentSplitter(
        address _nftify,
        uint256 _nftifyShares,
        address[] memory _payees,
        uint256[] memory _shares
    ) internal {
        require(_nftify != address(0), "PS:001");
        NFTIFY_RECEIVER_ADDRESS = _nftify;
        NFTIFY_SHARES = _nftifyShares;
        _setPayees(_payees, _shares);
    }

    /**
     * @dev set new payees before releasing any payment
     * @param _payees array of payee address
     * @param _shares array of payee shares, index for both arrays should match for a payee
     */
    function setPayees(address[] memory _payees, uint256[] memory _shares)
        external
        onlyOwner
    {
        require(totalReleased == 0, "PS:002");
        _setPayees(_payees, _shares);
    }

    /**
     * @dev private method to set new payees before releasing any payment
     * @param _payees array of payee address
     * @param _shares array of payee shares, index for both arrays should match for a payee
     */
    function _setPayees(address[] memory _payees, uint256[] memory _shares)
        private
    {
        require(_payees.length == _shares.length, "PS:003");
        uint256 totalSharesAdded;
        if (totalPayees > _payees.length) {
            for (uint256 i = _payees.length; i < totalPayees; i++) {
                delete payees[payeeAddress[i]];
                delete payeeAddress[i];
            }
        }
        for (uint256 i; i < _payees.length; i++) {
            payeeAddress[i] = _payees[i];
            payees[_payees[i]] = Payee(_shares[i], 0);
            totalSharesAdded += _shares[i];
        }
        payeeAddress[_payees.length] = NFTIFY_RECEIVER_ADDRESS;
        payees[NFTIFY_RECEIVER_ADDRESS] = Payee(NFTIFY_SHARES, 0);
        totalPayees = _payees.length + 1;
        require(totalSharesAdded + NFTIFY_SHARES == TOTAL_SHARES, "PS:004");
    }

    /**
     * @dev release payment to a payee
     * @param _amount amount that is to be released
     */
    function release(uint256 _amount) external {
        address _payee = msg.sender;
        require(payees[_payee].shares > 0, "PS:005");
        uint256 payment = pendingPayment(_payee);
        require(payment != 0 && payment >= _amount, "PS:006");
        payees[_payee].amountReleased += _amount;
        totalReleased += _amount;
        payable(_payee).transfer(_amount);
    }

    /**
     * @dev view method to get the pending amount of a payee
     * @param account payee address
     * @return pending amount
     */
    function pendingPayment(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased;
        return
            (totalReceived * payees[account].shares) /
            TOTAL_SHARES -
            payees[account].amountReleased;
    }
}
