// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

abstract contract ITellor {
    event NewTellorAddress(address _newTellor);
    event NewDispute(
        uint256 indexed _disputeId,
        uint256 indexed _requestId,
        uint256 _timestamp,
        address _miner
    );
    event Voted(
        uint256 indexed _disputeID,
        bool _position,
        address indexed _voter,
        uint256 indexed _voteWeight
    );
    event DisputeVoteTallied(
        uint256 indexed _disputeID,
        int256 _result,
        address indexed _reportedMiner,
        address _reportingParty,
        bool _active
    );
    event TipAdded(
        address indexed _sender,
        uint256 indexed _requestId,
        uint256 _tip,
        uint256 _totalTips
    );
    event NewChallenge(
        bytes32 indexed _currentChallenge,
        uint256[5] _currentRequestId,
        uint256 _difficulty,
        uint256 _totalTips
    );
    event NewValue(
        uint256[5] _requestId,
        uint256 _time,
        uint256[5] _value,
        uint256 _totalTips,
        bytes32 indexed _currentChallenge
    );
    event NonceSubmitted(
        address indexed _miner,
        string _nonce,
        uint256[5] _requestId,
        uint256[5] _value,
        bytes32 indexed _currentChallenge
    );
    event OwnershipTransferred(
        address indexed _previousOwner,
        address indexed _newOwner
    );
    event OwnershipProposed(
        address indexed _previousOwner,
        address indexed _newOwner
    );
    event NewStake(address indexed _sender); //Emits upon new staker
    event StakeWithdrawn(address indexed _sender); //Emits when a staker is now no longer staked
    event StakeWithdrawRequested(address indexed _sender); //Emits when a staker begins the 7 day withdraw period
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    ); //ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //ERC20 Transfer Event

    function changeDeity(address _newDeity) external virtual;

    function changeTellorContract(address _tellorContract) external virtual;

    function allowance(address _user, address _spender)
        external
        view
        virtual
        returns (uint256);

    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        virtual
        returns (bool);

    function balanceOf(address _user) external view virtual returns (uint256);

    function balanceOfAt(address _user, uint256 _blockNumber)
        external
        view
        virtual
        returns (uint256);

    function didMine(bytes32 _challenge, address _miner)
        external
        view
        virtual
        returns (bool);

    function didVote(uint256 _disputeId, address _address)
        external
        view
        virtual
        returns (bool);

    function getAddressVars(bytes32 _data)
        external
        view
        virtual
        returns (address);

    function getAllDisputeVars(uint256 _disputeId)
        public
        view
        virtual
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        );

    function getCurrentVariables()
        external
        view
        virtual
        returns (
            bytes32,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256
        );

    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        virtual
        returns (uint256);

    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        virtual
        returns (uint256);

    function getLastNewValue() external view virtual returns (uint256, bool);

    function getLastNewValueById(uint256 _requestId)
        external
        view
        virtual
        returns (uint256, bool);

    function getMinedBlockNum(uint256 _requestId, uint256 _timestamp)
        external
        view
        virtual
        returns (uint256);

    function getMinersByRequestIdAndTimestamp(
        uint256 _requestId,
        uint256 _timestamp
    ) external view virtual returns (address[5] memory);

    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        virtual
        returns (uint256);

    function getRequestIdByRequestQIndex(uint256 _index)
        external
        view
        virtual
        returns (uint256);

    function getRequestIdByTimestamp(uint256 _timestamp)
        external
        view
        virtual
        returns (uint256);

    function getRequestIdByQueryHash(bytes32 _request)
        external
        view
        virtual
        returns (uint256);

    function getRequestQ() public view virtual returns (uint256[51] memory);

    function getRequestUintVars(uint256 _requestId, bytes32 _data)
        external
        view
        virtual
        returns (uint256);

    function getRequestVars(uint256 _requestId)
        external
        view
        virtual
        returns (uint256, uint256);

    function getStakerInfo(address _staker)
        external
        view
        virtual
        returns (uint256, uint256);

    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp)
        external
        view
        virtual
        returns (uint256[5] memory);

    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index)
        external
        view
        virtual
        returns (uint256);

    function getUintVar(bytes32 _data) public view virtual returns (uint256);

    function getVariablesOnDeck()
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            string memory
        );

    function isInDispute(uint256 _requestId, uint256 _timestamp)
        external
        view
        virtual
        returns (bool);

    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        virtual
        returns (uint256);

    function totalSupply() external view virtual returns (uint256);

    function beginDispute(
        uint256 _requestId,
        uint256 _timestamp,
        uint256 _minerIndex
    ) external virtual;

    function vote(uint256 _disputeId, bool _supportsDispute) external virtual;

    function tallyVotes(uint256 _disputeId) external virtual;

    function proposeFork(address _propNewTellorAddress) external virtual;

    function addTip(uint256 _requestId, uint256 _tip) external virtual;

    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestId,
        uint256[5] calldata _value
    ) external virtual;

    function proposeOwnership(address payable _pendingOwner) external virtual;

    function claimOwnership() external virtual;

    function depositStake() external virtual;

    function requestStakingWithdraw() external virtual;

    function withdrawStake() external virtual;

    function approve(address _spender, uint256 _amount)
        external
        virtual
        returns (bool);

    function transfer(address _to, uint256 _amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external virtual returns (bool);

    function name() external pure virtual returns (string memory);

    function symbol() external pure virtual returns (string memory);

    function decimals() external pure virtual returns (uint8);

    function getNewCurrentVariables()
        external
        view
        virtual
        returns (
            bytes32 _challenge,
            uint256[5] memory _requestIds,
            uint256 _difficutly,
            uint256 _tip
        );

    function getTopRequestIDs()
        external
        view
        virtual
        returns (uint256[5] memory _requestIds);

    function getNewVariablesOnDeck()
        external
        view
        virtual
        returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck);

    function updateTellor(uint256 _disputeId) external virtual;

    function unlockDisputeFee(uint256 _disputeId) external virtual;

    //Test Functions
    function theLazyCoon(address _address, uint256 _amount) external virtual;

    function testSubmitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestId,
        uint256[5] calldata _value
    ) external virtual;

    function manuallySetDifficulty(uint256 _diff) external virtual {}

    function migrate() external {}

    function getMax(uint256[51] memory data)
        public
        view
        virtual
        returns (uint256 max, uint256 maxIndex);

    function getMin(uint256[51] memory data)
        public
        view
        virtual
        returns (uint256 min, uint256 minIndex);

    function getMax5(uint256[51] memory data)
        public
        view
        virtual
        returns (uint256[5] memory max, uint256[5] memory maxIndex);

    function changeTellorGetters(address _tGetters) external virtual;
}
