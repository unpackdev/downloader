
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Adapted from SushiSwap's MasterChef contract
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./eeee.sol";

// snatchFeeder is one of the elements of dolphins.wtf.
// It can be funded, started and stopped (e.g. by her majesty the Cetacean Queen's devs)
// A call to the snatchFeeder can be made *by anyone* to send eeee to the snatchpool
// Once received by the snatchPool, no one can feed from the snatchPool during the cooldown period (1 hour)
// Calls to the snatchFeeder can only be made once per hour.
//
//////////////////////////////////////////////////////////////////////
//                                       __                         //
//                                   _.-~  ) ___ snatchFeeder ____  //
//                        _..--~~~~,'   ,-/     _                   //
//                     .-'. . . .'   ,-','    ,' )                  //
//                   ,'. . . _   ,--~,-'__..-'  ,'                  //
//                 ,'. . .  (@)' ---~~~~      ,'                    //
//                /. . . . '~~             ,-'                      //
//               /. . . . .             ,-'                         //
//              ; . . . .  - .        ,'                            //
//             : . . . .       _     /                              //
//            . . . . .          `-.:                               //
//           . . . ./  - .          )                               //
//          .  . . |  _____..---.._/ ____ dolphins.wtf ____         //
//~---~~~~-~~---~~~~----~~~~-~~~~-~~---~~~~----~~~~~~---~~~~-~~---~~//
//                                                                  //
//////////////////////////////////////////////////////////////////////

contract snatchFeeder is Ownable {
    using SafeMath for uint256;

    eeee    public _eeee;
    uint256 public _coolDownTime = 1 hours;
    uint256 public _feedAmount = 69e17; //6.9 EEEE released per snatch
    bool    public _snatchingStarted;
    uint256 public _feedStock;
    uint256 public _lastUpdated;

    event Deposit(address indexed user, uint256 amount);
    event FundSnatch(address indexed user, uint256 amount);

    constructor (eeee dolphinToken) public {
        _eeee = dolphinToken;
        _snatchingStarted = true;
    }

    modifier snatchingStarted() {
        require(_snatchingStarted, "you must wait for snatching to begin");
        _;
    }

    modifier cooledDown() {
        require(now > (_lastUpdated+_coolDownTime), "you must wait one hour for the fundSnatch feature to cooldown");
        _;
    }

    function deposit(uint256 _amount) public {
        if(_amount > 0) {
            _eeee.transferFrom(address(msg.sender), address(this), _amount);
            _feedStock = _feedStock.add(_amount);
        }
        emit Deposit(msg.sender, _amount);
    }

    function fundSnatch() public snatchingStarted cooledDown {
        require(_feedStock > 0, 'The funds have been fully snatched');
        uint256 _feedToSnatch = _feedStock >= _feedAmount ? _feedAmount : _feedStock;

        _eeee.depositToSnatchPool(_feedToSnatch);
        _feedStock = _feedStock.sub(_feedToSnatch);

        if(_feedStock == 0) {
            // if the last snatch amount took balance to zero then stop snatching
            _snatchingStarted = false;
        }
        
        _lastUpdated = now;
        emit FundSnatch(msg.sender, _feedStock);
    }

    function startSnatching() public onlyOwner {
        _feedStock = _eeee.balanceOf(address(this));
        require(_feedStock > 0, "You must deposit eeee before starting snatching");
        _snatchingStarted = true;
    }

    function endSnatching() public onlyOwner {
        _snatchingStarted = false;
    }


}