// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IKeep3rV1Mini.sol";

interface IBACFarmer {
  function getRewards (  ) external;
  function takeProfits (  ) external;
}

contract BCAFarmerRelayerv2 is Ownable {
    using SafeMath for uint256;

    IKeep3rV1Mini public RLR;
    IBACFarmer public iBACFarm;

    uint256 public lastHarvest = 0;
    uint256 public harvestInterval = 2 hours;

    modifier upkeep() {
        require(RLR.isKeeper(msg.sender), "::isKeeper: relayer is not registered");
        _;
        RLR.worked(msg.sender);
        lastHarvest = block.timestamp;
    }

    //Use this to depricate this job to move rlr to another job later
    function destructJob() public onlyOwner {
     //Get the credits for this job first
     uint256 currRLRCreds = RLR.credits(address(this),address(RLR));
     uint256 currETHCreds = RLR.credits(address(this),RLR.ETH());
     //Send out RLR Credits if any
     if(currRLRCreds > 0) {
        //Invoke receipt to send all the credits of job to owner
        RLR.receipt(address(RLR),owner(),currRLRCreds);
     }
     //Send out ETH credits if any
     if (currETHCreds > 0) {
        RLR.receiptETH(owner(),currETHCreds);
     }
     //Finally self destruct the contract after sending the credits
     selfdestruct(payable(owner()));
    }

    function updateFarmer(address farmer) public onlyOwner {
        iBACFarm = IBACFarmer(farmer);
        lastHarvest = 0;
    }

    function updateHarvestInterval(uint256 newInterval) public onlyOwner {
        harvestInterval = newInterval;
    }

    //Init interfaces with addresses
    constructor (address token,address farmer) public {
        RLR = IKeep3rV1Mini(token);
        iBACFarm = IBACFarmer(farmer);
    }

    function workable() public view returns (bool) {
        return (block.timestamp - lastHarvest) > harvestInterval;
    }

    function work() public upkeep {
        require(workable(),"!workable");
        iBACFarm.takeProfits();
    }

}