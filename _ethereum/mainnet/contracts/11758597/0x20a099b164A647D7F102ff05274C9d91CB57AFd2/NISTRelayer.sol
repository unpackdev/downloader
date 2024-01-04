// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./INitroStaking.sol";
import "./IChainLinkFeed.sol";
import "./IKeep3rV1Mini.sol";

contract NISTRelayer is Ownable {
    using SafeMath for uint256;
    //Params for reward bonus and interval
    uint256 public distributeInterval = 2 hours;
    //Requirements for the relayer executing
    uint public minBond = 500 ether;
    uint public minEarned = 0;
    uint public minAge = 0;
    //Amount of users to reward each cycle
    uint256 public stakersPerRun = 10;

    uint internal _gasUsed;

    uint constant public MIN = 11;
    uint constant public MAX = 12;
    uint constant public BASE = 10;
    uint public TARGETBOND = 2500 ether;

    IKeep3rV1Mini public RLR;
    INitroStaking public NIST;
    IChainLinkFeed public FASTGAS;

    constructor(address nisttoken, address rlrtoken, address gasoracle) public {
        RLR     = IKeep3rV1Mini(rlrtoken);
        NIST    = INitroStaking(nisttoken);
        FASTGAS = IChainLinkFeed(gasoracle);
    }

    receive() external payable {}

    function bonds(address keeper) public view returns (uint) {
        return RLR.bonds(keeper, address(RLR)).add(RLR.votes(keeper));
    }

    function calculateReward(uint __gasUsed,address origin,uint _gasPrice) public view returns (uint){
        uint _quote = (__gasUsed).mul(uint(_gasPrice));
        // console.log("Gas used : %s",__gasUsed);
        // console.log("Gas price : %s",_gasPrice);
        uint _min = _quote.mul(MIN).div(BASE);
        uint _boost = _quote.mul(MAX).div(BASE);
        uint _bond = Math.min(bonds(origin), TARGETBOND);
        return Math.max(_min, _boost.mul(_bond).div(TARGETBOND));
    }

    modifier upkeep() {
        _gasUsed = gasleft();
        // console.log(msg.sender);
        require(RLR.isMinKeeper(msg.sender, minBond, minEarned, minAge), "::isKeeper: relayer is not registered");
        _;
        uint gasPrice = Math.min(tx.gasprice, uint(FASTGAS.latestAnswer()));
        uint gasUsed = _gasUsed.sub(gasleft());
        //reward gas spent with 10% bonus as incentive
        uint keeperFee = calculateReward(gasUsed,msg.sender,gasPrice);
        // console.log(keeperFee);
        // console.log(RLR.credits(address(this), RLR.ETH()));
        require(keeperFee <= RLR.credits(address(this), RLR.ETH()),"Not enough ETH to pay back gas");
        //Reward relayer in eth
        RLR.receiptETH(msg.sender, keeperFee);
        uint256 newCreditbal = RLR.credits(address(this), RLR.ETH());
        //If we still have excess after paying the keeperfee,send it back to the nist contract
        // if(newCreditbal > 0)  RLR.receiptETH(address(NIST),newCreditbal);
    }

    // Change requirements and rewards
    function setDistributeInterval(uint256 newInterval) external onlyOwner {
        distributeInterval = newInterval;
    }

    function setMinBond(uint newminbond) external onlyOwner {
        minBond = newminbond;
    }

    function setTargetBond(uint newTarget) external onlyOwner {
        TARGETBOND = newTarget;
    }

    function setMinEarned(uint newMinEarned) external onlyOwner {
        minEarned = newMinEarned;
    }

    function setMinAge(uint newAge) external onlyOwner {
        minAge = newAge;
    }

    function setStakersPerRun(uint256 newCount) external onlyOwner {
        stakersPerRun = newCount;
    }

    function workable() public view returns (bool) {
        (address[] memory addrs,) = getData();
        return
         addrs.length > 0
         &&
         block.timestamp > NIST.previousRewardDistributionTimestamp().add(distributeInterval);
    }

    //Use this function to get data to pass to work
    function getData() public view returns (address[] memory eligible_addresses, uint256 total_reward){
        (eligible_addresses,total_reward) = NIST.getEligibleAddressesForAutomaticPayout(stakersPerRun);
    }
    function work(address[] memory stakers, uint256 tokens_to_liquidate) public upkeep {
        NIST.processAutoRewardPayouts(stakers,tokens_to_liquidate);
    }
}