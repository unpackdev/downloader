// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract CRRevenueSharing {
    address public marketingFund;
    address public developmentFund;
    address public owner;

    struct Holder {
        address holderAddress;
        uint256 amount;
    }

    event OwnershipRenounced(address indexed previousOwner);

    event AddedToCR(address indexed payer, uint256 amount, address token);

    event RevenueDistributed(uint256 totalPayment, uint256 successfulPayments);
    event PaymentSuccess(address holderAddress, uint256 amount);
    event PaymentFailed(address holderAddress, uint256 amount);

    constructor() {
        marketingFund = 0x8dF75F0936f8BFbc7117726097530677A9F7d604;
        developmentFund = 0x0E6337d6a0Cf896E56147B3Cd3A0589613991EF1;
        owner = msg.sender;
    }

    function addToCR(address tokenAddress) external payable {
        require(msg.value > 0, 'Payment should be greater than 0');

        uint256 marketingFundPayment = (msg.value * 40) / 100;
        uint256 developmentFundPayment = (msg.value * 10) / 100;

        payable(marketingFund).transfer(marketingFundPayment);
        payable(developmentFund).transfer(developmentFundPayment);

        emit AddedToCR(msg.sender, msg.value, tokenAddress);
    }


    function distributeRevenue(
        Holder[] memory holders
    ) external onlyDevelopmentFund {
        uint256 totalPayment = 0;
        uint256 successfulPayments = 0;

        for (uint256 i = 0; i < holders.length; i++) {
            Holder memory holder = holders[i];
            address payable holderAddress = payable(holder.holderAddress);

            if (
                holderAddress != address(0) &&
                holder.amount > 0 &&
                holder.amount <= address(this).balance
            ) {
                bool success = holderAddress.send(holder.amount);

                if (success) {
                    emit PaymentSuccess(holder.holderAddress, holder.amount);
                    totalPayment += holder.amount;
                    successfulPayments++;
                } else {
                    emit PaymentFailed(holder.holderAddress, holder.amount);
                }
            } else {
                emit PaymentFailed(holder.holderAddress, holder.amount);
            }
        }

        emit RevenueDistributed(totalPayment, successfulPayments);
    }

    modifier onlyDevelopmentFund() {
        require(msg.sender == developmentFund, 'Only the Development Fund can call this function.');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Caller is not the owner');
        _;
    }

    function renounceOwnership() public {
        require(owner == msg.sender, 'Not the contract owner');
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}