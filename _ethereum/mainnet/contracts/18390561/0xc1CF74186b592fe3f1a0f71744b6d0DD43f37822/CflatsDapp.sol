// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SafeERC20.sol";
import "./IAccessControl.sol";
import "./Harvest.sol";
import "./DappErrors.sol";
import "./ICflatsDapp.sol";
import "./ICflatsTerritory.sol";
import "./ICflatsStaking.sol";
import "./ICflatsDatabase.sol";
import "./CflatsDappRequirements.sol";


contract CflatsDapp is ICflatsDapp, CflatsDappRequirements, Harvest
{
    using SafeERC20 for IERC20;
    uint256 private constant _ONE_DAY = 86_400;


    // Attack payment plan for users who has the highest nft rarity of one of these
    // Attack can be done only gen by gen. Highest gen can't attach lower gen as well
    // as lower gen staker can't attach higher gen staker
    //
    // NOTE: Only stakers with rarity Silver to Diamond can make attack
    // Standart rarity users can only return tokens with 10%, 20%, 30% of chance
    uint256 public constant DEFAULT_ATTACK_PAYMENT_PLAN_SILVER  = 0.025 ether;
    uint256 public constant DEFAULT_ATTACK_PAYMENT_PLAN_GOLDEN  = 0.020 ether;
    uint256 public constant DEFAULT_ATTACK_PAYMENT_PLAN_DIAMOND = 0.015 ether;


    // Return payment plan is the same for each nft rarity
    uint256 public constant DEFAULT_RETURN_PAYMENT_PLAN_CHEAP  = 0.01 ether;
    uint256 public constant DEFAULT_RETURN_PAYMENT_PLAN_MEDIUM = 0.02 ether;
    uint256 public constant DEFAULT_RETURN_PAYMENT_PLAN_BEST   = 0.03 ether;


    // Staking contract
    ICflatsStaking private immutable _STAKING_CONTRACT;
    


    mapping(address fraudster => bool allowance) _allowanceToDoFraud;
    mapping(address victim => 
        mapping(address fraudster => bool allowance)
    ) _allowanceToPunishFraudster;
    mapping(address user => 
        mapping(DappStrategy strategy => PaymentPlan paymentPlan)
    ) _userPlan;
    
    mapping(address fraudster => 
        mapping(address victim => bool isVictim)
    ) private _isVictimOf;

    mapping(address user => bool isVictim) private _isVictim;
    mapping(address user => 
        mapping(DappStrategy strategy => TaxMultiplier multiplier)
    ) private _taxMultiplier;

    // amount that was stolen from victim
    mapping(address victim => 
        mapping(address fraudster => VictimReturn victimReturn)
    ) private _victimReturn;


    mapping(address victim => address[] fraudsters) private _victimFraudsters;




    constructor(
        ICflatsStaking stakingContract,
        ICflatsDatabase database
    ) CflatsDappRequirements(database)
    {
        _STAKING_CONTRACT = stakingContract;
    }



    function getAttackPaymentPlanByGen(
        address user,
        address gen
    )
        public
        view
        returns (PaymentPlan)
    {
        CflatsRarity rarity = _STAKING_CONTRACT.getUpperStakedRarityOf(user, gen);
        return PaymentPlan(uint8(rarity));
    }
    
    
    function getAttackPaymentValueByGen(
        address user,
        address gen
    )
        public
        view
        returns (uint256)
    {
        CflatsRarity rarity = _STAKING_CONTRACT.getUpperStakedRarityOf(user, gen);

        if(rarity == CflatsRarity.Silver)
        {
            return DEFAULT_ATTACK_PAYMENT_PLAN_SILVER * getTaxMultiplierOf(user, DappStrategy.ATTACK);
        }
        else if(rarity == CflatsRarity.Gold)
        {
            return DEFAULT_ATTACK_PAYMENT_PLAN_GOLDEN * getTaxMultiplierOf(user, DappStrategy.ATTACK);
        }
        else if(rarity == CflatsRarity.Diamond)
        {
            return DEFAULT_ATTACK_PAYMENT_PLAN_DIAMOND * getTaxMultiplierOf(user, DappStrategy.ATTACK);
        }

        return 0;
    }

    function getAttackPaymentPlanByValue(
        address user,
        uint256 value
    )
        public
        view
        returns (PaymentPlan)
    {
        if(value >= DEFAULT_ATTACK_PAYMENT_PLAN_SILVER * getTaxMultiplierOf(user, DappStrategy.ATTACK))
        {
            return PaymentPlan.CHEAP;
        }
        else if(value >= DEFAULT_ATTACK_PAYMENT_PLAN_GOLDEN * getTaxMultiplierOf(user, DappStrategy.ATTACK))
        {
            return PaymentPlan.MEDIUM;
        }
        else if(value >= DEFAULT_ATTACK_PAYMENT_PLAN_DIAMOND * getTaxMultiplierOf(user, DappStrategy.ATTACK))
        {
            return PaymentPlan.BEST;
        }

        return PaymentPlan.NO_PLAN;
    }


    function getReturnPaymentValueByPlan(address user, PaymentPlan paymentPlan)
        public
        view
        returns (uint256)
    {
        // by default setting expensive plan
        if(paymentPlan == PaymentPlan.CHEAP)
        {
            return DEFAULT_RETURN_PAYMENT_PLAN_CHEAP * getTaxMultiplierOf(user, DappStrategy.RETURN);
        }
        else if(paymentPlan == PaymentPlan.MEDIUM)
        {
            return DEFAULT_RETURN_PAYMENT_PLAN_MEDIUM * getTaxMultiplierOf(user, DappStrategy.RETURN);
        }
        if(paymentPlan == PaymentPlan.BEST)
        {
            return DEFAULT_RETURN_PAYMENT_PLAN_BEST * getTaxMultiplierOf(user, DappStrategy.RETURN);
        }

        return 0;
    }

    function getReturnPaymentPlanByValue(address user, uint256 value)
        public
        view
        returns (PaymentPlan)
    {
        if(value >= DEFAULT_RETURN_PAYMENT_PLAN_BEST * getTaxMultiplierOf(user, DappStrategy.RETURN))
        {
            return PaymentPlan.BEST;
        }
        else if(value >= DEFAULT_RETURN_PAYMENT_PLAN_MEDIUM * getTaxMultiplierOf(user, DappStrategy.RETURN))
        {
            return PaymentPlan.MEDIUM;
        }
        else if(value >= DEFAULT_RETURN_PAYMENT_PLAN_CHEAP * getTaxMultiplierOf(user, DappStrategy.RETURN))
        {
            return PaymentPlan.CHEAP;
        }

        return PaymentPlan.NO_PLAN;
    }


    function getTaxMultiplierOf(address user, DappStrategy strategy) public view returns (uint8)
    {
        TaxMultiplier memory taxMultiplier = _taxMultiplier[user][strategy];
        
        if(block.timestamp >= taxMultiplier._timer)
        {
            return 1;
        }

        return taxMultiplier._multplier == 0 ? 1 : taxMultiplier._multplier;
    }

    function getTaxMultiplierTimerOf(address user, DappStrategy strategy) public view returns (uint256)
    {
        return _taxMultiplier[user][strategy]._timer;
    }


    function getVictimFraudsters(address victim) external view returns (address[] memory)
    {
        return _victimFraudsters[victim];
    }



    function stolenAmountFrom(
        address victim,
        address fraudster
    ) 
        public
        view
        returns (uint256)
    {
        return _victimReturn[victim][fraudster]._stolenAmount;
    }

    function victimReturnTimer(
        address victim,
        address fraudster
    ) 
        public
        view
        returns (uint256)
    {
        return _victimReturn[victim][fraudster]._timer;
    }

    function canVictimReturnFrom(
        address fraudster,
        address victim
    ) public view returns (bool)
    {
        if(victimReturnTimer(victim, fraudster) < block.timestamp)
        {
            return false;
        }

        return true;
    }


    function allowedToDoFraud(address fraudster)
        public
        view
        returns (bool)
    {
        if(_userPlan[fraudster][DappStrategy.ATTACK] == PaymentPlan.NO_PLAN)
        {
            return false;
        }

        return _allowanceToDoFraud[fraudster];
    }


    function allowedToPunishFraudster(address victim, address fraudster) public view returns (bool)
    {
        if(_userPlan[victim][DappStrategy.RETURN] == PaymentPlan.NO_PLAN)
        {
            return false;
        }
        if(canVictimReturnFrom(fraudster, victim) == false)
        {
            return false;
        }

        return _allowanceToPunishFraudster[victim][fraudster];
    }


    function userPlan(address user, DappStrategy strategy) external view returns(PaymentPlan)
    {
        return _userPlan[user][strategy];
    }


    function isVictimOf(address fraudster, address victim) public view returns (bool)
    {
        return _isVictimOf[fraudster][victim];
    }

    function isVictim(address user) public view returns (bool)
    {
        return _isVictim[user];
    }


    function buyPlan(DappStrategy strategy) 
        external
        payable
        onlyNotBlacklisted
    {
        uint256 msgValue = msg.value;
        address msgSender = msg.sender;

        PaymentPlan plan;
        
        if(strategy == DappStrategy.ATTACK)
        {
            plan = getAttackPaymentPlanByValue(msgSender, msgValue);

            // allow user to do fraud
            _allowanceToDoFraud[msgSender] = true;
        }
        else if(strategy == DappStrategy.RETURN)
        {
            if(isVictim(msgSender) != true)
            {
                revert PaymentPlanReturnFundsRevertedError();
            }

            plan = getReturnPaymentPlanByValue(msgSender, msgValue);
        }

        // any plan required
        if(plan == PaymentPlan.NO_PLAN)
        {
            revert PaymentPlanError();
        }

        _setupTimerAndMultiplierFor(msgSender, strategy);
        _userPlan[msgSender][strategy] = plan;
    }


    // Functionality bellow can be realized only by operator
    // because probability is generated only off-chain
    function doFraud(
        address fraudster,
        address victim,
        uint256 stolenAmount,
        FraudStatus fraudStatus
    ) 
        external
        onlyOperator
    {
        if(allowedToDoFraud(fraudster) != true)
        {
            revert AllowedToDoFraudError();
        }

        if(fraudStatus != FraudStatus.SUCCESSFUL)
        {
            emit UnsucessfulFraud(fraudster);
            return;
        }

        // transferring staking rewards from victim to fraudster
        _STAKING_CONTRACT.transferRewards(victim, fraudster, stolenAmount);

        // recharge after successfull fraud
        _userPlan[fraudster][DappStrategy.ATTACK] = PaymentPlan.NO_PLAN;
        
        _victimReturn[victim][fraudster] = VictimReturn(
            stolenAmount,
            block.timestamp + _ONE_DAY
        );

        _isVictimOf[fraudster][victim] = true;
        _isVictim[victim] = true;
        _allowanceToPunishFraudster[victim][fraudster] = true;
        _victimFraudsters[victim].push(fraudster);

        delete _allowanceToDoFraud[fraudster];

        emit SuccessfulFraud(fraudster, victim, stolenAmount);
    }


    function punishFraudster(
        address fraudster,
        address victim,
        uint256 returnBonus,
        FraudStatus fraudStatus
    ) 
        external
        onlyOperator
    {
        if(allowedToPunishFraudster(victim, fraudster) != true)
        {
            revert AllowedToPunishFraudsterError(); 
        }
        
        if(fraudStatus != FraudStatus.SUCCESSFUL)
        {
            emit UnsucessfulPunish(victim, fraudster);
            return;
        }

        

        uint256 returnAmount = stolenAmountFrom(victim, fraudster) + returnBonus;
        
        // recharge after attempt
        delete _userPlan[victim][DappStrategy.RETURN];
        delete _victimReturn[victim][fraudster];
        delete _isVictimOf[fraudster][victim];
        delete _isVictim[victim];
        delete _allowanceToPunishFraudster[victim][fraudster];

        // transferring staking rewards from fraudster to victim
        _STAKING_CONTRACT.transferRewards(fraudster, victim, returnAmount);

        emit SuccessfulPunish(victim, fraudster, returnAmount);
    }



    function _setupTimerAndMultiplierFor(address user, DappStrategy strategy) private
    {
        uint8 multiplier = getTaxMultiplierOf(user, strategy);
        TaxMultiplier storage taxMultiplier = _taxMultiplier[user][strategy];

        if(multiplier != 1 && taxMultiplier._timer != 0)
        {
            taxMultiplier._timer = 0;
        }

        unchecked
        {
            taxMultiplier._multplier = ++multiplier;
        }
        if(taxMultiplier._timer == 0)
        {
            taxMultiplier._timer = block.timestamp + _ONE_DAY;
        }
    }
}
