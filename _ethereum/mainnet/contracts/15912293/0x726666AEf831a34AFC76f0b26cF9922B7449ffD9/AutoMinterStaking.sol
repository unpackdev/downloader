// SPDX-License-Identifier: UNLICENSED

import "./ECDSA.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

pragma solidity >=0.7.0 <0.9.0;

contract AutoMinterStaking is Initializable, OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private erc20Token;
    uint256 private totalShares;
    uint256 private defaultSharePerToken;
    mapping(address => uint256) private stakeholderToShares;

    event StakeAdded(
        address indexed stakeholder,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event StakeRemoved(
        address indexed stakeholder,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    constructor() {}

    function initialize(address erc20Token_) public initializer {
        erc20Token = erc20Token_;
        __Ownable_init_unchained();
        defaultSharePerToken = 1;
    }

    /**
     * @notice stake tokens in the contract
     * @dev stake tokens in the contract
     * @param stakeAmount the amount of tokens you want to send to the staking contract
     */
    function createStake(uint256 stakeAmount) public
    {
        uint256 totalStakeAmount = IERC20Upgradeable(erc20Token).balanceOf(address(this));
        
        uint256 shares;

        if(totalStakeAmount > 0 && totalShares > 0){
            // shares allocated equal to the portion of the total stake balance
            shares = (stakeAmount * totalShares) / totalStakeAmount;
        }
        else{
            // handle the case when supply of tokens is 0
            shares = defaultSharePerToken * stakeAmount;
        }
        
        require(
            IERC20Upgradeable(erc20Token).transferFrom(msg.sender, address(this), stakeAmount),
            "ERC20 transfer failed"
        );

        stakeholderToShares[msg.sender] += shares;
        totalShares += shares;
        
        emit StakeAdded(msg.sender, stakeAmount, shares, block.timestamp);
    }

    /**
     * @notice remove tokens from the contract
     * @dev remove tokens from the contract
     * @param stakeAmount the amount of tokens you want to withdraw from the staking contract
     */
    function removeStake(uint256 stakeAmount) public {
        uint256 stakeholderShares = stakeholderToShares[msg.sender];

        uint256 totalStakeAmount = IERC20Upgradeable(erc20Token).balanceOf(address(this));

        uint256 sharesToWithdraw = (stakeAmount * totalShares) / totalStakeAmount;

        require(stakeholderShares >= sharesToWithdraw, "Not enough shares!");
        
        stakeholderToShares[msg.sender] -= sharesToWithdraw;
        totalShares -= sharesToWithdraw;
        
        require(
            IERC20Upgradeable(erc20Token).transfer(msg.sender, stakeAmount),
            "ERC20 transfer failed"
        );
        
        emit StakeRemoved(
            msg.sender,
            stakeAmount,
            sharesToWithdraw,
            block.timestamp
        );
    }

    function getStakePerShare() public view returns (uint256) {
        return (IERC20Upgradeable(erc20Token).balanceOf(address(this))) / totalShares;
    }

    function stakeOf(address stakeholder) public view returns (uint256) {
        uint256 totalStakeAmount = IERC20Upgradeable(erc20Token).balanceOf(address(this));
        uint256 shares = stakeholderToShares[stakeholder];

        if(totalShares == 0){
            return 0;
        }

        return (shares * totalStakeAmount) / totalShares;
    }
    
    function sharesOf(address stakeholder) public view returns (uint256) {
        return stakeholderToShares[stakeholder];
    }
    
    function getTotalStakes() public view returns (uint256) {
        return IERC20Upgradeable(erc20Token).balanceOf(address(this));
    }
    
    function getTotalShares() public view returns (uint256) {
        return totalShares;
    }
}