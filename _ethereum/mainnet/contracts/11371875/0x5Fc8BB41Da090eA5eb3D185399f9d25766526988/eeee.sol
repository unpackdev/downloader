//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20Capped.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Math.sol";

// Eeee! Welcome Dolphins! 
//
//////////////////////////////////////////////////////////////////////
//                                       __                         //
//                                   _.-~  )    ____ eeee ____      //
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
//
// This code has not been audited, but has been reviewed. Hopefully it's bug free... 
// If you do find bugs, remember those were features and part of the game... Don't hate the player.
//
// Also, this token is a worthless game token. Don't buy it. Just farm it, and then play games. It will be fun. 
//
// Eeee! Let the games begin!

// eeee, hardcap set on deployment with minting to dev for subsequent deployment into DolphinPods (2x) & snatchFeeder
contract eeee is ERC20Capped, Ownable {
    using SafeMath for uint256;

    bool public _isGameActive;
    uint256 public _lastUpdated;
    uint256 public _coolDownTime;
    uint256 public _snatchRate;
    uint256 public _snatchPool;
    uint256 public _devFoodBucket;
    bool public _devCanEat;
    bool public _isAnarchy;
    uint256 public _orca;
	uint256 public _river;
	uint256 public _bottlenose;
	uint256 public _flipper = 42069e17;
	uint256 public _peter = 210345e17;
	address public _owner;
	address public _UniLP;
	uint256 public _lpMin;
	uint256 public _feeLevel1;
	uint256 public _feeLevel2;
    
    event Snatched(address indexed user, uint256 amount);

    constructor() public
        ERC20("dolphins.wtf", "EEEE")
        ERC20Capped(42069e18)
    {
        _isGameActive = false;
        _coolDownTime = 3600;
        _devCanEat = false;
        _isAnarchy = false;
        _snatchRate = 1;
        _orca = 69e18;
		_river = 42069e16;
		_bottlenose = 210345e16;
		_lpMin = 1;
		_UniLP = address(0);
		_feeLevel1 = 1e18;
		_feeLevel2 = 5e18;
		_owner = msg.sender;
        mint(msg.sender, 42069e18);
    }

    // levels: checks caller's balance to determine if they can access a function

    function uniLPBalance() public view returns (uint256) {
		IERC20 lpToken = IERC20(_UniLP);
        return lpToken.balanceOf(msg.sender);
	}
	
    function amILP() public view returns(bool) {
        require(_UniLP != address(0), "Eeee! The LP contract has not been set");
        return uniLPBalance() > _lpMin;
    } 

    function amIOrca() public view returns(bool) {
        return balanceOf(msg.sender) >= _orca || amILP();
    } 

    //  Orcas (are you even a dolphin?) - 69 (0.00164%); Can: Snatch tax base
    modifier onlyOrca() {
        require(amIOrca(), "Eeee! You're not even an orca");
        _;
    }

    function amIRiver() public view returns(bool) {
        return balanceOf(msg.sender) >= _river;
    } 

    // River Dolphin (what is wrong with your nose?) - 420.69 (1%); Can: turn game on/off
    modifier onlyRiver() {
        require(amIRiver(), "You're not even a river dolphin");
        _;
    }

    function amIBottlenose() public view returns(bool) {
        return balanceOf(msg.sender) >= _bottlenose;
    } 

    // Bottlenose Dolphin  (now that's a dolphin) - 2103.45 (5%); Can: Change tax rate (up to 2.5%); Devs can eat (allows dev to withdraw from the dev food bucket)
    modifier onlyBottlenose() {
        require(amIBottlenose(), "You're not even a bottlenose dolphin");
        _;
    }

    function amIFlipper() public view returns(bool) {
        return balanceOf(msg.sender) >= _flipper;
    } 

    // Flipper (A based dolphin) - 4206.9 (10%); Can: Change levels thresholds (except Flipper and Peter); Change tax rate (up to 10%); Change cooldown time
    modifier onlyFlipper() {
        require(amIFlipper(), "You're not flipper");
        _;
    }

    function amIPeter() public view returns(bool) {
        return balanceOf(msg.sender) >= _peter;
    } 

    // Peter the Dolphin (ask Margaret Howe Lovatt) - 21034.5 (50%); Can: Burn the key and hand the world over to the dolphins, and stops feeding the devs
    modifier onlyPeter() {
        require(amIPeter(), "You're not peter the dolphin");
        _;
    }

    // Are you the dev?
    modifier onlyDev() {
        require(address(msg.sender) == _owner, "You're not the dev, get out of here");
        _;
    }

    modifier cooledDown() {
        require(now > _lastUpdated.add(_coolDownTime));
        _;
    }
    
    // snatch - grab from snatch pool, requires min 0.01 EEEE in snatchpool -- always free
    function snatchFood() public onlyOrca cooledDown {
        require(_snatchPool >= 1 * 1e16, "snatchpool: min snatch amount (0.01 EEEE) not reached.");
        // check that the balance left in the contract is not less than the amount in the snatchPool, in case of rounding errors
        uint256 effectiveSnatched = balanceOf(address(this)) < _snatchPool ? balanceOf(address(this)) : _snatchPool;

        this.transfer(msg.sender, effectiveSnatched);

        _snatchPool = 0;
        emit Snatched(msg.sender, effectiveSnatched);
    }
    
    // Add directly to the snatchpool, if the caller is not the dev then set to cooldown
    function depositToSnatchPool(uint256 EEEEtoSnatchPool) public {
        transfer(address(this), EEEEtoSnatchPool);
        _snatchPool = _snatchPool.add(EEEEtoSnatchPool);
        if (address(msg.sender) != _owner) {
            _lastUpdated = now;
        }
        
    }

    function depositToDevFood(uint256 EEEEtoDevFood) public {
        transfer(address(this), EEEEtoDevFood);
        _devFoodBucket = _devFoodBucket.add(EEEEtoDevFood);
    }

    // startGame -- call fee level 1
    function startGame() public onlyRiver cooledDown {
        require(!_isGameActive, "Eeee! The game has already started");
        transfer(address(this), _feeLevel1);
        // because the game doesn't turn on until after this call completes we need to manually add to snatch
        callsAlwaysPaySnatch(_feeLevel1);
        _isGameActive = true;
        _lastUpdated = now;
    }

    // pauseGame -- call fee level 1
    function pauseGame() public onlyRiver cooledDown {
        require(_isGameActive, "Eeee! The game has already been paused");
		transfer(address(this), _feeLevel1);
        _isGameActive = false;
        _lastUpdated = now;
    }

    // all payed function calls should pay snatch, even if the game is off
    function callsAlwaysPaySnatch (uint256 amount) internal {
        if (!_isGameActive) {
            _snatch(amount);
        }
    }

    // allowDevToEat - can only be turned on once  -- call fee level 1
    function allowDevToEat() public onlyBottlenose {
        require(!_devCanEat, "Eeee! Too late sucker, dev's eating tonight");
		transfer(address(this), _feeLevel1);
        callsAlwaysPaySnatch(_feeLevel1);
        _devCanEat = true;
		_lastUpdated = now;
    }

    // changeSnatchRate - with max of 3% if Bottlenose; with max of 10% if Flipper -- call fee level 2
    function changeSnatchRate(uint256 newSnatchRate) public onlyBottlenose cooledDown {
        if (amIFlipper()) {
            require(newSnatchRate >= 1 && newSnatchRate <= 10, "Eeee! Minimum snatchRate is 1%, maximum is 10%.");
        } else {
            require(newSnatchRate >= 1 && newSnatchRate <= 3, "Eeee! Minimum snatchRate is 1%, maximum 10% for Flipper");
        }
        transfer(address(this), _feeLevel2);
		callsAlwaysPaySnatch(_feeLevel2);
        _snatchRate = newSnatchRate;
		_lastUpdated = now;
    }

    // changeCoolDownTime - make the game go faster or slower, cooldown to be set in hours (min 1; max 24) -- call fee level 2
    function updateCoolDown(uint256 newCoolDown) public onlyFlipper cooledDown {
        require(_isGameActive, "Eeee! You need to wait for the game to start first");
        require(newCoolDown <= 24 && newCoolDown >= 1, "Eeee! Minimum cooldown is 1 hour, maximum is 24 hours");
        transfer(address(this), _feeLevel2);
		callsAlwaysPaySnatch(_feeLevel2);
        _coolDownTime = newCoolDown * 1 hours;
        _lastUpdated = now;
    }

    // functions to change levels, caller should ensure to calculate this on 1e18 basis -- call fee level 1 * sought change
    function getSizeChangeFee(uint256 currentThreshold, uint256 newThreshold) private pure returns (uint256) {
        require (currentThreshold != newThreshold, 'this is already the threshold');
        return currentThreshold > newThreshold ? currentThreshold.sub(newThreshold) : newThreshold.sub(currentThreshold);
    }
    
    function updateOrca(uint256 updatedThreshold) public onlyFlipper {
        uint256 changeFee = getSizeChangeFee(_orca, updatedThreshold);
        require(balanceOf(msg.sender) >= changeFee, "Eeee! You don't have enough EEEE to make this change.");
		require(updatedThreshold >= 1e18 && updatedThreshold <= 99e18, "Threshold for Orcas must be 1 to 99 EEEE");
        require(updatedThreshold < _river, "Threshold for Orcas must be less than River Dolphins");
        _orca = updatedThreshold;
        transfer(address(this), changeFee);
		callsAlwaysPaySnatch(changeFee);
        _lastUpdated = now;
    }
    
    function updateRiver(uint256 updatedThreshold) public onlyFlipper {
        uint256 changeFee = getSizeChangeFee(_river, updatedThreshold);
        require(balanceOf(msg.sender) >= changeFee, "Eeee! You don't have enough EEEE to make this change.");
		require(updatedThreshold >= 1e18 && updatedThreshold <= 210345e16, "Threshold for River Dolphins must be 1 to 2103.45 EEEE");
        require(updatedThreshold > _orca && updatedThreshold < _bottlenose, "Threshold for River Dolphins must great than River Dolphins *and* less than Bottlenose Dolphins");
        _river = updatedThreshold;
		transfer(address(this), changeFee);
		callsAlwaysPaySnatch(changeFee);
        _lastUpdated = now;
    }
    
    function updateBottlenose(uint256 updatedThreshold) public onlyFlipper {
        uint256 changeFee = getSizeChangeFee(_bottlenose, updatedThreshold);
        require(balanceOf(msg.sender) >= changeFee, "Eeee! You don't have enough EEEE to make this change.");
		require(updatedThreshold >= 1e18 && updatedThreshold <= 42069e17, "Threshold for Bottlenose Dolphins must be 1 to 4206.9 EEEE");
        require(updatedThreshold > _river, "Threshold for Bottlenose Dolphins must great than River Dolphins");
        _bottlenose = updatedThreshold;
		transfer(address(this), changeFee);
		callsAlwaysPaySnatch(changeFee);
        _lastUpdated = now;
    }

    // dolphinAnarchy - transfer owner permissions to 0xNull & stops feeding dev. CAREFUL: this cannot be undone and once you do it the dolphins swim alone.  -- call fee level 2
    function activateAnarchy() public onlyPeter {
        //Return anything in dev pool to snatchpool
        transfer(address(this), _feeLevel2);
		callsAlwaysPaySnatch(_feeLevel2);
        _snatchPool = _snatchPool.add(_devFoodBucket);
        _devFoodBucket = 0;
        _isAnarchy = true; // ends dev feeding
        _owner = address(0);
        _lastUpdated = now;
    }


    // transfers tokens to snatchSupply and fees paid to dev (5%) only when we have not descended into Dolphin BASED anarchy
    function _snatch(uint256 amount) internal {
        // check that the amount is at least 5e-18 eeee, otherwise throw it all in the snatchpool
        if (amount >= 5) {
        uint256 devFood;
            devFood = _isAnarchy ? 0 : amount.mul(5).div(100); // 5% put in a food bucket for the contract creator if we've not descended into dolphin anarchy
            uint256 snatchedFood = amount.sub(devFood);
            _snatchPool = _snatchPool.add(snatchedFood);
            _devFoodBucket = _devFoodBucket.add(devFood);
        } else {
            _snatchPool = _snatchPool.add(amount);
        }
    }

    function _calcSnatchAmount (uint256 amount) internal view returns (uint256) {
        if (_isGameActive) {
            // calculate the snatched amount to be transfered if the game is active
            return (amount.mul(_snatchRate).div(100));
        } else {
            return 0;
        }
    }

    // Need the _transfer function to break at _beforeTokenTransfer to do a second transfer to this contract for SnatchPool & DevFood, but if 
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        super._beforeTokenTransfer(sender, recipient, amount);

        // This function should only do anything if the game is active, otherwise it should allow normal transfers
        if (_isGameActive) {
            // TO DO, make sure that transfers from Uniswap LP pool adhere to this
            // Don't snatch transfers from the Uniswap LP pool (if set)
            if (_UniLP != address(sender)) {
                // A first call to _transfer (where the recipient isn't this contract will create a second transfer to this contract
                if (recipient != address(this)) {
                    //calculate snatchAmount
                    uint256 amountToSnatch = _calcSnatchAmount(amount);
                    // This function checks that the account sending funds has enough funds (transfer amount + snatch amount), otherwise reverts
                    require(balanceOf(sender).sub(amount).sub(amountToSnatch) >= 0, "ERC20: transfer amount with snatch cost exceeds balance, send less");
                    // allocate amountToSnatch to snatchPool and devFoodBucket
                    _snatch(amountToSnatch);
                    // make transfer from sender to this address
                    _transfer(sender, address(this), amountToSnatch);
                } 
            }
            // After this, the normal function continues, and makes amount transfer to intended recipient
        }
    }
    
    // feedDev - allows owner to withdraw 5% thrown into dev food buck. Must only be called by the Dev.
    function feedDev() public onlyDev {
        require(_devCanEat, "sorry dev, no scraps for you");
        // check that the balance left in the contract is not less than the amount in the DevFoodBucket, in case of rounding errors
        if (balanceOf(address(this)) < _devFoodBucket) {
            transfer(msg.sender, balanceOf(address(this)));
        } else {
            transfer(msg.sender, _devFoodBucket);
        }
        _devFoodBucket = 0;
    }
	
	// change fees for function calls, can only be triggered by Dev, and then enters cooldown
	function changeFunctionFees(uint256 newFeeLevel1, uint256 newFeeLevel2) public onlyDev {
		_feeLevel1 = newFeeLevel1;
		_feeLevel2 = newFeeLevel2;
		_lastUpdated = now;
	}
	
	function setLP(address addrUniV2LP, uint256 lpMin) public onlyDev {
		_UniLP = addrUniV2LP;
		_lpMin = lpMin;
	}

    function mint(address _to, uint256 amount) public onlyDev {
        _mint(_to, amount);
    }
}