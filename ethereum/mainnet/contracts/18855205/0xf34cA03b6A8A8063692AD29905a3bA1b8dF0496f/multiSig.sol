// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    address public saltsAddress;
    address public yardAddress;

    struct Transaction {
        address target;
        bytes data;
        bool executed;
        uint confirmations;
    }

   struct OwnerChange {
    address owner;
    bool isAddition; // true for addition, false for removal
    bool executed;
    uint confirmations;
}

    struct RequirementChange {  
    uint requiredNew;
    bool executed;
    uint confirmations;
}

    RequirementChange[] public requirementChanges;

    OwnerChange[] public ownerChanges;

    Transaction[] public transactions;


    mapping(uint => mapping(address => bool)) public isConfirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    function submitSetdevWallet(address _addr) public onlyOwner {
        bytes memory data = abi.encodeWithSignature("setdevWallet(address)", _addr);
        _submitTransaction(saltsAddress, data);
    }

    function submitTransferRewardToYard() public onlyOwner {
        bytes memory data = abi.encodeWithSignature("transferRewardToYard()");
        _submitTransaction(saltsAddress, data);
    }

    function submitUpdateTxLimit(uint256 _trnx) public onlyOwner {
        bytes memory data = abi.encodeWithSignature("updateTxLimit(uint256)", _trnx);
        _submitTransaction(saltsAddress, data);
    }

    function submitIncludeExcludeFromFee(address arg1, bool arg2) public onlyOwner {
        bytes memory data = abi.encodeWithSignature("includeAndExcludeFromFee(address,bool)", arg1, arg2);
        _submitTransaction(saltsAddress, data);
    }

   //Yard contract call
    function submitsetRewardsDuration(uint256 arg1) public onlyOwner {
        bytes memory data = abi.encodeWithSignature("setRewardsDuration(uint256)", arg1);
        _submitTransaction(yardAddress, data);
    }


    function submitUpdateInitialBoost(uint256 arg1) public onlyOwner {
        bytes memory data = abi.encodeWithSignature("updateInitialBoost(uint256)", arg1);
        _submitTransaction(yardAddress, data);
    }

        function submitUpdateBoost(uint256 arg1) public onlyOwner {
        bytes memory data = abi.encodeWithSignature("updateBoost(uint256)", arg1);
        _submitTransaction(yardAddress, data);
    }



    function _submitTransaction(address _target, bytes memory _data) private {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            target: _target,
            data: _data,
            executed: false,
            confirmations: 0
        }));
        emit SubmitTransaction(msg.sender, txIndex, _target, _data);
    }

    function _submitOwner(address _owner) public{

    }



    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        transaction.confirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.confirmations >= required, "Insufficient confirmations");
        transaction.executed = true;
        (bool success, ) = transaction.target.call(transaction.data);
        require(success, "Transaction execution failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }


//-----------------------To add or remove owner------------------------//

function submitOwnerChange(address _owner, bool _isAddition) public onlyOwner {
    uint changeIndex = ownerChanges.length;
    ownerChanges.push(OwnerChange({
        owner: _owner,
        isAddition: _isAddition,
        executed: false,
        confirmations: 0
    }));
    emit SubmitOwnerChange(msg.sender, changeIndex, _owner, _isAddition);
}

function confirmOwnerChange(uint _changeIndex) public onlyOwner {
    require(_changeIndex < ownerChanges.length, "Owner change does not exist");
    OwnerChange storage change = ownerChanges[_changeIndex];
    require(!change.executed, "Owner change already executed");
    require(!isConfirmed[_changeIndex][msg.sender], "Owner change already confirmed");

    change.confirmations += 1;
    isConfirmed[_changeIndex][msg.sender] = true;
    emit ConfirmOwnerChange(msg.sender, _changeIndex);
}

function executeOwnerChange(uint _changeIndex) public onlyOwner {
    require(_changeIndex < ownerChanges.length, "Owner change does not exist");
    OwnerChange storage change = ownerChanges[_changeIndex];
    require(!change.executed, "Owner change already executed");
    require(change.confirmations >= required, "Insufficient confirmations");

    change.executed = true;
    if (change.isAddition) {
        require(!isOwner[change.owner], "Address is already an owner");
        isOwner[change.owner] = true;
        owners.push(change.owner);
    } else {
        require(isOwner[change.owner], "Address is not an owner");
        isOwner[change.owner] = false;
        for (uint i = 0; i < owners.length - 1; i++) {
            if (owners[i] == change.owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
    }

    emit ExecuteOwnerChange(msg.sender, _changeIndex);
}


//----------------For minimum required sig----------------//

function submitRequirementChange(uint _requiredNew) public onlyOwner {
    require(_requiredNew > 0 && _requiredNew <= owners.length, "Invalid number of required confirmations");

    uint changeIndex = requirementChanges.length;
    requirementChanges.push(RequirementChange({
        requiredNew: _requiredNew,
        executed: false,
        confirmations: 0
    }));
    emit SubmitRequirementChange(msg.sender, changeIndex, _requiredNew);
}

function confirmRequirementChange(uint _changeIndex) public onlyOwner {
    require(_changeIndex < requirementChanges.length, "Requirement change does not exist");
    RequirementChange storage change = requirementChanges[_changeIndex];
    require(!change.executed, "Requirement change already executed");
    require(!isConfirmed[_changeIndex][msg.sender], "Requirement change already confirmed");

    change.confirmations += 1;
    isConfirmed[_changeIndex][msg.sender] = true;
    emit ConfirmRequirementChange(msg.sender, _changeIndex);
}

function executeRequirementChange(uint _changeIndex) public onlyOwner {
    require(_changeIndex < requirementChanges.length, "Requirement change does not exist");
    RequirementChange storage change = requirementChanges[_changeIndex];
    require(!change.executed, "Requirement change already executed");
    require(change.confirmations >= required, "Insufficient confirmations");

    change.executed = true;
    required = change.requiredNew;
    
    emit ExecuteRequirementChange(msg.sender, _changeIndex);
}





function changeAddress(address _salts, address _yard) public onlyOwner{
    saltsAddress = _salts;
    yardAddress = _yard;

}


 event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed target, bytes data);
 event ConfirmTransaction(address indexed owner, uint indexed txIndex);
 event ExecuteTransaction(address indexed owner, uint indexed txIndex);

 event SubmitOwnerChange(address indexed owner, uint indexed changeIndex, address indexed targetOwner, bool isAddition);
 event ConfirmOwnerChange(address indexed owner, uint indexed changeIndex);
 event ExecuteOwnerChange(address indexed owner, uint indexed changeIndex);
 
 event SubmitRequirementChange(address indexed owner, uint indexed changeIndex, uint requiredNew);
 event ConfirmRequirementChange(address indexed owner, uint indexed changeIndex);
 event ExecuteRequirementChange(address indexed owner, uint indexed changeIndex);


}
