pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./GasBurner.sol";
import "./DSMath.sol";
import "./AdminAuth.sol";
import "./DefisaverLogger.sol";
import "./DFSExchangeData.sol";
import "./AaveMonitorProxyV2.sol";
import "./AaveSubscriptionsV2.sol";
import "./AaveSafetyRatioV2.sol";

/// @title Contract implements logic of calling boost/repay in the automatic system
contract AaveMonitorV2 is AdminAuth, DSMath, AaveSafetyRatioV2, GasBurner {

    using SafeERC20 for ERC20;

    string public constant NAME = "AaveMonitorV2";

    enum Method { Boost, Repay }

    uint public REPAY_GAS_TOKEN = 20;
    uint public BOOST_GAS_TOKEN = 20;

    uint public MAX_GAS_PRICE = 400000000000; // 400 gwei

    uint public REPAY_GAS_COST = 2000000;
    uint public BOOST_GAS_COST = 2000000;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant AAVE_MARKET_ADDRESS = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

    AaveMonitorProxyV2 public aaveMonitorProxy;
    AaveSubscriptionsV2 public subscriptionsContract;
    address public aaveSaverProxy;

    DefisaverLogger public logger = DefisaverLogger(DEFISAVER_LOGGER);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    /// @param _aaveMonitorProxy Proxy contracts that actually is authorized to call DSProxy
    /// @param _subscriptions Subscriptions contract for Aave positions
    /// @param _aaveSaverProxy Contract that actually performs Repay/Boost
    constructor(address _aaveMonitorProxy, address _subscriptions, address _aaveSaverProxy) public {
        aaveMonitorProxy = AaveMonitorProxyV2(_aaveMonitorProxy);
        subscriptionsContract = AaveSubscriptionsV2(_subscriptions);
        aaveSaverProxy = _aaveSaverProxy;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _user The actual address that owns the Aave position
    function repayFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user,
        uint256 _rateMode
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(REPAY_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "repay(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256)",
                AAVE_MARKET_ADDRESS,
                _exData,
                _rateMode,
                gasCost
            )
        );

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _user);
        require(isGoodRatio); // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveRepayV2", abi.encode(ratioBefore, ratioAfter));
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _exData Exchange data
    /// @param _user The actual address that owns the Aave position
    function boostFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user,
        uint256 _rateMode
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _user);
        require(isAllowed); // check if conditions are met

        uint256 gasCost = calcGasCost(BOOST_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "boost(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256)",
                AAVE_MARKET_ADDRESS,
                _exData,
                _rateMode,
                gasCost
            )
        );


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _user);
        require(isGoodRatio);  // check if the after result of the actions is good

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveBoostV2", abi.encode(ratioBefore, ratioAfter));
    }

/******************* INTERNAL METHODS ********************************/
    function returnEth() internal {
        // return if some eth left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

/******************* STATIC METHODS ********************************/

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by AaveMonitor to enforce the min/max check
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Aave position
    /// @return Boolean if it can be called and the ratio
    function canCall(Method _method, address _user) public view returns(bool, uint) {
        bool subscribed = subscriptionsContract.isSubscribed(_user);
        AaveSubscriptionsV2.AaveHolder memory holder = subscriptionsContract.getHolder(_user);

        // check if cdp is subscribed
        if (!subscribed) return (false, 0);

        // check if boost and boost allowed
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        uint currRatio = getSafetyRatio(AAVE_MARKET_ADDRESS, _user);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    /// @param _method Type of action to be called
    /// @param _user The actual address that owns the Aave position
    /// @return Boolean if the recent action preformed correctly and the ratio
    function ratioGoodAfter(Method _method, address _user) public view returns(bool, uint) {
        AaveSubscriptionsV2.AaveHolder memory holder;

        holder = subscriptionsContract.getHolder(_user);

        uint currRatio = getSafetyRatio(AAVE_MARKET_ADDRESS, _user);

        if (_method == Method.Repay) {
            return (currRatio < holder.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.minRatio, currRatio);
        }
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) public view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

    /// @notice As the code is new, have a emergancy admin saver proxy change
    function changeAaveSaverProxy(address _newAaveSaverProxy) public onlyAdmin {
        aaveSaverProxy = _newAaveSaverProxy;
    }

    /// @notice Allows owner to change gas cost for boost operation, but only up to 3 millions
    /// @param _gasCost New gas cost for boost method
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change gas cost for repay operation, but only up to 3 millions
    /// @param _gasCost New gas cost for repay method
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    /// @notice Allows owner to change max gas price
    /// @param _maxGasPrice New max gas price
    function changeMaxGasPrice(uint _maxGasPrice) public onlyOwner {
        require(_maxGasPrice < 500000000000);

        MAX_GAS_PRICE = _maxGasPrice;
    }

    /// @notice Allows owner to change gas token amount
    /// @param _gasTokenAmount New gas token amount
    /// @param _repay true if repay gas token, false if boost gas token
    function changeGasTokenAmount(uint _gasTokenAmount, bool _repay) public onlyOwner {
        if (_repay) {
            REPAY_GAS_TOKEN = _gasTokenAmount;
        } else {
            BOOST_GAS_TOKEN = _gasTokenAmount;
        }
    }
}
