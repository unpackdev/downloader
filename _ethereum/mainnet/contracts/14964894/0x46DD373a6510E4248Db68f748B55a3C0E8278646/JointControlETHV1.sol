// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.13;

import "./UUPSUpgradeable.sol";
import "./ERC1967Proxy.sol";
import "./JCETHPlaceholderBase.sol";

contract JointControlETHV1 is UUPSUpgradeable {
    ////////////////////////////////////////////////////////////////////////////
    // Types
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev VoteMode decides how many yahs needed to pass a proposal
     *   - `Majority`: >= 2/3 members voted yes
     *   - `Omni`: all members
     */
    enum VoteMode {
        Majority,
        Omni
    }

    enum ProposalType {
        // Plain ETH transfer
        Transfer,
        // Contract interaction
        ContractInteraction,
        // Account contract proxy upgrade
        AccounContractUpgrade,
        // Multi contract call
        MultiCall
    }

    /**
     * @dev JCAccount entity
     *
     * `accountNumber`: i-th account opened by the contract. Must be non-zero. If it's 0, the entity is not a valid account.
     */
    struct JCAccount {
        uint256 accountNumber;
        address accountAddress;
        address[] committee;
        address founder;
        VoteMode voteMode;
        uint256 numProposals;
        bytes32 accountAlias;
    }

    /**
     * @dev  Proposal content entity. It represents a transaction one member proposes to execute.
     *
     * `bytes`: In ETH transfer, it's the amount in WEI. In contract interaction, it's function call data
     * `deadline`: the blocknumber after which proposal is invalid.
     */
    struct ProposalContent {
        uint256 accountNumber;
        ProposalType proposalType;
        address target;
        bytes data;
        uint256 deadline;
    }

    /**
     * @dev Proposal entity. It represents a valid proposal in the pool that committee can vote on;
     *
     * `proposalNumber`: i-th proposal of an account. Must be non-zero. If it's 0, the entity is not a valid proposal.
     */
    struct Proposal {
        uint256 proposalNumber;
        bool executed;
        uint256 yah;
        uint256 nay;
        address advocate;
        ProposalContent content;
    }

    /**
     * @dev Poll entity. It represents a vote on a proposal from a committee member;
     */
    struct Poll {
        uint256 accountNumber;
        uint256 proposalNumber;
        bool approval;
    }

    /**
     * @dev Execution request entity.
     */
    struct ExecutionRequest {
        uint256 accountNumber;
        uint256 proposalNumber;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////////

    event NewAccount(
        uint256 indexed accountNumber,
        address indexed founder,
        address indexed member,
        address accountAddress,
        bytes32 accountAlias,
        uint256 numMembers,
        VoteMode voteMode
    );

    event NewProposal(
        uint256 indexed accountNumber,
        uint256 indexed proposalNumber,
        address indexed advocate,
        address target,
        bool approval
    );

    event NewPoll(
        uint256 indexed accountNumber,
        uint256 indexed proposalNumber,
        bool indexed approval,
        address member
    );

    event NewDeposit(
        uint256 indexed accountNumber,
        address indexed sender,
        uint256 indexed amount,
        uint256 balance
    );

    event NewExecution(
        uint256 indexed accountNumber,
        uint256 indexed proposalNumber,
        ProposalType indexed proposalType,
        address executor,
        address target
    );

    ////////////////////////////////////////////////////////////////////////////
    // Fields
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev admin of the contract. Could do upgrade and pause
     */
    address private _admin;

    /**
     * @dev total number of acctouns opened from the contract
     */
    uint256 private _openedAccounts;

    /**
     * @dev Accounts entities storage
     *
     * `accountNumber` => `JCAccount`
     */
    mapping(uint256 => JCAccount) private _accounts;

    /**
     * @dev Proposal entities storage
     *
     * `accountNumber` => (`proposalNumber` => `Proposal`)
     */
    mapping(uint256 => mapping(uint256 => Proposal)) private _proposals;

    /**
     * @dev Accounts ownership. Used to quickly check if a user is belonging to an account's committee.
     *
     * `accountNumber` => ('address' => true if it belongs to this account's committee)
     */
    mapping(uint256 => mapping(address => bool)) private _accountOwnerships;

    /**
     * @dev Vote history. Used to prevent double voting.
     *
     * `accountNumber` => (`proposalNumber` => (`address` => true if voted))
     */
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        private _voteHistory;

    /**
     * @dev Execution status of proposals. Prevent re-entry attack
     *
     * `accountNumber` => (`proposalNumber` => true if it's in execution)
     */
    mapping(uint256 => mapping(uint256 => bool)) _inExecution;

    /**
     * @dev Implementation instance version
     */
    string private _version;

    ////////////////////////////////////////////////////////////////////////////
    // Modifiers
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Check account exists
     */
    modifier accountExists(uint256 accountNumber_) {
        JCAccount storage account = _accounts[accountNumber_];
        require(account.accountNumber != 0, "Non-existing account");
        _;
    }

    /**
     * @dev Check a member call that:
     *   1) account exists;
     *   2) `msg.sender` is part of the committee;
     */
    modifier memberCallSanityCheck(uint256 accountNumber_) {
        JCAccount storage account = _accounts[accountNumber_];

        // account exists
        require(account.accountNumber != 0, "Non-existing account");

        // sender in committee
        require(
            _accountOwnerships[accountNumber_][msg.sender],
            "Sender not in the committee"
        );

        _;
    }

    /**
     * @dev Check a proposal that:
     *   1) proposal exists;
     *   2) we didn't pass the deadline
     *   3) Not executed yet
     *
     * Also, this modifier supposed to follow up `memberCallSanityCheck()` cause this one does not check account's validation
     */
    modifier proposalSanityCheck(
        uint256 accountNumber_,
        uint256 proposalNumber_
    ) {
        Proposal storage proposal = _proposals[accountNumber_][proposalNumber_];

        // proposal exists
        require(proposal.proposalNumber != 0, "Non-existing proposal");

        // we didn't pass deadline
        require(
            block.number <= proposal.content.deadline,
            "Poll passing deadline"
        );

        // proposal has not been executed yet
        require(proposal.executed == false, "Proposal executed");

        _;
    }

    modifier reEntryProtection(
        uint256 accountNumber_,
        uint256 proposalNumber_
    ) {
        require(
            _inExecution[accountNumber_][proposalNumber_] == false,
            "re-Entry"
        );

        _inExecution[accountNumber_][proposalNumber_] = true;
        _;
        _inExecution[accountNumber_][proposalNumber_] = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Auth error: admin only");
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////
    constructor() {}

    function initialize() public reinitializer(1) {
        _version = "v1";
        _admin = msg.sender;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Account management functions (only committee can call)
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev deploy account placeholder contract as a UUPS proxy
     */
    function _deployAccountContract(uint256 accountNumber_)
        internal
        returns (address)
    {
        // deploye account placeholder contract impl
        JCETHPlaceholderBase placeholderImpl = new JCETHPlaceholderBase();

        // initialize
        placeholderImpl.initialize(address(this), accountNumber_);

        // deploy account placeholder proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(placeholderImpl),
            abi.encodeWithSelector(
                JCETHPlaceholderBase(payable(0)).initialize.selector,
                address(this),
                accountNumber_
            )
        );
        return address(proxy);
    }

    /**
     * @dev Open a new account. Returns this account's number.
     * `msg.sender` will NOT be included in the committee.
     */
    function newAccount(
        VoteMode voteMode_,
        address[] calldata committee_,
        bytes32 alias_
    ) public returns (uint256) {
        // committee not empty
        require(committee_.length > 0, "empty committee");

        // bump account counter
        _openedAccounts += 1;
        uint256 accountNumber = _openedAccounts;

        // deploy account contract
        address accountAddress = _deployAccountContract(accountNumber);

        // New account
        _accounts[accountNumber] = JCAccount(
            accountNumber,
            accountAddress,
            committee_,
            msg.sender,
            voteMode_,
            0,
            alias_
        );

        // record ownership and emit events
        for (uint256 i = 0; i < committee_.length; i++) {
            _accountOwnerships[accountNumber][committee_[i]] = true;

            emit NewAccount(
                accountNumber,
                msg.sender,
                committee_[i],
                accountAddress,
                alias_,
                committee_.length,
                voteMode_
            );
        }

        return accountNumber;
    }

    /**
     * @dev Submit a new proposal
     */
    function newProposal(ProposalContent calldata content_, bool approval_)
        public
        memberCallSanityCheck(content_.accountNumber)
        returns (uint256)
    {
        JCAccount storage account = _accounts[content_.accountNumber];
        uint256 accountNumber = account.accountNumber;

        // bump proposal counter
        account.numProposals += 1;
        uint256 proposalNumber = account.numProposals;

        // add to _proposals pool
        _proposals[accountNumber][proposalNumber] = Proposal(
            proposalNumber,
            false,
            approval_ ? 1 : 0,
            approval_ ? 0 : 1,
            msg.sender,
            content_
        );

        // emit
        emit NewProposal(
            accountNumber,
            proposalNumber,
            msg.sender,
            content_.target,
            approval_
        );

        // mark voted
        _voteHistory[accountNumber][proposalNumber][msg.sender] = true;

        return proposalNumber;
    }

    /**
     * @dev Member call this to vote on an existing proposal
     */
    function newPoll(Poll calldata poll_)
        public
        memberCallSanityCheck(poll_.accountNumber)
        proposalSanityCheck(poll_.accountNumber, poll_.proposalNumber)
    {
        // no double voting
        require(
            _voteHistory[poll_.accountNumber][poll_.proposalNumber][
                msg.sender
            ] == false,
            "Double voting"
        );

        Proposal storage proposal = _proposals[poll_.accountNumber][
            poll_.proposalNumber
        ];

        // update poll numbers
        if (poll_.approval) {
            proposal.yah += 1;
        } else {
            proposal.nay += 1;
        }

        emit NewPoll(
            poll_.accountNumber,
            poll_.proposalNumber,
            poll_.approval,
            msg.sender
        );

        // mark voted
        _voteHistory[poll_.accountNumber][poll_.proposalNumber][
            msg.sender
        ] = true;
    }

    /**
     * @dev Member calls this function to execute a approved proposal.
     */
    function execute(ExecutionRequest calldata request_)
        public
        memberCallSanityCheck(request_.accountNumber)
        proposalSanityCheck(request_.accountNumber, request_.proposalNumber)
        reEntryProtection(request_.accountNumber, request_.proposalNumber)
        returns (bytes memory)
    {
        JCAccount storage account = _accounts[request_.accountNumber];
        Proposal storage proposal = _proposals[request_.accountNumber][
            request_.proposalNumber
        ];

        // Check we have enough yah
        uint256 majority = _majorityThreshold(
            account.committee.length,
            account.voteMode
        );
        require(proposal.yah >= majority, "Not enough yah");

        // execute & mark execution status
        bytes memory returnData;
        if (proposal.content.proposalType == ProposalType.Transfer) {
            (proposal.executed, returnData) = _exeTransferProposal(
                proposal.content,
                account.accountAddress
            );
        } else if (
            proposal.content.proposalType == ProposalType.ContractInteraction
        ) {
            (proposal.executed, returnData) = _exeInteractionProposal(
                proposal.content,
                account.accountAddress
            );
        } else if (
            proposal.content.proposalType == ProposalType.AccounContractUpgrade
        ) {
            (proposal.executed, returnData) = _exeAccountAddressUpgrade(
                proposal.content
            );
        } else if (proposal.content.proposalType == ProposalType.MultiCall) {
            (proposal.executed, returnData) = _exeMultiCall(
                proposal.content,
                account.accountAddress
            );
        } else {
            require(false, "Un-supported ProposalType");
        }

        // revert if not executed successful
        require(proposal.executed, string(returnData));

        emit NewExecution(
            account.accountNumber,
            proposal.proposalNumber,
            proposal.content.proposalType,
            msg.sender,
            proposal.content.target
        );

        return returnData;
    }

    function _exeMultiCall(
        ProposalContent storage content_,
        address accountAddress_
    ) internal returns (bool success, bytes memory returnData) {
        JCETHPlaceholderBase holder = JCETHPlaceholderBase(
            payable(accountAddress_)
        );

        // Data encoding:
        //  [
        //     uint64 code,
        //    [
        //      ...
        //      [address target, bytes callData]
        //    ]
        //  ]
        (, bytes[] memory callDataArray) = abi.decode(
            content_.data,
            (uint64, bytes[])
        );

        for (uint256 i = 0; i < callDataArray.length; i++) {
            (address target, bytes memory data) = abi.decode(
                callDataArray[i],
                (address, bytes)
            );
            (success, returnData) = holder._call(target, data);
            if (!success) {
                return (false, returnData);
            }
        }

        return (success, returnData);
    }

    function _exeAccountAddressUpgrade(ProposalContent storage content_)
        internal
        returns (bool, bytes memory returnData)
    {
        JCAccount storage account = _accounts[content_.accountNumber];

        UUPSUpgradeable proxy = UUPSUpgradeable(account.accountAddress);
        proxy.upgradeTo(content_.target);

        return (true, "");
    }

    function _exeTransferProposal(
        ProposalContent storage content_,
        address accountAddress_
    ) internal returns (bool, bytes memory returnData) {
        uint256 eth = abi.decode(content_.data, (uint256));

        // ETH amount is > 0
        require(eth > 0, "Invalid transfer amount");

        // Contract has enough ETH
        require(accountAddress_.balance >= eth, "Not enough balance");

        JCETHPlaceholderBase holder = JCETHPlaceholderBase(
            payable(accountAddress_)
        );
        return holder._transfer(content_.target, eth);
    }

    function _exeInteractionProposal(
        ProposalContent storage content_,
        address accountAddress_
    ) internal returns (bool, bytes memory) {
        JCETHPlaceholderBase holder = JCETHPlaceholderBase(
            payable(accountAddress_)
        );
        (, bytes memory data) = abi.decode(content_.data, (uint64, bytes));
        return holder._call(content_.target, data);
    }

    function _majorityThreshold(uint256 numMembers_, VoteMode voteMode_)
        internal
        pure
        returns (uint256)
    {
        if (numMembers_ == 1 || voteMode_ == VoteMode.Omni) {
            return numMembers_;
        } else {
            return (numMembers_ * 2 + 3 - 1) / 3;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // UUPS
    ////////////////////////////////////////////////////////////////////////////

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function setAdmin(address newAdmin_) public onlyAdmin {
        _admin = newAdmin_;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Public interactions (anyone can call)
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Deposit ETH into an account. Returns new balance.
     */
    function depositETH(uint256 accountNumber_)
        public
        payable
        accountExists(accountNumber_)
        returns (uint256)
    {
        address accountAddress = _accounts[accountNumber_].accountAddress;
        payable(accountAddress).transfer(msg.value);

        emit NewDeposit(
            accountNumber_,
            msg.sender,
            msg.value,
            accountAddress.balance
        );

        return accountAddress.balance;
    }

    /**
     * @dev Get balance of an account
     */
    function getBalance(uint256 accountNumber_)
        public
        view
        accountExists(accountNumber_)
        returns (uint256)
    {
        address accountAddress = _accounts[accountNumber_].accountAddress;

        return accountAddress.balance;
    }

    /**
     * @dev Get account info
     */
    function getAccount(uint256 accountNumber_)
        public
        view
        accountExists(accountNumber_)
        returns (JCAccount memory)
    {
        return _accounts[accountNumber_];
    }

    /**
     * @dev Get proposal info
     */
    function getProposal(uint256 accountNumber_, uint256 proposalNumber_)
        public
        view
        accountExists(accountNumber_)
        returns (Proposal memory)
    {
        Proposal storage proposal = _proposals[accountNumber_][proposalNumber_];
        require(proposal.proposalNumber != 0, "Invalid proposalNumber");

        return proposal;
    }

    /**
     * @dev Check if `poc_` owns `accountNumber_`
     */
    function doesOwnAccount(address poc_, uint256 accountNumber_)
        public
        view
        accountExists(accountNumber_)
        returns (bool)
    {
        return _accountOwnerships[accountNumber_][poc_];
    }

    /**
     * @dev Get voting history of `poc_`'s voting history
     */
    function getVoteHistory(
        address poc_,
        uint256 accountNumber_,
        uint256 proposalNumber_
    ) public view accountExists(accountNumber_) returns (bool) {
        // valid proposal
        Proposal storage proposal = _proposals[accountNumber_][proposalNumber_];
        require(proposal.proposalNumber != 0, "Invalid proposalNumber");

        // poc_ in committee
        require(
            _accountOwnerships[accountNumber_][poc_],
            "POC not in the committee"
        );

        return _voteHistory[accountNumber_][proposalNumber_][poc_];
    }

    /**
     * @dev Total number of accounts opened
     */
    function totalAccounts() public view returns (uint256) {
        return _openedAccounts;
    }

    /**
     * @dev Get majority threshold of an account
     */
    function getAccountMajorityThreshold(uint256 accountNumber_)
        public
        view
        accountExists(accountNumber_)
        returns (uint256)
    {
        JCAccount storage account = _accounts[accountNumber_];

        return _majorityThreshold(account.committee.length, account.voteMode);
    }

    function getVersion() public view returns (string memory) {
        return _version;
    }

    function getAdmin() public view returns (address) {
        return _admin;
    }
}
