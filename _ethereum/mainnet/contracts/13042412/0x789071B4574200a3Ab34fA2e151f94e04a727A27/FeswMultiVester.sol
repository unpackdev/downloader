// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint128 x, uint128 y) internal pure returns (uint128 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint128 x, uint128 y) internal pure returns (uint128 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IFeswap {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}

contract FeswMultiVester {
    using SafeMath for uint128;

    struct VesterInfo {
        uint128 vestingAmount;
        uint32 vestingBegin;
        uint32 vestingCliff;
        uint32 vestingEnd;
        uint32 lastClaimTime;
    }

    address public Fesw;
    address public owner;
    address public recipient;
 
    uint64 public numTotalVester;
    uint64 public noVesterClaimable;

   // Mapping VesterInfoID to the Vester
    mapping (uint64 => VesterInfo) public allVesters;

    constructor(address Fesw_, address recipient_) {    
        owner = msg.sender;
        Fesw = Fesw_;
        recipient = recipient_;
    }

    receive() external payable { }  

    function setOwner(address owner_) public {
        require(msg.sender == owner, 'Owner not allowed');
        owner = owner_;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'Recipient not allowed');
        recipient = recipient_;
    }

    function deployVester(  uint vestingAmount_,
                            uint vestingBegin_,
                            uint vestingCliff_,
                            uint vestingEnd_) public {

        require(msg.sender == owner, 'Deploy not allowed');
        require(vestingAmount_ > 0, 'Wrong p0');
        require(uint32(vestingBegin_) > block.timestamp, 'Wrong p1');
        require(uint32(vestingCliff_) > uint32(vestingBegin_), 'Wrong p2');
        require(uint32(vestingEnd_) > uint32(vestingCliff_), 'Wrong p3');

        // Prepare vesterInfo infomation
        VesterInfo memory vesterInfo;

        vesterInfo.vestingAmount    = uint128(vestingAmount_);
        vesterInfo.vestingBegin     = uint32(vestingBegin_);
        vesterInfo.vestingCliff     = uint32(vestingCliff_);
        vesterInfo.vestingEnd       = uint32(vestingEnd_);
        vesterInfo.lastClaimTime    = uint32(vestingBegin_);

        allVesters[numTotalVester] = vesterInfo;
        numTotalVester += 1;
    }

    function claim() public {
        VesterInfo storage vesterInfo = allVesters[noVesterClaimable];

        require(vesterInfo.vestingAmount > 0, 'Not claimable');
        require(block.timestamp >= vesterInfo.vestingCliff, 'Not time yet');
        uint amount;
        if (block.timestamp >= vesterInfo.vestingEnd) {
            noVesterClaimable += 1;                                 // Next vester could be non-available
            if(noVesterClaimable == numTotalVester) {               // for last vester, claim all
                amount = IFeswap(Fesw).balanceOf(address(this));
            } else {
                amount = vesterInfo.vestingAmount.mul(vesterInfo.vestingEnd - vesterInfo.lastClaimTime) / (vesterInfo.vestingEnd - vesterInfo.vestingBegin);
            }
        } else {
            amount = vesterInfo.vestingAmount.mul(uint32(block.timestamp) - vesterInfo.lastClaimTime) / (vesterInfo.vestingEnd - vesterInfo.vestingBegin);
            vesterInfo.lastClaimTime = uint32(block.timestamp);
        }
        IFeswap(Fesw).transfer(recipient, amount);
    }
}