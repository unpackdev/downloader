// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;

import "./IERC721.sol";
import "./Distribute.sol";

contract StakingERC721  {
    using SafeERC20 for IERC20;

    /// @dev handle to access ERC721 token contract to make transfers
    IERC721 immutable public tokenA;
    IERC721 immutable public tokenB;
    IERC20 immutable public token;
    Distribute immutable public stakingContractEth;

    mapping(address => uint256[]) public tokenOwnershipA;
    mapping(address => uint256[]) public tokenOwnershipB;

    event ProfitEth(uint256 amount);
    event ReceivedToken(uint256 amount);
    event Staked(address indexed account, uint256 amount, uint256 total);
    event Unstaked(address indexed account, uint256 amount, uint256 total);
    event StakeChanged(uint256 total, uint256 timestamp);
    event Claimed(address indexed account, uint256 eth);

    constructor(IERC721 _tokenA, IERC721 _tokenB, IERC20 _token) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        token = _token;
        stakingContractEth = new Distribute(0, IERC20(address(0)));
    }

    function distribute_eth() payable public {
        stakingContractEth.distribute{value : msg.value}(0, msg.sender);
        emit ProfitEth(msg.value);
    }

    function distribute(uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit ReceivedToken(amount);
    }
    
    /**
        @dev Stakes a certain amount of tokens, this MUST transfer the given amount from the account
        @param ids token ids to stake
        @param isTokenA true if staking tokenA
    */
    function stake(uint256[] memory ids, bool isTokenA) external {
        stakeFor(msg.sender, ids, isTokenA);
    }

    /**
        @dev Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
        @param account Address who will own the stake afterwards
        @param ids token ids to stake
        @param isTokenA true if staking tokenA
    */
    function stakeFor(address account, uint256[] memory ids, bool isTokenA) public {
        //transfer tokens from the sender to the contract, allowance must be set in terms of isApprovedForAll
        for(uint i = 0; i < ids.length; i++) {
            
            if(isTokenA) {
                tokenOwnershipA[account].push(ids[i]);
                tokenA.transferFrom(msg.sender, address(this), ids[i]);
            }
            else {
                tokenOwnershipB[account].push(ids[i]);
                tokenB.transferFrom(msg.sender, address(this), ids[i]);
            }
        }
        
        stakingContractEth.stakeFor(account, ids.length);
        
        emit Staked(account, ids.length, totalStakedFor(account));
        emit StakeChanged(stakingContractEth.totalStaked(), block.timestamp);
    }

    /**
        @dev Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the account, if unstaking is currently not possible the function MUST revert
        @param amount Amount of tokens to remove from the stake
        @param isTokenA true if unstaking tokenA
    */
    function unstake(uint256 amount, bool isTokenA) external {
        stakingContractEth.unstakeFrom(msg.sender, amount);

        uint256[] storage tokens;
        IERC721 token;
        if(isTokenA) {
            tokens = tokenOwnershipA[msg.sender];
            token = tokenA;
        }
        else {
            tokens = tokenOwnershipB[msg.sender];
            token = tokenB;
        }

        require(amount <= tokens.length, "StakingERC721: Not enough tokens of this type");

        for(uint i = 0; i < amount; i++) {
            uint256 id = tokens[tokens.length - 1];
            tokens.pop();
            token.transferFrom(address(this), msg.sender, id);
        }

        emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender));
        emit StakeChanged(stakingContractEth.totalStaked(), block.timestamp);
    }

     /**
        @dev Withdraws rewards (basically unstake then restake)
        @param amount Amount of token to remove from the stake
    */
    function withdraw(uint256 amount) external {
        if(amount == 0) //If amount if 0, then we claim all the rewards
            amount = totalStakedFor(msg.sender);
        stakingContractEth.withdrawFrom(msg.sender, amount);
        emit Claimed(msg.sender, getReward(msg.sender) * amount / totalStakedFor(msg.sender));
    }

    /**
        @dev Returns the current total of tokens staked for an address
        @param account address owning the stake
        @return the total of staked tokens of this address
    */
    function totalStakedFor(address account) public view returns (uint256) {
        return stakingContractEth.totalStakedFor(account);
    }

    /**
        @param account address owning the stake
        @return tokenA Amount of tokenA staked by the account. tokenB Amount of tokenB staked by the account
    */
    function totalTokenStakedFor(address account) public view returns (uint256 tokenA, uint256 tokenB) {
        tokenA = tokenOwnershipA[account].length;
        tokenB = tokenOwnershipB[account].length;
    }

    /**
        @dev returns the total rewards stored for token and eth
    */
    function totalReward() external view returns (uint256) {
        return stakingContractEth.getTotalReward();
    }
    
    /**
        @dev Returns the current total of tokens staked
        @return the total of staked tokens
    */
    function totalStaked() external view returns (uint256) {
        return stakingContractEth.totalStaked();
    }

    /**
        @dev Returns how much ETH the user can withdraw currently
        @param account Address of the user to check reward for
        @return eth the amount of ETH the account will perceive if he unstakes now
    */
    function getReward(address account) public view returns (uint256 eth) {
        eth = stakingContractEth.getReward(account);
    }
}
