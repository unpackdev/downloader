//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./console.sol";

interface IERC20 {
  function balanceOf(address owner) external returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transfer(address recipient, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface IVoters {
    function snapshot() external returns (uint);
    function totalSupplyAt(uint snapshotId) external view returns (uint);
    function votesAt(address account, uint snapshotId) external view returns (uint);
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
}

contract RaDAO {
    bool private _initialized;

    constructor() {
        _initialized = true;
    }

    // ERC20 & Voting Power & Delegation
    ///////////////////////////////////////////////////////////////////////////

    struct Snapshots {
        uint[] ids;
        uint[] values;
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Snapshot(uint id);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    IERC20 public wrappedToken;
    uint public totalWrapped;
    mapping(address => mapping(address => uint)) public allowance;
    uint private _currentSnapshotId;
    Snapshots private _totalSupplySnapshots;
    mapping(address => Snapshots) private _balancesSnapshots;
    mapping(address => address) public delegates;
    mapping(address => Snapshots) private _votesSnapshots;

    function totalSupply() public view returns (uint) {
      return _valueAt(_totalSupplySnapshots, _currentSnapshotId);
    }

    function balanceOf(address owner) external view returns (uint) {
      return _valueAt(_balancesSnapshots[owner], _currentSnapshotId);
    }

    function burn(address from, uint amount) external {
        require(msg.sender == address(this), "!dao");
        _burn(from, amount);
    }

    function _burn(address from, uint amount) private {
        _updateSnapshot(_balancesSnapshots[from], 0 - int(amount));
        _updateSnapshot(_totalSupplySnapshots, 0 - int(amount));
        _updateSnapshot(_votesSnapshots[delegates[from]], 0 - int(amount));
        emit Transfer(from, address(0), amount);
    }

    function mint(address to, uint amount) external {
        require(msg.sender == address(this) || !_initialized, "!dao");
        _mint(to, amount);
    }

    function _mint(address to, uint amount) private {
        _updateSnapshot(_balancesSnapshots[to], int(amount));
        _updateSnapshot(_totalSupplySnapshots, int(amount));
        _updateSnapshot(_votesSnapshots[delegates[to]], int(amount));
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        require(spender != address(0), "!zero");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) external returns (bool) {
        require(address(wrappedToken) != address(0), "!wrapped");
        unchecked {
            _updateSnapshot(_balancesSnapshots[msg.sender], 0 - int(amount));
            _updateSnapshot(_balancesSnapshots[to], int(amount));
            _updateSnapshot(_votesSnapshots[delegates[msg.sender]], 0 - int(amount));
            _updateSnapshot(_votesSnapshots[delegates[to]], int(amount));
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(address(wrappedToken) != address(0), "!wrapped");
        allowance[from][msg.sender] = allowance[from][msg.sender] - amount;
        unchecked {
            _updateSnapshot(_balancesSnapshots[from], 0 - int(amount));
            _updateSnapshot(_balancesSnapshots[to], int(amount));
            _updateSnapshot(_votesSnapshots[delegates[from]], 0 - int(amount));
            _updateSnapshot(_votesSnapshots[delegates[to]], int(amount));
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function snapshot() external returns (uint) {
        require(msg.sender == address(this) || !_initialized, "!dao");
        return _snapshot();
    }

    function _snapshot() private returns (uint) {
        unchecked { _currentSnapshotId += 1; }
        emit Snapshot(_currentSnapshotId);
        return _currentSnapshotId;
    }

    function totalSupplyAt(uint snapshotId) public view returns (uint) {
        return _valueAt(_totalSupplySnapshots, snapshotId);
    }

    function votesAt(address account, uint snapshotId) public view returns (uint) {
        return _valueAt(_votesSnapshots[account], snapshotId);
    }

    function _valueAt(Snapshots storage snapshots, uint snapshotId) private view returns (uint) {
        if (snapshots.ids.length <= 0) {
            return 0;
        }
        uint lower = 0;
        uint upper = snapshots.ids.length-1;
        unchecked {
            while (upper > lower) {
                uint center = upper - (upper - lower) / 2;
                uint id = snapshots.ids[center];
                if (id == snapshotId) {
                  return snapshots.values[center];
                } else if (id < snapshotId){
                  lower = center;
                } else {
                  upper = center - 1;
                }
            }
        }
        if (lower < snapshots.values.length) {
          return snapshots.values[lower];
        }
        return 0;
    }

    function _updateSnapshot(Snapshots storage snapshots, int change) private {
        uint newValue = uint(int(_valueAt(snapshots, _currentSnapshotId)) + change);
        uint currentId = _currentSnapshotId;
        uint lastSnapshotId = 0;
        if (snapshots.ids.length > 0) {
            unchecked {
                lastSnapshotId = snapshots.ids[snapshots.ids.length - 1];
            }
        }
        if (lastSnapshotId < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(newValue);
        } else {
            unchecked {
                snapshots.values[snapshots.values.length - 1] = newValue;
            }
        }
    }

    function delegate(address delegatee) external {
        address currentDelegate = delegates[msg.sender];
        delegates[msg.sender] = delegatee;
        uint amount = _valueAt(_balancesSnapshots[msg.sender], _currentSnapshotId);
        _updateSnapshot(_votesSnapshots[currentDelegate], 0 - int(amount));
        _updateSnapshot(_votesSnapshots[delegatee],  int(amount));
        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
    }

    // Lock / Unlock
    ///////////////////////////////////////////////////////////////////////////

    function adjustTotalWrapped(int value) external {
        require(msg.sender == address(this), "!dao");
        unchecked {
            if (value > 0) {
                totalWrapped += uint(value);
            } else {
                totalWrapped -= uint(0 - value);
            }
        }
    }

    function lock(uint amount) external {
        require(address(wrappedToken) != address(0), "!wrapped");
        safeTransferFrom(wrappedToken, msg.sender, address(this), amount);
        uint _mintAmount = amount;
        if (totalSupply() != 0 && totalWrapped != 0) {
          _mintAmount = (amount * totalSupply()) / totalWrapped;
        }
        unchecked { totalWrapped += _mintAmount; }
        if (address(voters) == address(this)) {
          _mint(msg.sender, _mintAmount);
        } else {
          voters.mint(msg.sender, _mintAmount);
        }
    }

    function unlock(uint amount) external {
        require(address(wrappedToken) != address(0), "!wrapped");
        uint _totalWrapped = totalWrapped;
        uint _totalSupply = totalSupply();
        if (address(voters) == address(this)) {
          _burn(msg.sender, amount);
        } else {
          voters.burn(msg.sender, amount);
        }
        uint _value = (amount * _totalWrapped) / _totalSupply;
        totalWrapped -= _value;
        safeTransfer(wrappedToken, msg.sender, _value);
    }

    function safeTransfer(IERC20 token, address to, uint value) private {
      _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) private {
      _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(address token, bytes memory data) private {
        uint size;
        assembly { size := extcodesize(token) }
        require(size > 0, "!contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "erc20!call");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "erc20!success");
        }
    }

    // Proposals
    ///////////////////////////////////////////////////////////////////////////

    struct Proposal {
        uint id;
        address proposer;
        string title;
        string description;
        string[] optionsNames;
        bytes[][] optionsActions;
        uint[] optionsVotes;
        uint startAt;
        uint endAt;
        uint executableAt;
        uint executedAt;
        uint snapshotId;
        uint votersSupply;
    }

    event Proposed(uint indexed proposalId);
    event Voted(uint indexed proposalId, address indexed voter, uint optionId);
    event Executed(address indexed to, uint value, bytes data);
    event ExecutedProposal(uint indexed proposalId, uint optionId, address executer);

    string constant private AGAINST_OPTION_NAME = "-";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint optionId)");
    uint public minBalanceToPropose;
    uint public minPercentQuorum;
    uint public minVotingTime;
    uint public minExecutionDelay;
    IVoters public voters;
    uint public proposalsCount;
    mapping(uint => Proposal) private proposals;
    mapping(uint => mapping(address => uint)) public proposalVotes;
    mapping (address => uint) private latestProposalIds;

    function configure(
      string calldata _name, string calldata _symbol, address _voters, address _wrappedToken,
      uint _minBalanceToPropose, uint _minPercentQuorum, uint _minVotingTime, uint _minExecutionDelay
    ) external {
        require(msg.sender == address(this) || !_initialized, "!dao");
        name = _name;
        symbol = _symbol;
        voters = IVoters(_voters);
        wrappedToken = IERC20(_wrappedToken);
        minBalanceToPropose = _minBalanceToPropose;
        minPercentQuorum = _minPercentQuorum;
        minVotingTime = _minVotingTime;
        minExecutionDelay = _minExecutionDelay;
        if (!_initialized) {
            _initialized = true;
        }
    }

    function proposal(uint index) public view returns (uint, address, string memory, uint, uint, uint, uint) {
        return (
          proposals[index].id,
          proposals[index].proposer,
          proposals[index].title,
          proposals[index].startAt,
          proposals[index].endAt,
          proposals[index].executableAt,
          proposals[index].executedAt
        );
    }

    function proposalDetails(uint index) public view returns (string memory, uint, uint, string[] memory, bytes[][] memory, uint[] memory) {
        return (
          proposals[index].description,
          proposals[index].snapshotId,
          proposals[index].votersSupply,
          proposals[index].optionsNames,
          proposals[index].optionsActions,
          proposals[index].optionsVotes
        );
    }

    function propose(string calldata title, string calldata description, uint votingTime, uint executionDelay, string[] calldata optionNames, bytes[][] memory optionActions) external returns (uint) {
        uint snapshotId;
        if (address(voters) == address(this)) {
          snapshotId = _snapshot();
        } else {
          snapshotId = voters.snapshot();
        }
        require(voters.votesAt(msg.sender, snapshotId) >= minBalanceToPropose, "<balance");
        require(optionNames.length == optionActions.length && optionNames.length > 0 && optionNames.length <= 100, "option len match or count");
        require(optionActions[optionActions.length - 1].length == 0, "last option, no action");
        require(votingTime >= minVotingTime, "<voting time");
        require(executionDelay >= minExecutionDelay, "<exec delay");

        // Check the proposing address doesn't have an other active proposal
        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            require(block.timestamp > proposals[latestProposalId].endAt, "1 live proposal max");
        }

        // Add new proposal
        Proposal storage newProposal = proposals[proposalsCount];
        newProposal.id = proposalsCount;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.startAt = block.timestamp;
        newProposal.endAt = block.timestamp + votingTime;
        newProposal.executableAt = block.timestamp + votingTime + executionDelay;
        newProposal.snapshotId = snapshotId;
        newProposal.votersSupply = voters.totalSupplyAt(snapshotId);
        newProposal.optionsNames = new string[](optionNames.length);
        newProposal.optionsVotes = new uint[](optionNames.length);
        newProposal.optionsActions = optionActions;

        unchecked {
            for (uint i = 0; i < optionNames.length; i++) {
                require(optionActions[i].length <= 10, "actions length > 10");
                newProposal.optionsNames[i] = optionNames[i];
            }

            proposalsCount += 1;
        }

        latestProposalIds[msg.sender] = newProposal.id;
        emit Proposed(newProposal.id);
        return newProposal.id;
    }

    function vote(uint proposalId, uint optionId, uint8 v, bytes32 r, bytes32 s) external {
        address voter = msg.sender;
        if (r != 0x00000000000000000000000000000000) {
          uint chainId;
          assembly { chainId := chainid() }
          bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), chainId, address(this)));
          bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, optionId));
          bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
          voter = ecrecover(digest, v, r, s);
          require(voter != address(0), "invalid signature");
        }
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.endAt && proposalVotes[proposalId][voter] == 0, "voting ended or already voted");
        unchecked {
          p.optionsVotes[optionId] = p.optionsVotes[optionId] + voters.votesAt(voter, p.snapshotId);
          proposalVotes[proposalId][voter] = optionId + 1;
        }
        emit Voted(proposalId, voter, optionId);
    }

    // Executes an un-executed, with quorum, ready to be executed proposal
    // If the pre-conditions are met, anybody can call this
    // Part of this is establishing which option "won" and if quorum was reached
    function execute(uint proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.executedAt == 0 && block.timestamp > p.executableAt, "executed or not executable");
        p.executedAt = block.timestamp; // Mark as executed now to prevent re-entrancy

        // Pick the winning option (the one with the most votes, defaulting to the "Against" (last) option
        uint votesTotal;
        uint winningOptionIndex = p.optionsNames.length - 1; // Default to "Against"
        uint winningOptionVotes = 0;
        unchecked {
            for (uint i = p.optionsNames.length - 1; i >= 0; i--) {
                uint votes = p.optionsVotes[i];
                votesTotal = votesTotal + votes;
                // Use greater than (not equal) to avoid a proposal with 0 votes
                // to default to the 1st option
                if (votes > winningOptionVotes) {
                    winningOptionIndex = i;
                    winningOptionVotes = votes;
                }
            }
        }

        require((votesTotal * 1e12) / p.votersSupply > minPercentQuorum, "not at quorum");

        // Run all actions attached to the winning option
        unchecked {
          for (uint i = 0; i < p.optionsActions[winningOptionIndex].length; i++) {
              (address to, uint value, bytes memory data) = abi.decode(
                p.optionsActions[winningOptionIndex][i],
                (address, uint, bytes)
              );
              (bool success,) = to.call{value: value}(data);
              require(success, "action reverted");
              emit Executed(to, value, data);
          }
        }

        emit ExecutedProposal(proposalId, winningOptionIndex, msg.sender);
    }

    // Treasury
    ///////////////////////////////////////////////////////////////////////////

    event ValueReceived(address indexed sender, uint value);

    receive() external payable {
      emit ValueReceived(msg.sender, msg.value);
    }
}
