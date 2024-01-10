// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721.sol";

/**
 * @dev Interface for checking active staked balance of a user.
 */
interface ILoomi {
  function spendLoomi(address user, uint256 amount) external;
  function depositLoomiFor(address user, uint256 amount) external;
}

interface ILoomiSource {
  function getAccumulatedAmount(address staker) external view returns (uint256);
}

contract ProxyYield is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    ILoomi public loomi;
    ILoomiSource public Staking;
    IERC721 public lamex;

    bool public isPaused;

    uint256 public coolDownPeriod;

    mapping (address => bool) private _hasUserSwitched;
    mapping (address => uint256) public _accumulatedAtSwitch;
    mapping (address => uint256) public _accumulatedAtLamex;
    mapping (address => uint256) public _lastSwitch;

    mapping (address => bool) private _authorised;
    
    event SwitchYield(address indexed userAddress, bool toSeasonTwo);

    function initialize(address _loomi, address _staking, address _lamex) external initializer {
      loomi = ILoomi(_loomi);
      Staking = ILoomiSource(_staking);
      lamex = IERC721(_lamex);

      coolDownPeriod = 1 days;

      __Ownable_init();
      __ReentrancyGuard_init();
    }

    modifier whenNotPaused {
      require(!isPaused, "Contract paused!");
      _;
    }

    modifier onlyAuthorised {
      require(_authorised[_msgSender()], "Not authorised!");
      _;
    }

    function activateLamex(address _user) external whenNotPaused onlyAuthorised {
      _switchToLamex(_user);
    }

    function yieldLamex() public whenNotPaused {
      require(IERC721(lamex).balanceOf(_msgSender()) > 0, "Activate your lamex first");
      _switchToLamex(_msgSender());
    }

    function yieldLoomi() public whenNotPaused {
      require(_hasUserSwitched[_msgSender()], "Already yielding loomi");
      require(block.timestamp - _lastSwitch[_msgSender()] > coolDownPeriod, "Switch cool down period");

      uint256 accumulatedAmount = Staking.getAccumulatedAmount(_msgSender());
      _accumulatedAtLamex[_msgSender()] += accumulatedAmount - _accumulatedAtSwitch[_msgSender()];
      
      _hasUserSwitched[_msgSender()] = false;
      loomi.spendLoomi(_msgSender(), (accumulatedAmount - _accumulatedAtLamex[_msgSender()])); 

      emit SwitchYield(_msgSender(), false);
    }

    function _switchToLamex(address _user) internal {
      require(!_hasUserSwitched[_user], "Already yielding lamex");

      uint256 accumulatedAmount = Staking.getAccumulatedAmount(_user);
      
      _accumulatedAtSwitch[_user] = accumulatedAmount;
      _hasUserSwitched[_user] = true;
      _lastSwitch[_msgSender()] = block.timestamp;

      loomi.depositLoomiFor(_user, (accumulatedAmount - _accumulatedAtLamex[_msgSender()]));
      
      emit SwitchYield(_user, true);
    }


    function getAccumulatedAmount(address _user) public view returns (uint256) {
      if (_hasUserSwitched[_user]) return 0;
      return Staking.getAccumulatedAmount(_user) - _accumulatedAtLamex[_user];
    }

    function hasUserPortaled(address _user) public view returns (bool) {
      return _hasUserSwitched[_user];
    }

    /**
    * @dev Function allows admin to pause contract.
    */
    function pause(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    function authorise(address _address, bool _isAuth) public onlyOwner {
      _authorised[_address] = _isAuth;
    }

    function updateCoolDownPeriod(uint256 _newPeriod) public onlyOwner {
      coolDownPeriod = _newPeriod;
    }
    
}
