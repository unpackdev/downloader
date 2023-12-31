// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IPointsDistributor.sol";
import "./PointsDistributor.sol";
import "./IAcross.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract AcrossBridgeBase is OwnableUpgradeable {
    address public constant BRIDGE = 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public rewardsContract;

    uint256 public decimal1;
    uint256 public decimal2;
    uint256 public percent1;
    uint256 public percent2;

    function changeConfig(
        uint256 newDec1,
        uint256 newDec2,
        uint256 newPercent1,
        uint256 newPercent2
    ) public onlyOwner {
        decimal1 = newDec1;
        decimal2 = newDec2;
        percent1 = newPercent1;
        percent2 = newPercent2;
    }

    function getHighRelayersFee(uint256 val) public view returns (int64) {
        if (val <= 0.1 ether) {
            return int64(int256((percent1 * 10 ** decimal1)));
        } else {
            return int64(int256((percent2 * 10 ** decimal2)));
        }
    }

    function _chargeFee(uint256 amount) internal returns (uint256) {
        address feeDestination = IPointsDistributor(rewardsContract)
            .feeDestination();
            
        uint256 shortcutComplexity = IPointsDistributor(rewardsContract)
            .shortcuts(address(this))
            .complexity;
        uint256 baseShortcutFee = IPointsDistributor(rewardsContract)
            .shortcutBaseFee();
        uint256 fee = (amount * shortcutComplexity) / baseShortcutFee;

        payable(feeDestination).transfer(fee);
        return fee;
    }


    function setPointsDistributorContract(
        address _rewardsContract
    ) public onlyOwner {
        rewardsContract = _rewardsContract;
    }

}
