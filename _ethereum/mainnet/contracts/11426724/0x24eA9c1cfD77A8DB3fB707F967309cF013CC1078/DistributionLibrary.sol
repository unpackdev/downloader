pragma solidity >=0.6.6;

import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ICAVO.sol";

library DistributionLibrary {
    using SafeMath for uint;

    struct Data {
        mapping(address => uint) claimedAmountOf;
        mapping(address => uint) maxAmountOf;
        uint unlockBlock;
        uint32 blocksInPeriod;
    }

    function availableAmountOf(Data storage self, address account) internal view returns (uint) {
        if (self.unlockBlock == 0 || block.number <= self.unlockBlock || self.maxAmountOf[account] == 0) {
            return 0;
        }
        uint unlockedAmountPerPeriod = self.maxAmountOf[account].mul(10).div(100);
        uint unlockPeriodInBlocks = self.maxAmountOf[account].div(unlockedAmountPerPeriod).mul(self.blocksInPeriod);
        return Math.min(self.unlockBlock.add(unlockPeriodInBlocks), block.number)
            .sub(self.unlockBlock)
            .div(self.blocksInPeriod)
            .mul(unlockedAmountPerPeriod)
            .sub(self.claimedAmountOf[account]);
    }

    function start(Data storage self) internal {
        require(self.unlockBlock == 0 && msg.sender == ICAVO(address(this)).creator(), 'DistributionLibrary: FORBIDDEN');
        self.unlockBlock = block.number;
    }

    function claim(Data storage self, uint amount) internal {
        require(amount <= availableAmountOf(self, msg.sender), 'DistributionLibrary: OVERDRAFT');
        self.claimedAmountOf[msg.sender] = self.claimedAmountOf[msg.sender].add(amount);
        TransferHelper.safeTransfer(address(this), msg.sender, amount);
    }
}
