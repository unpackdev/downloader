// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./console.sol";
import "./ITerminal.sol";
import "./IARVO.sol";

// Debugging solution
// console.log("all it's fine = ", fuckyou);

// TODO: add fork period and percentage functions

contract Terminal is ITerminal, Ownable {
    using SafeMath for uint256;

    IARVO private ARVO;

    uint256 public rewardsPerBlock;
    uint256 public maximumSupply;
    address public stakingContract;
    address public farmingContract;
    address public developersAddr;

    modifier onlyFarmingOrStaking() {
        require((farmingContract == _msgSender() || stakingContract == _msgSender()), 'TERMINAL: the caller is not farming or staking contract');
        _;
    }

    constructor(
        address _arvoToken,
        uint256 _maximumSupply,
        uint256 _rewardsPerBlock,
        address _developersAddr
    ) public Ownable() {
        maximumSupply = _maximumSupply;
        rewardsPerBlock = _rewardsPerBlock;
        developersAddr = _developersAddr;
        ARVO = IARVO(_arvoToken);
    }

    function changeRewardsPerBlock(uint256 _rewards) public onlyOwner {
        require(_rewards > 0, 'TERMINAL: the rewards is less from 0');
        rewardsPerBlock = _rewards;
    }

    function changeDevelopersAddr(address _developersAddr) public onlyOwner {
        require(_developersAddr != address(0), 'TERMINAL: the developers address it is the zero address');
        developersAddr = _developersAddr;
    }

    function changeMaximumSupply(uint256 _maximumSupply) public onlyOwner {
        require(_maximumSupply > 0, 'TERMINAL: the maximum supply is 0');
        maximumSupply = _maximumSupply;
    }

    function changeStakingContract(address _stakingContract) public onlyOwner {
        require(_stakingContract != address(0), 'ERC20: the caller from the zero address');
        stakingContract = _stakingContract;
    }

    function changeFarmingContract(address _farmingContract) public onlyOwner {
        require(_farmingContract != address(0), 'ERC20: the caller from the zero address');
        farmingContract = _farmingContract;
    }

    function calculateRewards(uint256 _fromBlock, uint256 _toBlock) external override pure returns (uint256) {
        // return rewardsPerBlock;
    }

    function getRewardsPerBlock() external override view returns (uint256) {
        return rewardsPerBlock;
    }

    function mint(address _beneficiary, uint256 _amount) external override onlyFarmingOrStaking {
        uint256 finalTotalSupply = _amount.add(ARVO.totalSupply());
        require(finalTotalSupply <= maximumSupply, 'TERMINAL: you exceeded the limit');
        ARVO.mint(_beneficiary, _amount);
    }

    function burn(address _beneficiary, uint256 _amount) external override onlyFarmingOrStaking {
        ARVO.burn(_beneficiary, _amount);
    }
}
