pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Governance {

  using SafeMath for uint;

  /// @notice The duration of voting on a proposal, in Ethereum blocks
  uint public votingPeriod;

  /// @notice The total number of proposals
  uint public proposalCount;

  /// @notice Number of blocks before the same account can submit another proposal
  uint public proposalCooldown;

  /// @notice The required minimum number of votes in support of a proposal for it to succeed
  uint public quorumVotes;

  /// @notice The minimum number of votes required for an account to create a proposal
  uint public proposalThreshold;

  ERC20 public token;
  address public owner;

  /// @notice The record of all proposals ever proposed
  mapping (uint256 => Proposal) public proposals;

  /// @notice The block until which tokens used for voting will be locked
  mapping (address => uint) public voteLock;

  /// @notice Delay before the same address can submit another proposal, in Ethereum blocks
  mapping (address => uint) public proposalLock;

  /// @notice Keeps track of locked tokens per address
  mapping(address => uint) public balanceOf;

  struct Proposal {
    /// @notice Unique id for looking up a proposal
    uint id;

    /// @notice Creator of the proposal
    address proposer;

    /// @notice The block at which voting starts
    uint startBlock;

    /// @notice Current number of votes in favor of this proposal
    uint forVotes;

    /// @notice Current number of votes in opposition to this proposal
    uint againstVotes;

    /// @notice Receipts of ballots for the entire set of voters
    mapping (address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    /// @notice Whether or not a vote has been cast
    bool hasVoted;

    /// @notice Whether or not the voter supports the proposal
    bool support;

    /// @notice The number of votes the voter had, which were cast
    uint votes;
  }

  /// @notice Possible states that a proposal may be in
  enum ProposalState {
    Active,
    Defeated,
    Succeeded
  }

  /// @notice If the votingPeriod is changed and the user votes again, the lock period will be reset.
  modifier lockVotes() {
    uint tokenBalance = token.balanceOf(msg.sender);
    token.transferFrom(msg.sender, address(this), tokenBalance);
    _mint(msg.sender, tokenBalance);
    voteLock[msg.sender] = block.number.add(votingPeriod);
    _;
  }

  constructor() public {
    token = ERC20(0x5eCA15B12d959dfcf9c71c59F8B467Eb8c6efD0b);
    owner = msg.sender;
  }

  function state(uint proposalId)
    public
    view
    returns (ProposalState)
  {
    require(proposalCount >= proposalId && proposalId > 0, "Governance::state: invalid proposal id");
    Proposal storage proposal = proposals[proposalId];

    if (block.number <= proposal.startBlock.add(votingPeriod)) {
      return ProposalState.Active;

    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
      return ProposalState.Defeated;

    } else {
      return ProposalState.Succeeded;
    }
  }

  function getVote(uint _proposalId, address _voter)
    public
    view
    returns (bool)
  {
    return proposals[_proposalId].receipts[_voter].support;
  }


  function updateParams(
    uint _votingPeriod,
    uint _quorumVotes,
    uint _proposalThreshold,
    uint _proposalCooldown
  )
    public
  {
    require(msg.sender == owner, "Governance::state: not owner");
    require(_votingPeriod >= 1 && _votingPeriod <= 40000, "Governance::state: _votingPeriod out of range");
    require(_quorumVotes >= 1 && _quorumVotes <= 50000e18, "Governance::state: _quorumVotes out of range");
    require(_proposalThreshold >= 1 && _proposalThreshold <= 10000e18, "Governance::state: _proposalThreshold out of range");
    require(_proposalCooldown >= 1 && _proposalCooldown <= 40000, "Governance::state: _proposalCooldown out of range");

    votingPeriod = _votingPeriod;
    quorumVotes = _quorumVotes;
    proposalThreshold = _proposalThreshold;
    proposalCooldown = _proposalCooldown;
  }

  function propose()
    public
    lockVotes
    returns (uint)
  {

    require(balanceOf[msg.sender] > proposalThreshold, "Governance::propose: proposer votes below proposal threshold");
    require(block.number > proposalLock[msg.sender], "Governance::propose: wait until proposalLock expiration");

    proposalLock[msg.sender] = block.number.add(proposalCooldown);

    proposalCount++;
    Proposal memory newProposal = Proposal({
      id: proposalCount,
      proposer: msg.sender,
      startBlock: block.number,
      forVotes: 0,
      againstVotes: 0
    });

    proposals[newProposal.id] = newProposal;
  }

  function vote(uint _proposalId, bool _support) public lockVotes {

    require(state(_proposalId) == ProposalState.Active, "Governance::vote: voting is closed");
    Proposal storage proposal = proposals[_proposalId];
    Receipt storage receipt = proposal.receipts[msg.sender];
    require(receipt.hasVoted == false, "Governance::vote: voter already voted");

    uint votes = balanceOf[msg.sender];

    if (_support) {
      proposal.forVotes = proposal.forVotes.add(votes);
    } else {
      proposal.againstVotes = proposal.againstVotes.add(votes);
    }

    receipt.hasVoted = true;
    receipt.support = _support;
    receipt.votes = votes;
  }

  function withdraw() public {
    require(block.number > voteLock[msg.sender], "Governance::withdraw: wait until voteLock expiration");
    require(block.number > proposalLock[msg.sender], "Governance::propose: wait until proposalLock expiration");
    token.transfer(msg.sender, balanceOf[msg.sender]);
    _burn(msg.sender, balanceOf[msg.sender]);
  }

  function _mint(address _account, uint _amount) internal {
    balanceOf[_account] = balanceOf[_account].add(_amount);
  }

  function _burn(address _account, uint _amount) internal {
    balanceOf[_account] = balanceOf[_account].sub(_amount, "ERC20: burn amount exceeds balance");
  }
}