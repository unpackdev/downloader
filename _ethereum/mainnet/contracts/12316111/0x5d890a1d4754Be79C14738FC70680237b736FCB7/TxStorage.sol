// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./GovernanceOwnable.sol";

abstract contract TxStorage is GovernanceOwnable{
	using SafeMath for uint;

    uint private expirePeriod = 7776000;

    struct Transaction {
		uint ammount;		
		uint price;	
        uint timestamp;
        uint expireTimeStamp;
        bool closed;
	}


    mapping(address => mapping (uint => Transaction)) internal transactionsHistory;
    mapping(address => uint) internal index;
    address [] public userList;

    function setExparePeriud(uint _epirePeriod) external onlyGovernance payable{
        expirePeriod = _epirePeriod;
    }

    function transactionAdd(uint ammount, uint price) internal{
       uint timestamp = block.timestamp;
       _transactionAdd(msg.sender, ammount, price, timestamp, timestamp.add(expirePeriod));
    }

    function closedTransaction(address to, uint _index) internal {
         transactionsHistory[to][_index].closed = true;
    }

    function _transactionAdd(address to, uint ammount, uint price, uint timestamp, uint expireTimeStamp) internal {
        if (index[to]==0){
            userList.push(to);
        }
        index[to] +=1;
        transactionsHistory[to][index[to]] = Transaction(ammount, price, timestamp, expireTimeStamp, false);
    }


    function amountOfActualTransactions() public view returns (uint result) {
        for (uint i = 0; i < userList.length; i++) {
            for (uint a = 0; a <= index[userList[i]]; a++) {
               if (transactionsHistory[userList[i]][a].expireTimeStamp > block.timestamp){
                   result += transactionsHistory[userList[i]][a].price;
               }
            }           
        }
        return result;
    }

    function getTransaction(address to, uint _index) public view returns (uint ammount, uint price, uint timestamp, uint expireTimeStamp, bool closed) {
       require(transactionsHistory[to][_index].timestamp != 0 , "INDEX OUT OF RANGE");
       ammount = transactionsHistory[to][_index].ammount;
       price =transactionsHistory[to][_index].price;
       timestamp = transactionsHistory[to][_index].timestamp;
       expireTimeStamp = transactionsHistory[to][_index].expireTimeStamp;
       closed = transactionsHistory[to][_index].closed;
    }


    function checkTrransaction(address to, uint _index) internal view{
       Transaction memory transaction = transactionsHistory[to][_index];
       require(transaction.timestamp != 0 , "INDEX OUT OF RANGE");
       require(!transaction.closed , "THE TRANSACTION IS CLOSED");
       require(block.timestamp <= transaction.expireTimeStamp, "TRANSACTION TIME EXPIRED");
    }


    function getTransactionlastIndex(address to) external view returns (uint ) {
        return index[to];
    }

}