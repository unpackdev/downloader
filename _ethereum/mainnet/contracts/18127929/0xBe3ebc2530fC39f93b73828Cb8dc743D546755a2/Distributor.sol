// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./IRevenueDistributionToken.sol";


contract Redistributor {

    uint public totalAccumulated;
    
    uint public distributionThreshold;

    uint public liquidityShare;
    uint public crocShare;
    uint public vestingPeriod;
    uint public distributionTime;

    address public croc;
    address public crocLp;
    address public crocVault;
    address public lpVault;
    address public creator;


    IUniswapV2Router02 public uniswapRouter;

    event Distribution(uint ethForCroc, uint ethForLiq);
    
    constructor(
        uint _liquidityShare, 
        uint _crocShare,
        address _crocVault,
        address _croc, 
        address _crocLp,
        address _lpVault,
        address _uniswapRouter,
        uint _vestingPeriod,
        uint _threshold
    ) {
        creator = msg.sender;
        liquidityShare = _liquidityShare;
        crocShare = _crocShare;
        crocVault = _crocVault;
        lpVault = _lpVault;
        croc = _croc;
        crocLp = _crocLp;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        vestingPeriod = _vestingPeriod;
        distributionTime = block.timestamp; 
        distributionThreshold = _threshold;
    }

    receive() external payable {
        totalAccumulated += msg.value;
        if (totalAccumulated >= distributionThreshold && block.timestamp >= distributionTime + 1 days) {
            _triggerDistribution();
        }
    }

    function editDistributionThreshold(uint _newThreshold) external {
        require(msg.sender == creator, "Only creator can edit threshold");
        distributionThreshold = _newThreshold;
    }

    function acceptVaultOwnership(address _vault) external {
        require(msg.sender == creator, "Only creator can accept vault ownership");
        IRevenueDistributionToken(_vault).acceptOwnership();
    }

    function setVaultPendingOwner(address _vault) external {
        require(msg.sender == creator, "Only creator can set vault ownership");
        IRevenueDistributionToken(_vault).setPendingOwner(creator);
    }

    function editShares(uint _crocShare, uint _liquidityShare) external {
        require(msg.sender == creator, "Only creator can edit shares");
        crocShare = _crocShare;
        liquidityShare = _liquidityShare;
    }

    function editVesting(uint _vestingPeriod) external {
        require(msg.sender == creator, "Only creator can edit vesting");
        vestingPeriod = _vestingPeriod;
    }

    function updateDistributionTime(uint _newTime) external {
        require(msg.sender == creator, "Only creator can change distribution time");
        distributionTime = _newTime;
    }

    function emergencyWithdraw() external  {
        require(msg.sender == creator, "Only creator can edit emergency withdraw");
        payable(creator).transfer(address(this).balance);
    }

    function _triggerDistribution() internal {
        uint crocAmount = (totalAccumulated * crocShare) / 100;
        uint liquidityAmount = totalAccumulated - crocAmount;

        // Buy CROC
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = croc;
        uniswapRouter.swapExactETHForTokens{value: crocAmount}(
            0, 
            path,
            address(this),
            block.timestamp
        );
    
        // Deposit to CrocVault
        IERC20(croc).transfer(crocVault, IERC20(path[1]).balanceOf(address(this)));
        IRevenueDistributionToken(crocVault).updateVestingSchedule(vestingPeriod);

        // Buy more CROC
        path[0] = uniswapRouter.WETH(); 
        path[1] = croc;
        uniswapRouter.swapExactETHForTokens{value: liquidityAmount / 2}(
            0, 
            path,
            address(this),
            block.timestamp
        );

        // Approve
        IERC20(croc).approve(address(uniswapRouter), IERC20(croc).balanceOf(address(this)));

        // Add liquidity
        uniswapRouter.addLiquidityETH{value: liquidityAmount / 2}(
            croc,
            IERC20(croc).balanceOf(address(this)),
            0,
            0,
            lpVault,
            block.timestamp
        );
        
        IRevenueDistributionToken(lpVault).updateVestingSchedule(vestingPeriod);

        emit Distribution(crocAmount, liquidityAmount);

        totalAccumulated = 0;
        distributionTime = distributionTime + 1 days;
    }
}
