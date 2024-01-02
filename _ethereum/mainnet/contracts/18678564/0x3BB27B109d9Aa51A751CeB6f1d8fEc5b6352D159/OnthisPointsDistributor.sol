// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract OnthisPointsDistributor is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{

    struct Shortcut {
        address[] creators;
        uint256 complexity;
        bool isActive;
    }

    event RegisteredShortcut(address addr, Shortcut shortcut);
    event PointsClaimed(uint256 amount, address user);
    event UserPointsDistributed(
        address user,
        uint256 usersAmount,
        uint256 volume
    );
    event CreatorsPointsDistributed(address creator, uint256 creatorsAmount);
    event MultiplierDeltaChanged(uint256 newDelta, uint256 ts);
    event DistributionEnded(uint256 ts);

    mapping(address => Shortcut) public shortcuts;
    mapping(address => uint256) public usersPoints;

    uint256 public usersSplit;
    uint256 public creatorsSplit;
    uint256 public decreaseDeltaVolume;
    uint256 public totalShortcutsVolume;
    uint256 public multiplierDelta;
    uint256 public shortcutBaseFee;
    address public feeDestination;
    uint256 public currentStageVolume;
    address public onthisToken;
    bool public isPointDistributionActive;

    uint256[50] private _gap;

    function initialize(
        uint256 initialUserSplit,
        uint256 initialCreatorsSplit,
        uint256 _multiplierDelta,
        address initialFeeDestination
    ) public initializer {
        usersSplit = initialUserSplit;
        creatorsSplit = initialCreatorsSplit;
        feeDestination = initialFeeDestination;
        multiplierDelta = _multiplierDelta;
        isPointDistributionActive = true;   
        decreaseDeltaVolume = 1 ether;
        shortcutBaseFee = 1000;
        __Ownable_init();
    }

    function getShortcutCreators(
        address shortcut
    ) public view returns (address[] memory creators) {
        return shortcuts[shortcut].creators;
    }

    function resetMultiplierDelta(uint256 newMultiplierDelta) public onlyOwner {
        multiplierDelta = newMultiplierDelta;
    }

    function setOnthisTokenContract(address _onthisToken) public onlyOwner {
        onthisToken = _onthisToken;
    }

    function changeFeeDestination(address _newFeeDestination) public onlyOwner {
        feeDestination = _newFeeDestination;
    }

    function changeBaseFee(uint256 _newFee) public onlyOwner {
        shortcutBaseFee = _newFee;
    }

    function changeCreatorSplit(uint256 newCreatorsSplit) public onlyOwner {
        creatorsSplit = newCreatorsSplit;
    }

    function changeUsersSplit(uint256 newUsersSplit) public onlyOwner {
        usersSplit = newUsersSplit;
    }

    function disableShortcut(address _shortcutAddr) public onlyOwner {
        shortcuts[_shortcutAddr].isActive = false;
    }

    function enableShortcut(address _shortcutAddr) public onlyOwner {
        shortcuts[_shortcutAddr].isActive = true;
    }

    function registerShortcut(
        address _shortcutAddr,
        Shortcut memory _shortcut
    ) public onlyOwner {
        shortcuts[_shortcutAddr] = _shortcut;
 
        emit RegisteredShortcut(_shortcutAddr, _shortcut);
    }

    function _validateEmissionMultiplier(uint256 amount) private {
        currentStageVolume += amount;
        if (currentStageVolume >= decreaseDeltaVolume) {
            unchecked {
                currentStageVolume = 0;
                multiplierDelta -= 2;
            }
        }
        if (multiplierDelta <= 100) {
            isPointDistributionActive = false;
            emit DistributionEnded(block.timestamp);
        }

        emit MultiplierDeltaChanged(multiplierDelta, block.timestamp);
    }

    function afterTokenClaim() public nonReentrant {
        require(
            msg.sender == onthisToken,
            "OnthisPointsDistrubutor: !icoContract"
        );

        uint256 points = usersPoints[tx.origin];
        usersPoints[tx.origin] = 0;

        emit PointsClaimed(points, tx.origin);
    }

    function _addCreatorsPoints(
        address[] memory creators,
        uint256 points
    ) private {
        uint length = creators.length;
        uint256 part = points / length;

        for (uint256 i = 0; i < length; ) {
            usersPoints[creators[i]] += part;

            emit CreatorsPointsDistributed(creators[i], part);
            unchecked {
                i++;
            }
        }
    }
    function disablePointsDistribution(bool active) public onlyOwner {
        isPointDistributionActive = active;
    }
    function distributePoints(uint256 amount) public nonReentrant {
        require(
            isPointDistributionActive,
            "OnthisPointsDistrubutor: points distribution has been ended"
        );
        Shortcut memory shortcut = shortcuts[msg.sender];

        if (shortcut.creators.length == 0) {
            revert("OnthisPointsDistrubutor: shortcut does not registered");
        }
        if (!shortcut.isActive) {
            revert("OnthisPointsDistrubutor: shortcut is disabled");
        }

        (uint256 userPoints, uint256 creatorsPoints) = calculatePoints(
            amount,
            shortcut.complexity
        );

        unchecked {
            usersPoints[tx.origin] += userPoints;
            totalShortcutsVolume += amount;
        }

        _addCreatorsPoints(shortcut.creators, creatorsPoints);
        _validateEmissionMultiplier(amount);

        emit UserPointsDistributed(tx.origin, userPoints, amount);
    }

    function calculatePoints(
        uint256 amount,
        uint256 shortcutMultiplier
    ) public view returns (uint256 userAmount, uint256 creatorAmount) {
        uint256 totalBonus = amount * shortcutMultiplier * multiplierDelta;
        
        userAmount = (totalBonus * usersSplit) / 100;
        creatorAmount = (totalBonus * creatorsSplit) / 100;

        return (userAmount, creatorAmount);
    }
}
