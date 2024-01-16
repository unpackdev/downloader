// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaUnitTracker.sol";


/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitRegister
 * @notice Manages registration of all transactions on platform.
 */
contract MetaUnitTracker is IMetaUnitTracker {
    address private _owner_of;
    Transaction[] private _transactions;
    mapping(address => bool) private _is_sale_contract_address;
    mapping(address => uint256) private _resales_sum_by_user_address;
    mapping(address => uint256) private _quantity_of_transaction_by_user_address;

    /**
     * @dev setup owner of this contract.
     */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
    }

    /**
     * @dev helps MetaUnit receive data about sales and resales.
     * @param eth_address_ address which sold NFT on platform.
     * @param value_ price which he received form this order.
     */
    function track(address eth_address_, uint256 value_) public {
        require(_is_sale_contract_address[msg.sender], "No permissions to this function");
        _transactions.push(Transaction(eth_address_, value_, block.timestamp));
        _resales_sum_by_user_address[eth_address_] += value_;
        _quantity_of_transaction_by_user_address[eth_address_] += 1;
    }

    /**
     * @dev setup sale contracts.
     */
    function setSaleContractsAddresses(address[] memory contract_addresses_, bool action_) public {
        require(_owner_of == msg.sender, "Permission denied!");
        for (uint256 i = 0; i < contract_addresses_.length; i++) {
            _is_sale_contract_address[contract_addresses_[i]] = action_;
        }
    }

    /**
     * @dev helps us receive sum of resales 
     * @param eth_address_ address of user which resales should be retrieved.
     * @return resales_sum sum of resales for specified user address.
     */
    function getUserResalesSum(address eth_address_) public view returns (uint256) {
        return _resales_sum_by_user_address[eth_address_];
    }

    /**
     * @dev helps us receive quantity of transactions 
     * @param eth_address_ address of user which transactions should be retrieved.
     * @return quantity quantity of transactions for specified user address.
     */
    function getUserTransactionQuantity(address eth_address_) public view returns (uint256) {
        return _quantity_of_transaction_by_user_address[eth_address_];
    }

    /**
     * @dev helps us retrive all transactions.
     * @return transactions all transactions.
     */
    function getTransactions() public view returns (Transaction[] memory transactions) {
        return _transactions;
    }

    /**
     * @dev helps us retrive all transactions in defined periods.
     */
    function getTransactionsForPeriod(uint256 from_, uint256 to_) public view returns (address[] memory, uint256[] memory) {
        uint256 len = 0;
        for (uint256 i = 0; i < _transactions.length; i ++) {
            if (_transactions[i].timestamp > from_ && _transactions[i].timestamp < to_) {
                len += 1;
            }
        }
        require(len > 0, "No transactions in this period");
        address[] memory addresses = new address[](len);
        uint256[] memory values = new uint256[](len);
        uint256 counter = 0;
        for (uint256 i = 0; i < _transactions.length; i ++) {
            if (_transactions[i].timestamp > from_ && _transactions[i].timestamp < to_) {
                addresses[counter] = _transactions[i].owner_of;
                values[counter] = _transactions[i].value;
                counter +=1;
            }
        }
        return (addresses, values);
    }
}
