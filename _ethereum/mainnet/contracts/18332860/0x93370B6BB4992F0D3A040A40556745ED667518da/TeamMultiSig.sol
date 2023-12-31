// SPDX-License-Identifier: MIT
pragma solidity = 0.8.19;

/* MULTISIG WALLET CONTRACT
   - Max number of owners is 5. Then 4 confirmations are required to confirm a transaction.
   - Min number of owners is 4. Then 3 confirmations are required to confirm a transaction.
*/
contract TeamMultiSig {
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        bytes data
    );
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RejectTransaction(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    uint8 public numConfirmationsRequired = 4; // 4 initially, can be modified to 3
    uint256 public constant NUM_REJECTIONS_REQUIRED = 2;

    struct Transaction {
        address to;
        address initiatorOwner;
        bytes data;
        bool executed;
        bool rejected;
        uint8 numConfirmations;
        uint8 numRejections;
    }

    // mapping: tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(uint256 => mapping(address => bool)) public isRejected;

    mapping(address => bool) public isOwner;
    address[] public owners;
    Transaction[] private transactions;

    modifier onlyWallet() {
        require(msg.sender == address(this), "not wallet");
        _;
    }
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notFullRejected(uint256 _txIndex) {
        require(!transactions[_txIndex].rejected, "tx already rejected");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed by user");
        _;
    }

    modifier notRejected(uint256 _txIndex) {
        require(!isRejected[_txIndex][msg.sender], "tx already rejected by user");
        _;
    }

    constructor(address[] memory _owners) {
        require(_owners.length == 5, "5 owners required"); // 5 wallets initially

        for (uint256 i = 0; i < _owners.length; ) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
            unchecked {
                i++;
            }
        }
    }

    /* 
    Allows to add a new owner. Transaction has to be sent by wallet.
    @param owner: Address of new owner.
    */
    function addOwner(address owner) external onlyWallet {
        require(!isOwner[owner] && owners.length == 4, "Already owner or MAX");
        isOwner[owner] = true;
        owners.push(owner);
        numConfirmationsRequired = 4;
        emit OwnerAdded(owner);
    }

    /*
    Allows to remove a owner. Transaction has to be sent by wallet.
    @param owner: Address of owner to be removed.
    */
    function removeOwner(address owner) external onlyWallet {
        require(isOwner[owner] && owners.length == 5, "Not owner or MIN");
        isOwner[owner] = false;
        numConfirmationsRequired = 3;
        for (uint256 i = 0; i < owners.length; ) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
            unchecked {
                i++;
            }
        }
        emit OwnerRemoved(owner);
    }

    /*
    Allows to submit a new transaction. Transaction has to be sent by an owner.
    @param _to: Target address.
    @param _data: Transaction data.
    */
    function submitTransaction(
        address _to,
        bytes memory _data
    ) external onlyOwner {

        transactions.push(
            Transaction({
                to: _to,
                initiatorOwner: msg.sender,
                data: _data,
                executed: false,
                rejected: false,
                numConfirmations: 1,
                numRejections: 0
            })
        );
        // Get the index of the transaction that has been pushed
        uint256 txIndex = transactions.length - 1;
        
        isConfirmed[txIndex][msg.sender] = true;

        emit SubmitTransaction(msg.sender, txIndex, _to, _data);
        emit ConfirmTransaction(msg.sender, txIndex);
    }

    /*
    Allows to confirm a pending transaction. Transaction has to be sent by an owner.
    @param _txIndex: Transaction index.
    */
    function confirmTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        notRejected(_txIndex)
        notFullRejected(_txIndex)
    {
        unchecked {
            transactions[_txIndex].numConfirmations += 1;
        }
        
        isConfirmed[_txIndex][msg.sender] = true;

        // Automatically execute the transaction once the num of required confirmations is reached
        if (transactions[_txIndex].numConfirmations == numConfirmationsRequired) {
            executeTransaction(_txIndex);
        }

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /*
    Allows to reject a pending transaction. Transaction has to be sent by an owner.
    @param _txIndex: Transaction index.
    */
    function rejectTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        notRejected(_txIndex)
        notFullRejected(_txIndex)
    {   
        unchecked {
            transactions[_txIndex].numRejections += 1;
        }
        isRejected[_txIndex][msg.sender] = true;

        // Automatically reject the transaction once the num of required rejections is reached
        if (transactions[_txIndex].numRejections == NUM_REJECTIONS_REQUIRED)
            transactions[_txIndex].rejected = true;

        emit RejectTransaction(msg.sender, _txIndex);
    }

    /*
    Allows to execute a confirmed transaction. Last confirmation has to be sent by an owner through the confirmTransaction() function.
    @param _txIndex: Transaction index.
    */
    function executeTransaction(uint256 _txIndex)
        internal
    {
        transactions[_txIndex].executed = true;

        (bool success, ) = transactions[_txIndex].to.call{value: 0}(
            transactions[_txIndex].data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function isConfirmedOrRejected(uint256 _txIndex, address _owner)
        external
        view
        returns (bool, bool)
    {
        return (isConfirmed[_txIndex][_owner], isRejected[_txIndex][_owner]);
    }

    function getTransaction(uint256 _txIndex)
        external
        view
        returns (
            address to,
            address initiatorOwner,
            bytes memory data,
            bool executed,
            bool rejected,
            uint8 numConfirmations,
            uint8 numRejections
        )
    {
        Transaction memory transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.initiatorOwner,
            transaction.data,
            transaction.executed,
            transaction.rejected,
            transaction.numConfirmations,
            transaction.numRejections
        );
    }
}