pragma solidity 0.5.16;

import "./Address.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IController.sol";
import "./IStrategy.sol";
import "./IVault.sol";

import "./IFeeRewardForwarder.sol";
import "./Governable.sol";
import "./IHardRewards.sol";

contract Controller is IController, Governable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public constant multiSig = 0xF49440C1F012d041802b25A73e5B0B9166a75c02;

  // external parties
  address public feeRewardForwarder;

  // Rewards for hard work. Nullable.
  IHardRewards public hardRewards;

  uint256 public constant profitSharingNumerator = 30;
  uint256 public constant profitSharingDenominator = 100;

  event SharePriceChangeLog(
    address indexed vault,
    address indexed strategy,
    uint256 oldSharePrice,
    uint256 newSharePrice,
    uint256 timestamp
  );

  mapping (address => bool) public whitelist;
  mapping (bytes32 => bool) public codeWhitelist;

  mapping (address => bool) public hardWorkers;

  modifier onlyHardWorkerOrGovernance() {
      require(hardWorkers[msg.sender] || (msg.sender == governance()),
      "only hard worker can call this");
      _;
  }

  constructor(address _storage, address _feeRewardForwarder, address[] memory _whitelist)
  Governable(_storage) public {
      require(_feeRewardForwarder != address(0), "feeRewardForwarder should not be empty");
      feeRewardForwarder = _feeRewardForwarder;
      hardWorkers[multiSig] = true;
      addMultipleToWhitelist(_whitelist);
  }

  function addHardWorker(address _worker) public onlyGovernance {
    require(_worker != address(0), "_worker must be defined");
    hardWorkers[_worker] = true;
  }

  function removeHardWorker(address _worker) public onlyGovernance {
    require(_worker != address(0), "_worker must be defined");
    hardWorkers[_worker] = false;
  }

  function greyList(address _addr) public view returns (bool) {
    return !whitelist[_addr] && !codeWhitelist[getContractHash(_addr)];
  }

  // Only smart contracts will be affected by the whitelist.
  function addToWhitelist(address _target) public onlyGovernance {
    whitelist[_target] = true;
  }

  function addMultipleToWhitelist(address[] memory _targets) public onlyGovernance {
    for (uint256 i = 0; i < _targets.length; i++) {
      whitelist[_targets[i]] = true;
    }
  }

  function removeFromWhitelist(address _target) public onlyGovernance {
    whitelist[_target] = false;
  }

  function removeMultipleFromWhitelist(address[] memory _targets) public onlyGovernance {
    for (uint256 i = 0; i < _targets.length; i++) {
      whitelist[_targets[i]] = false;
    }
  }

  function getContractHash(address a) public view returns (bytes32 hash) {
    assembly {
      hash := extcodehash(a)
    }
  }

  function addCodeToWhitelist(address _target) public onlyGovernance {
      codeWhitelist[getContractHash(_target)] = true;
  }

  function removeCodeFromWhitelist(address _target) public onlyGovernance {
      codeWhitelist[getContractHash(_target)] = false;
  }

  function setFeeRewardForwarder(address _feeRewardForwarder) public onlyGovernance {
    require(_feeRewardForwarder != address(0), "new reward forwarder should not be empty");
    feeRewardForwarder = _feeRewardForwarder;
  }

  function addVaultAndStrategy(address _vault, address _strategy) external onlyGovernance {
      require(_vault != address(0), "new vault shouldn't be empty");
      require(IVault(_vault).strategy() == address(0), "vault already has strategy");
      require(_strategy != address(0), "new strategy shouldn't be empty");

      // adding happens while setting
      IVault(_vault).setStrategy(_strategy);
  }

  function doHardWork(address _vault) external onlyHardWorkerOrGovernance {
      uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
      IVault(_vault).doHardWork();
      if (address(hardRewards) != address(0)) {
          // rewards are an option now
          hardRewards.rewardMe(msg.sender, _vault);
      }
      emit SharePriceChangeLog(
        _vault,
        IVault(_vault).strategy(),
        oldSharePrice,
        IVault(_vault).getPricePerFullShare(),
        block.timestamp
      );
  }

  function setHardRewards(address _hardRewards) external onlyGovernance {
      hardRewards = IHardRewards(_hardRewards);
  }

  // transfers token in the controller contract to the governance
  function salvage(address _token, uint256 _amount) external onlyGovernance {
      IERC20(_token).safeTransfer(governance(), _amount);
  }

  function salvageStrategy(address _strategy, address _token, uint256 _amount) external onlyGovernance {
      // the strategy is responsible for maintaining the list of
      // salvagable tokens, to make sure that governance cannot come
      // in and take away the coins
      IStrategy(_strategy).salvage(governance(), _token, _amount);
  }

  function notifyFee(address underlying, uint256 fee) external {
    if (fee > 0) {
      IERC20(underlying).safeTransferFrom(msg.sender, address(this), fee);
      IERC20(underlying).safeApprove(feeRewardForwarder, 0);
      IERC20(underlying).safeApprove(feeRewardForwarder, fee);
      IFeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(underlying, fee);
    }
  }
}
