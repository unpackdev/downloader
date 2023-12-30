pragma solidity ^0.6.0;

import "./ISubscriptions.sol";
import "./Static.sol";
import "./MCDMonitorProxy.sol";
import "./ConstantAddresses.sol";
import "./GasTokenInterface.sol";
import "./DSMath.sol";

/// @title Implements logic that allows bots to call Boost and Repay
contract MCDMonitor is ConstantAddresses, DSMath, Static {

    uint constant public REPAY_GAS_TOKEN = 30;
    uint constant public BOOST_GAS_TOKEN = 19;

    uint constant public MAX_GAS_PRICE = 40000000000; // 40 gwei

    uint public REPAY_GAS_COST = 1800000;
    uint public BOOST_GAS_COST = 1250000;

    MCDMonitorProxy public monitorProxyContract;
    ISubscriptions public subscriptionsContract;
    GasTokenInterface gasToken = GasTokenInterface(GAS_TOKEN_INTERFACE_ADDRESS);
    address public owner;
    address public mcdSaverProxyAddress;

    /// @dev Addresses that are able to call methods for repay and boost
    mapping(address => bool) public approvedCallers;

    event CdpRepay(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio);
    event CdpBoost(uint indexed cdpId, address indexed caller, uint amount, uint beforeRatio, uint afterRatio);

    modifier onlyApproved() {
        require(approvedCallers[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor(address _monitorProxy, address _subscriptions, address _mcdSaverProxyAddress) public {
        approvedCallers[msg.sender] = true;
        owner = msg.sender;

        monitorProxyContract = MCDMonitorProxy(_monitorProxy);
        subscriptionsContract = ISubscriptions(_subscriptions);
        mcdSaverProxyAddress = _mcdSaverProxyAddress;
    }

    /// @notice Bots call this method to repay for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _cdpId Id of the cdp
    /// @param _amount Amount of Eth to convert to Dai
    /// @param _exchangeType Which exchange to use, 0 is to select best one
    /// @param _collateralJoin Address of collateral join for specific CDP
    function repayFor(uint _cdpId, uint _amount, address _collateralJoin, uint _exchangeType) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= BOOST_GAS_TOKEN) {
            gasToken.free(BOOST_GAS_TOKEN);
        }


        uint ratioBefore;
        bool canCall;
        (canCall, ratioBefore) = subscriptionsContract.canCall(Method.Repay, _cdpId);
        require(canCall);

        uint gasCost = calcGasCost(REPAY_GAS_COST);

        monitorProxyContract.callExecute(subscriptionsContract.getOwner(_cdpId), mcdSaverProxyAddress, abi.encodeWithSignature("repay(uint256,address,uint256,uint256,uint256,uint256)", _cdpId, _collateralJoin, _amount, 0, _exchangeType, gasCost));

        uint ratioAfter;
        bool ratioGoodAfter;
        (ratioGoodAfter, ratioAfter) = subscriptionsContract.ratioGoodAfter(Method.Repay, _cdpId);
        // doesn't allow user to repay too much
        require(ratioGoodAfter);

        emit CdpRepay(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }

    /// @notice Bots call this method to boost for user when conditions are met
    /// @dev If the contract ownes gas token it will try and use it for gas price reduction
    /// @param _cdpId Id of the cdp
    /// @param _amount Amount of Dai to convert to Eth
    /// @param _exchangeType Which exchange to use, 0 is to select best one
    /// @param _collateralJoin Address of collateral join for specific CDP
    function boostFor(uint _cdpId, uint _amount, address _collateralJoin, uint _exchangeType) public onlyApproved {
        if (gasToken.balanceOf(address(this)) >= REPAY_GAS_TOKEN) {
            gasToken.free(REPAY_GAS_TOKEN);
        }

        uint ratioBefore;
        bool canCall;
        (canCall, ratioBefore) = subscriptionsContract.canCall(Method.Boost, _cdpId);
        require(canCall);

        uint gasCost = calcGasCost(BOOST_GAS_COST);

        monitorProxyContract.callExecute(subscriptionsContract.getOwner(_cdpId), mcdSaverProxyAddress, abi.encodeWithSignature("boost(uint256,address,uint256,uint256,uint256,uint256)", _cdpId, _collateralJoin, _amount, 0, _exchangeType, gasCost));

        uint ratioAfter;
        bool ratioGoodAfter;
        (ratioGoodAfter, ratioAfter) = subscriptionsContract.ratioGoodAfter(Method.Boost, _cdpId);
        // doesn't allow user to boost too much
        require(ratioGoodAfter);

        emit CdpBoost(_cdpId, msg.sender, _amount, ratioBefore, ratioAfter);
    }

    /// @notice Calculates gas cost (in Eth) of tx
    /// @dev Gas price is limited to MAX_GAS_PRICE to prevent attack of draining user CDP
    /// @param _gasAmount Amount of gas used for the tx
    function calcGasCost(uint _gasAmount) internal view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }

/******************* OWNER ONLY OPERATIONS ********************************/

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

    /// @notice Adds a new bot address which will be able to call repay/boost
    /// @param _caller Bot address
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    /// @notice Removes a bot address so it can't call repay/boost
    /// @param _caller Bot address
    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }

    /// @notice If any tokens gets stuck in the contract owner can withdraw it
    /// @param _tokenAddress Address of the ERC20 token
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        ERC20(_tokenAddress).transfer(_to, _amount);
    }

    /// @notice If any Eth gets stuck in the contract owner can withdraw it
    /// @param _to Address of the receiver
    /// @param _amount The amount to be sent
    function transferEth(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}
