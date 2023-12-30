pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Manager.sol";
import "./ISubscriptions.sol";
import "./MCDSaverProxy.sol";
import "./ConstantAddresses.sol";
import "./Vat.sol";
import "./Spotter.sol";

/// @title Handles subscriptions for automatic monitoring
contract Subscriptions is ISubscriptions, ConstantAddresses {

    bytes32 internal constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant BAT_ILK = 0x4241542d41000000000000000000000000000000000000000000000000000000;

    struct CdpHolder {
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        address owner;
        uint cdpId;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }

    CdpHolder[] public subscribers;
    mapping (uint => SubPosition) public subscribersPos;

    mapping (bytes32 => uint) public minLimits;

    address public owner;
    uint public changeIndex;

    Manager public manager = Manager(MANAGER_ADDRESS);
    Vat public vat = Vat(VAT_ADDRESS);
    Spotter public spotter = Spotter(SPOTTER_ADDRESS);
    MCDSaverProxy public saverProxy;

    event Subscribed(address indexed owner, uint cdpId);
    event Unsubscribed(address indexed owner, uint cdpId);
    event Updated(address indexed owner, uint cdpId);

    /// @param _saverProxy Address of the MCDSaverProxy contract
    constructor(address _saverProxy) public {
        owner = msg.sender;

        saverProxy = MCDSaverProxy(_saverProxy);

        minLimits[ETH_ILK] = 1700000000000000000;
        minLimits[BAT_ILK] = 1700000000000000000;
    }

    /// @dev Called by the DSProxy contract which owns the CDP
    /// @notice Adds the users CDP in the list of subscriptions so it can be monitored
    /// @param _cdpId Id of the CDP
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalBoost Ratio amount which boost should target
    /// @param _optimalRepay Ratio amount which repay should target
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");
        require(checkParams(manager.ilks(_cdpId), _minRatio, _maxRatio), "Must be correct params");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        CdpHolder memory subscription = CdpHolder({
                minRatio: _minRatio,
                maxRatio: _maxRatio,
                optimalRatioBoost: _optimalBoost,
                optimalRatioRepay: _optimalRepay,
                owner: msg.sender,
                cdpId: _cdpId
            });

        changeIndex++;

        if (subInfo.subscribed) {
            subscribers[subInfo.arrPos] = subscription;

            emit Updated(msg.sender, _cdpId);
        } else {
            subscribers.push(subscription);

            subInfo.arrPos = subscribers.length - 1;
            subInfo.subscribed = true;

            emit Subscribed(msg.sender, _cdpId);
        }
    }

    /// @notice Called by the users DSProxy
    /// @dev Owner who subscribed cancels his subscription
    function unsubscribe(uint _cdpId) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");

        _unsubscribe(_cdpId);
    }

    /// @dev Checks if the _owner is the owner of the CDP
    function isOwner(address _owner, uint _cdpId) internal view returns (bool) {
        return getOwner(_cdpId) == _owner;
    }

    /// @dev Checks limit for minimum ratio and if minRatio is bigger than max
    function checkParams(bytes32 _ilk, uint128 _minRatio, uint128 _maxRatio) internal view returns (bool) {
        if (_minRatio < minLimits[_ilk]) {
            return false;
        }

        if (_minRatio > _maxRatio) {
            return false;
        }

        return true;
    }

    /// @dev Gets CDP ratio, calls MCDSaverProxy for getting the ratio
    function getRatio(uint _cdpId) public override view returns (uint) {
        return saverProxy.getRatio(_cdpId, manager.ilks(_cdpId)) / (10 ** 18);
    }

    /// @notice Checks if Boost/Repay could be triggered for the CDP
    /// @dev Called by MCDMonitor to enforce the min/max check
    function canCall(Method _method, uint _cdpId) public override view returns(bool, uint) {
        SubPosition memory subInfo = subscribersPos[_cdpId];

        if (!subInfo.subscribed) return (false, 0);

        CdpHolder memory subscriber = subscribers[subInfo.arrPos];

        if (getOwner(_cdpId) != subscriber.owner) return (false, 0);

        uint currRatio = getRatio(_cdpId);

        if (_method == Method.Repay) {
            return (currRatio < subscriber.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > subscriber.maxRatio, currRatio);
        }
    }

    /// @dev Internal method to remove a subscriber from the list
    function _unsubscribe(uint _cdpId) internal {
        require(subscribers.length > 0, "Must have subscribers in the list");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        require(subInfo.subscribed, "Must first be subscribed");

        uint lastCdpId = subscribers[subscribers.length - 1].cdpId;

        SubPosition storage subInfo2 = subscribersPos[lastCdpId];
        subInfo2.arrPos = subInfo.arrPos;

        subscribers[subInfo.arrPos] = subscribers[subscribers.length - 1];
        subscribers.pop();

        changeIndex++;
        subInfo.subscribed = false;
        subInfo.arrPos = 0;

        emit Unsubscribed(msg.sender, _cdpId);
    }

    /// @notice Returns an address that owns the CDP
    /// @param _cdpId Id of the CDP
    function getOwner(uint _cdpId) public override view returns(address) {
        return manager.owns(_cdpId);
    }

    /// @dev After the Boost/Repay check if the ratio doesn't trigger another call
    function ratioGoodAfter(Method _method, uint _cdpId) public override view returns(bool, uint) {
        SubPosition memory subInfo = subscribersPos[_cdpId];
        CdpHolder memory subscriber = subscribers[subInfo.arrPos];

        uint currRatio = getRatio(_cdpId);

        if (_method == Method.Repay) {
            return (currRatio < subscriber.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > subscriber.minRatio, currRatio);
        }
    }

    /// @notice Helper method for the front to get all the info about the subscribed CDP
    function getSubscribedInfo(uint _cdpId) public override view returns(bool, uint128, uint128, uint128, uint128, address, uint coll, uint debt) {
        SubPosition memory subInfo = subscribersPos[_cdpId];

        if (!subInfo.subscribed) return (false, 0, 0, 0, 0, address(0), 0, 0);

        (coll, debt) = saverProxy.getCdpInfo(manager, _cdpId, manager.ilks(_cdpId));

        CdpHolder memory subscriber = subscribers[subInfo.arrPos];

        return (
            true,
            subscriber.minRatio,
            subscriber.maxRatio,
            subscriber.optimalRatioRepay,
            subscriber.optimalRatioBoost,
            subscriber.owner,
            coll,
            debt
        );
    }

    /// @notice Helper method for the front to get the information about the ilk of a CDP
    function getIlkInfo(bytes32 _ilk, uint _cdpId) public view returns(bytes32 ilk, uint art, uint rate, uint spot, uint line, uint dust, uint mat, uint par) {
        // send either ilk or cdpId
        if (_ilk == bytes32(0)) {
            _ilk = manager.ilks(_cdpId);
        }

        ilk = _ilk;
        (,mat) = spotter.ilks(_ilk);
        par = spotter.par();
        (art, rate, spot, line, dust) = vat.ilks(_ilk);
    }

    /// @notice Helper method to return all the subscribed CDPs
    function getSubscribers() public view returns (CdpHolder[] memory) {
        return subscribers;
    }


    ////////////// ADMIN METHODS ///////////////////

    /// @notice Admin function to change a min. limit for an asset
    function changeMinRatios(bytes32 _ilk, uint _newRatio) public {
        require(msg.sender == owner, "Must be owner");

        minLimits[_ilk] = _newRatio;
    }

    /// @notice Admin function to unsubscribe a CDP if it's owner transfered to a different addr
    function unsubscribeIfMoved(uint _cdpId) public override {
        require(msg.sender == owner, "Must be owner");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        if (subInfo.subscribed) {
            if (getOwner(_cdpId) != subscribers[subInfo.arrPos].owner) {
                _unsubscribe(_cdpId);
            }
        }

    }
}
