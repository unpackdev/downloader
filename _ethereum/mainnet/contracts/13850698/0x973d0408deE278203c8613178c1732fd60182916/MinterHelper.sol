pragma solidity 0.5.16;

import "./Controllable.sol";
import "./IFeeRewardForwarder.sol";
import "./SafeERC20.sol";
import "./iFarmStrategy.sol";

interface INotifyHelperStateful {
  function notifyPools(uint256, uint256) external;
}

interface IDelayMinter {
  function executeMint(uint256 _id) external;
  function announceMint(address _target, uint256 _amount) external;
  function nextId() external view returns(uint256);
}

contract MinterHelper is Controllable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event MintAnnounced(uint256 indexed id, uint256 indexed index);
  event MintExecuted(uint256 indexed id, uint256 indexed index);
  event MintPopped(uint256 indexed index);
  event MintAdded(uint256 indexed index);
  event MintUpdated(uint256 indexed index);
  event WhitelistSet(address indexed account, bool value);

  struct Mint {
    uint256 minterId; // the ID of the mint in the delay minter
    uint256 executeTimestamp; // the minimum timestamp when the mint can be executed
    uint256 amount; // the amount to be minted
    address target; // the target where the tokens are to be minted to
    bool executed; // flag for the mint execution
    bool announced; // flag for the mint announcement
  }

  mapping (address => bool) public whitelist;
  address public helper;
  address public farm;
  address public delayMinter;
  Mint[] public mints;

  modifier onlyWhitelisted {
    require(whitelist[msg.sender], "Only whitelisted");
    _;
  }

  constructor(address _helper, address _storage, address _farm, address _delayMinter) Controllable(_storage) public {
    helper = _helper;
    farm = _farm;
    delayMinter = _delayMinter;
  }

  /// Returning the governance
  function transferGovernance(address target, address newStorage) external onlyGovernance {
    Governable(target).setStorage(newStorage);
  }

  /// The governance configures mints for the future
  function appendMints(uint256[] calldata executeTimestamps, address[] calldata targets, uint256[] calldata amounts) external onlyGovernance {
    require(executeTimestamps.length == targets.length, "targets length mismatch");
    require(executeTimestamps.length == amounts.length, "amounts length mismatch");
    for (uint256 i = 0; i < executeTimestamps.length; i++) {
      appendMint(executeTimestamps[i], targets[i], amounts[i]);
    }
  }

  function appendMint(uint256 executeTimestamp, address target, uint256 amount) public onlyGovernance {
    require(amount > 0, "No zero mint");
    Mint memory mint = Mint(0, executeTimestamp, amount, target, false, false);
    mints.push(mint);
    emit MintAdded(mints.length - 1);
  }

  /// Corrective method to remove future mints
  function popMints(uint256 number) external onlyGovernance {
    for (uint256 i = 0; i < number; i++) {
      Mint storage mint = mints[mints.length.sub(1)];
      require(!mint.executed, "Executed");
      require(!mint.announced, "Announced");
      mints.pop();
      emit MintPopped(mints.length);
    }
  }

  function getNumberOfMints() external view returns(uint256) {
    return mints.length;
  }
  
  function updateMint(uint256 index, uint256 executeTimestamp, address target, uint256 amount) external onlyGovernance {
    require(index < mints.length, "Out of bounds");
    require(amount > 0, "No zero mint");
    require(!mints[index].executed, "Executed");
    require(!mints[index].announced, "Announced");
    mints[index].executeTimestamp = executeTimestamp;
    mints[index].target = target;
    mints[index].amount = amount;
    emit MintUpdated(index);
  }

  /// The governance configures mint executors
  function setWhitelist(address who, bool value) external onlyGovernance {
    whitelist[who] = value;
    emit WhitelistSet(who, value);
  }

  /// The mint executors can announce mints if they are not announced
  function announce(uint256 index) public onlyWhitelisted {
    require(!mints[index].announced, "Announced");
    require(!mints[index].executed, "Executed");
    require(block.timestamp >= mints[index].executeTimestamp.sub(1 weeks), "Too soon");
    require(block.timestamp <= mints[index].executeTimestamp.sub(24 hours), "Too late");
    mints[index].minterId = IDelayMinter(delayMinter).nextId();
    IDelayMinter(delayMinter).announceMint(address(this), mints[index].amount);
    mints[index].announced = true;
    emit MintAnnounced(mints[index].minterId, index);
  }

  /// The mint executors execute a mint, notify the pools, and optionally announce next mint
  function execute(uint256 index, bool announceNext) external onlyWhitelisted {
    require(block.timestamp >= mints[index].executeTimestamp, "Too early");
    require(!mints[index].executed, "Executed");
    require(mints[index].announced, "Announced");
    IDelayMinter(delayMinter).executeMint(mints[index].minterId);
    mints[index].executed = true;
    emit MintExecuted(mints[index].minterId, index);

    // use the mint
    uint256 amount = IERC20(farm).balanceOf(address(this));
    IERC20(farm).approve(helper, amount);
    INotifyHelperStateful(helper).notifyPools(amount, mints[index].executeTimestamp);

    // announcing next week's mint automatically
    if (index.add(1) < mints.length && announceNext) {
      announce(index.add(1));
    }
  }

  /// When launching, the delay minter will have a mint announced with a different target
  function executeFirstMint(uint256 amount, uint256 timestamp, bool announceNext, uint256 nextMint) external onlyGovernance {
    // use the mint
    IERC20(farm).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(farm).approve(helper, amount);
    INotifyHelperStateful(helper).notifyPools(amount, timestamp);

    // announcing next week's mint automatically
    if (nextMint < mints.length && announceNext) {
      announce(nextMint);
    }
  }

  /// emergency draining of tokens and ETH as there should be none staying here
  function emergencyDrain(address token, uint256 amount) public onlyGovernance {
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20(token).safeTransfer(msg.sender, amount);
    }
  }
}
