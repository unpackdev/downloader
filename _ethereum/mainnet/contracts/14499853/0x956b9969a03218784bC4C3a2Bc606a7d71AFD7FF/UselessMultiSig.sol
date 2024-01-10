// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./UselessNFT.sol";


contract UselessMultiSig {

    event Confirmation(uint256 indexed tokenId, uint256 indexed transactionId);
    event Revocation(uint256 indexed tokenId, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId, string error);
    event RequirementChange(uint256 required);
    event ReceiveEther(address indexed sender, uint amount);

    // ============ Constants ============

    uint256 constant public MAX_OWNER_COUNT = 50;
    address constant ADDRESS_ZERO = address(0x0);

    // ============ Storage ============

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(uint256 => bool)) public confirmations;
    UselessNFT public uselessNft;
    uint256 public required;
    uint256 public transactionCount;

    // ============ Structs ============

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    // ============ Modifiers ============

    modifier onlyWallet() {
        require(msg.sender == address(this), "only this council can call");
        _;
    }

    modifier requireIsValidOwnerAndCouncilIsSetUp(
        uint _tokenId
    ) {
        require(
            !uselessNft.isSaleOpen() && uselessNft.randomNumber() != 0,
            "council is not set up yet"
        );
        require(uselessNft.ownerOf(_tokenId) == msg.sender, "not a valid owner");
        require(uselessNft.getTier(_tokenId) <= UselessLibrary.Tier.TIER_ONE, "owner is not useless enough");
        _;
    }

    modifier transactionExists(
        uint256 transactionId
    ) {
        require(transactions[transactionId].destination != ADDRESS_ZERO, "useless transaction does not exist");
        _;
    }

    modifier confirmed(
        uint256 transactionId,
        uint256 tokenId
    ) {
        require(confirmations[transactionId][tokenId], "useless transaction is not confirmed by this NFT");
        _;
    }

    modifier notConfirmed(
        uint256 transactionId,
        uint256 tokenId
    ) {
        require(!confirmations[transactionId][tokenId], "useless transaction is already confirmed");
        _;
    }

    modifier notExecuted(
        uint256 transactionId
    ) {
        require(!transactions[transactionId].executed, "useless transaction is already executed");
        _;
    }

    modifier notNull(
        address _address
    ) {
        require(_address != ADDRESS_ZERO, "address is useless");
        _;
    }

    modifier validRequirement(
        uint256 ownerCount,
        uint256 _required
    ) {
        require(
            _required <= ownerCount && _required != 0 && ownerCount != 0,
            "requirements are useless"
        );
        _;
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets NFT contract and required number of confirmations.
     *
     * @param  _uselessNft  Address of the Useless NFT contract.
     */
    constructor(
        address payable _uselessNft
    )
    public
    {
        uselessNft = UselessNFT(_uselessNft);
        // when the council is created, post sale, there will be 11 signers. Initialize it simply at majority required
        // to execute transactions
        required = 6;
    }

    receive() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

    function ownerTokenIds() public view returns (uint[] memory) {
        return uselessNft.getCouncilIds();
    }

    function owners() public view returns (address[] memory) {
        UselessNFT _uselessNFT = uselessNft;
        uint[] memory tokenIds = _uselessNFT.getCouncilIds();
        address[] memory _owners = new address[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            _owners[i] = _uselessNFT.ownerOf(tokenIds[i]);
        }
        return _owners;
    }

    /**
     * Allows to change the number of required confirmations. Transaction has to be sent by wallet.
     *
     * @param  _required  Number of required confirmations.
     */
    function changeRequirement(
        uint256 _required
    )
    public
    onlyWallet
    validRequirement(owners().length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /**
     * Allows an owner to submit and confirm a transaction.
     *
     * @param  tokenId      Token ID of one of the owners of the UselessNFT contract.
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function submitTransaction(
        uint256 tokenId,
        address destination,
        uint256 value,
        bytes memory data
    )
    public
    returns (uint256)
    {
        uint256 transactionId = _addTransaction(destination, value, data);
        confirmTransaction(tokenId, transactionId);
        return transactionId;
    }

    /**
     * Allows an owner to confirm a transaction.
     */
    function confirmTransaction(
        uint256 tokenId,
        uint256 transactionId
    )
    public
    requireIsValidOwnerAndCouncilIsSetUp(tokenId)
    transactionExists(transactionId)
    notConfirmed(transactionId, tokenId)
    {
        confirmations[transactionId][tokenId] = true;
        emit Confirmation(tokenId, transactionId);
        executeTransaction(tokenId, transactionId);
    }

    /**
     * Allows an owner to revoke a confirmation for a transaction.
     */
    function revokeConfirmation(
        uint256 tokenId,
        uint256 transactionId
    )
    public
    requireIsValidOwnerAndCouncilIsSetUp(tokenId)
    confirmed(transactionId, tokenId)
    notExecuted(transactionId)
    {
        confirmations[transactionId][tokenId] = false;
        emit Revocation(tokenId, transactionId);
    }

    /**
     * Allows an owner to execute a confirmed transaction.
     */
    function executeTransaction(
        uint256 tokenId,
        uint256 transactionId
    )
    public
    requireIsValidOwnerAndCouncilIsSetUp(tokenId)
    confirmed(transactionId, tokenId)
    notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            (bool success, string memory error) = _externalCall(txn.destination, txn.value, txn.data);
            if (success) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId, error);
                txn.executed = false;
            }
        }
    }

    /**
     * Returns the confirmation status of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Confirmation status.
     */
    function isConfirmed(
        uint256 transactionId
    )
    public
    view
    returns (bool)
    {
        uint[] memory _ownerTokenIds = ownerTokenIds();
        uint256 count = 0;
        for (uint256 i = 0; i < _ownerTokenIds.length; i++) {
            if (confirmations[transactionId][_ownerTokenIds[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
        return false;
    }

    /**
     * Returns number of confirmations of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Number of confirmations.
     */
    function getConfirmationCount(
        uint256 transactionId
    )
    public
    view
    returns (uint256)
    {
        uint[] memory _ownerTokenIds = ownerTokenIds();
        uint256 count = 0;
        for (uint256 i = 0; i < _ownerTokenIds.length; i++) {
            if (confirmations[transactionId][_ownerTokenIds[i]]) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns total number of transactions after filers are applied.
     *
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Total number of transactions after filters are applied.
     */
    function getTransactionCount(
        bool pending,
        bool executed
    )
    public
    view
    returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns array with owner addresses, which confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Array of NFTs that confirmed the transaction.
     */
    function getConfirmations(
        uint256 transactionId
    )
    public
    view
    returns (uint256[] memory)
    {
        uint256[] memory _ownerTokenIds = ownerTokenIds();
        uint256[] memory confirmationsTemp = new uint256[](_ownerTokenIds.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < _ownerTokenIds.length; i++) {
            if (confirmations[transactionId][_ownerTokenIds[i]]) {
                confirmationsTemp[count] = _ownerTokenIds[i];
                count += 1;
            }
        }
        uint256[] memory _confirmations = new uint256[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
        return _confirmations;
    }

    /**
     * Returns list of transaction IDs in defined range.
     *
     * @param  from      Index start position of transaction array.
     * @param  to        Index end position of transaction array.
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Array of transaction IDs.
     */
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    )
    public
    view
    returns (uint256[] memory)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        uint256[] memory _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
        return _transactionIds;
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function _externalCall(
        address destination,
        uint256 value,
        bytes memory data
    )
    internal
    returns (bool, string memory)
    {
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory result) = destination.call{value : value}(data);
        if (!success) {
            string memory targetString = _addressToString(destination);
            if (result.length < 68) {
                return (false, string(abi.encodePacked("UselessMultiSig: revert at <", targetString, ">")));
            } else {
                // solium-disable-next-line security/no-inline-assembly
                assembly {
                    result := add(result, 0x04)
                }
                return (
                    false,
                    string(
                        abi.encodePacked(
                            "UselessMultiSig: revert at <",
                            targetString,
                            "> with reason: ",
                            abi.decode(result, (string))
                        )
                    )
                );
            }
        } else {
            return (true, "");
        }
    }

    /**
     * Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function _addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
    internal
    notNull(destination)
    returns (uint256)
    {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
        destination : destination,
        value : value,
        data : data,
        executed : false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }

    function _addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}
