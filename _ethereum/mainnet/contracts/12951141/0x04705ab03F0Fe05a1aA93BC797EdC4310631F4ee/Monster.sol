// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Spaghetti.sol";
import "./Fork.sol";

// Forked from the original Sushiswap's MasterChef contract 
// (https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol) 
// with a few changes:
// - Add NFT+token deposits
// - The rewardPerBlock distribution halves for every 4 years like BTC 

contract Monster is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 tokenIdOfFork;    // FORK (NFT) token id
        uint256 amount;           // How many FSM tokens the user has provided.
        uint256 rewardTokenDebt;  // Reward FSMTokens debt. 
        uint256 rewardNFTDebt;    // Reward FORKTokens debt. 
    }

    /// @notice The FSM token
    Spaghetti public fsmToken;

    Fork public fork;

    // FSM tokens created per block.
    uint256 public rewardPerBlock;

    uint256 public accTokenPerShare;

    uint256 public accTokenPerNFT;

    uint256 public lastRewardBlock;

    uint256 public nextHalvingBlock;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    // The block number when FSM mining starts.
    uint256 public startBlock;

    // record FSM token deposited by user
    uint256 public totalDeposited;

    uint256 constant NUMBER_OF_BLOCK_PER_ROUND = 4 * 60 * 24 * 365 * 4; 
    uint256 constant REWARD_TOKEN_PERCENTAGE = 40;
    uint256 constant REWARD_NFT_PERCENTAGE = 60;
    // Flag of setting start block ('false' means not set).
    bool public startFlag = false;

    event Deposited(address indexed user, uint256 tokenId, uint256 amount);
    event Withdrawn(address indexed user, uint256 tokenId, uint256 amount);
    event TokenDeposited(address indexed user, uint256 amount);
    event TokenWithdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amount);
    event ForkReceived(address operator, address from, uint256 tokenId);

    constructor(
        Spaghetti _fsmToken,
        Fork _fork
    ) public {
        fsmToken = _fsmToken;
        fork = _fork;
        rewardPerBlock = fsmToken.cap().div(2).div(NUMBER_OF_BLOCK_PER_ROUND);
    }
    
    /// @notice Set startBlock at beginning and it can only be set once.
    function setStartBlock(uint256 _startBlock) external onlyOwner
    {
        require(startFlag == false, "already start");
        
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
        nextHalvingBlock = _startBlock + NUMBER_OF_BLOCK_PER_ROUND;

        startFlag = true;
        return;
    }

    /// @notice Return the amount of reward from lastRewardBlock to `_to`
    function getMinedAmount(uint256 _to) 
        public 
        view 
        returns (uint256, uint256, uint256)
    {
        uint256 r = rewardPerBlock;

        if (_to < nextHalvingBlock) {
            uint256 mined = _to.sub(lastRewardBlock).mul(r);
            uint256 rounds = 0;
            return (mined, rounds, r);
        }

        uint256 mined = nextHalvingBlock.sub(lastRewardBlock).mul(r);
        uint256 b = _to.sub(nextHalvingBlock);
        uint256 rounds = 0;

        // Assume that the iterations are less than 27
        for (uint i = 0; i < b.div(NUMBER_OF_BLOCK_PER_ROUND); i++) {
            rounds = rounds + 1;
            r = r.div(2);
            mined = mined.add(r.mul(NUMBER_OF_BLOCK_PER_ROUND));
        }
        r = r.div(2);
        if (r == 0) {
            return (0, rounds+1, r);
        }
        uint256 n = nextHalvingBlock.add(rounds * NUMBER_OF_BLOCK_PER_ROUND);
        mined = mined.add(r.mul(_to.sub(n)));
        rounds += 1;
        return (mined, rounds, r);
    }

    /// @notice View function to see pending rewards on frontend.
    function pendingReward(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 _accTokenPerShare = accTokenPerShare;
        uint256 _accTokenPerNFT = accTokenPerNFT;
        uint256 total = totalDeposited;
        uint256 totalNFT = fork.balanceOf(address(this));

        if (user.tokenIdOfFork == uint256(0)) {
            return 0;
        }

        if (block.number > lastRewardBlock && total != 0) {
            (uint256 mined, , ) =
                getMinedAmount(block.number);

            _accTokenPerShare = _accTokenPerShare.add(
                mined.mul(REWARD_TOKEN_PERCENTAGE).mul(1e12).div(100).div(total)
            );

            _accTokenPerNFT = _accTokenPerNFT.add(
                mined.mul(REWARD_NFT_PERCENTAGE).mul(1e12).div(100).div(totalNFT)
            );
        }
        uint256 reward = user.amount.mul(_accTokenPerShare).div(1e12).sub(user.rewardTokenDebt);
        reward = reward.add(_accTokenPerNFT.div(1e12).sub(user.rewardNFTDebt));
        return reward;
    }

    /// @notice Update reward variables of the given dish(pool) to be up-to-date.
    function update() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 total = totalDeposited;
        uint256 totalNFT = fork.balanceOf(address(this));

        if (totalNFT == 0) {
            lastRewardBlock = block.number;
            if(lastRewardBlock > nextHalvingBlock){
                uint256 r = rewardPerBlock;
                uint256 rounds = 1;

                uint256 b = lastRewardBlock.sub(nextHalvingBlock);
                for (uint i = 0; i < b.div(NUMBER_OF_BLOCK_PER_ROUND); i++) {
                    rounds = rounds + 1;
                    r = r.div(2);
                }
                r = r.div(2);
                if (r == 0) {
                    rewardPerBlock = 0;
                    return;
                }

                rewardPerBlock = r;
                nextHalvingBlock = nextHalvingBlock.add(
                rounds * NUMBER_OF_BLOCK_PER_ROUND);
            }
            return;
        }

        (uint256 mined, uint256 rounds, uint256 rpb) = getMinedAmount(block.number);

        fsmToken.mint(address(this), mined);

        if (total != 0) {
            accTokenPerShare = accTokenPerShare.add(
                mined.mul(REWARD_TOKEN_PERCENTAGE).mul(1e12).div(100).div(total)
            );
        }

        accTokenPerNFT = accTokenPerNFT.add(
            mined.mul(REWARD_NFT_PERCENTAGE).mul(1e12).div(100).div(totalNFT)
        );
        
        lastRewardBlock = block.number;

        rewardPerBlock = rpb;

        nextHalvingBlock = nextHalvingBlock.add(
            rounds * NUMBER_OF_BLOCK_PER_ROUND
        );

    }

    /// @notice Deposit FSMTokens to MasterChef for more FSMTokens.
    /// @param tokenId Fork (NFT) Token's index
    /// @param _amount FSM token's amount
    function deposit(uint256 tokenId, uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(startFlag == true, "not start yet");
        require(block.number >= startBlock, "not start yet");
        require(user.tokenIdOfFork == uint256(0), "deposit: ~fork");
        require(user.amount == uint256(0), "deposit: IERR");

        update();

        fork.safeTransferFrom(
            address(msg.sender), 
            address(this),
            tokenId
        );

        fsmToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        
        totalDeposited = totalDeposited.add(_amount);
        user.tokenIdOfFork = tokenId;
        user.amount = _amount;
        user.rewardTokenDebt = user.amount.mul(accTokenPerShare).div(1e12);
        user.rewardNFTDebt = accTokenPerNFT.div(1e12);
        emit Deposited(msg.sender, tokenId, _amount);
    }

    /// @notice Deposit FSMTokens to MasterChef for more FSMTokens.
    /// @notice Append the FSM token after calling deposit() function.
    /// @param _amount The amount of FSMTokens. If argument of _amount is equal to zero, reward is withdrew by default.
    function depositToken(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.tokenIdOfFork != uint256(0), "deposit: ~fork");

        update();
        if (user.amount > 0) {
            uint256 pendingToken =
                user.amount.mul(accTokenPerShare).div(1e12).sub(
                    user.rewardTokenDebt
                );
            uint256 pendingNFT = 
                accTokenPerNFT.div(1e12).sub(
                    user.rewardNFTDebt 
            );
            uint256 pending = pendingToken.add(pendingNFT);

            fsmToken.transfer(msg.sender, pending);
        }

        if(_amount > 0){
        fsmToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        totalDeposited = totalDeposited.add(_amount);
        user.amount = user.amount.add(_amount);   
        }

        user.rewardTokenDebt = user.amount.mul(accTokenPerShare).div(1e12);
        user.rewardNFTDebt = accTokenPerNFT.div(1e12);
        emit TokenDeposited(msg.sender, _amount);
    }

    /// @notice Withdraw Fork NFT along with FSMTokens. 
    function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.tokenIdOfFork != uint256(0), "withdraw: ~fork");

        update();
        uint256 pendingToken = 
            user.amount.mul(accTokenPerShare).div(1e12).sub(
                user.rewardTokenDebt
            );

        uint256 pendingNFT = 
            accTokenPerNFT.div(1e12).sub(
                    user.rewardNFTDebt 
            );
        uint256 amount = pendingToken.add(pendingNFT).add(user.amount);
        if (amount > 0) {
            fsmToken.transfer(address(msg.sender), amount);
        }
        fork.safeTransferFrom(
            address(this),
            msg.sender, 
            user.tokenIdOfFork
        );

        totalDeposited = totalDeposited.sub(user.amount);
        user.tokenIdOfFork = 0;
        user.amount = 0;
        user.rewardTokenDebt = 0;
        user.rewardNFTDebt = 0;

        emit Withdrawn(msg.sender, user.tokenIdOfFork, user.amount);
    }

    /// @dev Withdraw LP tokens from MasterChef.
    /// @param _amount The amount of FSMTokens
    function withdrawToken(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: !amount");
        require(user.tokenIdOfFork != uint256(0), "withdraw: ~fork");

        update();
        uint256 pendingToken =
            user.amount.mul(accTokenPerShare).div(1e12).sub(
                user.rewardTokenDebt
            );

        uint256 pendingNFT = 
            accTokenPerNFT.div(1e12).sub(
                    user.rewardNFTDebt 
            );
        
        uint256 pending = pendingToken.add(pendingNFT);
        fsmToken.transfer(msg.sender, pending);

        if(_amount > 0){
            user.amount = user.amount.sub(_amount);
            totalDeposited = totalDeposited.sub(_amount);
            fsmToken.transfer(address(msg.sender), _amount);
        }

        user.rewardTokenDebt = user.amount.mul(accTokenPerShare).div(1e12);
        user.rewardNFTDebt = accTokenPerNFT.div(1e12);

        emit TokenWithdrawn(msg.sender, _amount);
    }

    /// @dev Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        fsmToken.transfer(address(msg.sender), user.amount);
        
        if (user.tokenIdOfFork != uint256(0)) {
            fork.safeTransferFrom(
                address(this),
                msg.sender, 
                user.tokenIdOfFork
            );
            user.tokenIdOfFork = 0;
        }
        totalDeposited = totalDeposited.sub(user.amount);
        user.amount = 0;
        user.rewardTokenDebt = 0;
        user.rewardNFTDebt = 0;
        emit EmergencyWithdrawn(msg.sender, user.amount);
    }

    function onERC721Received(
            address operator, 
            address from, 
            uint256 tokenId, 
            bytes calldata data
        ) 
        external 
        override
        returns (bytes4)
    {
        emit ForkReceived(operator, from, tokenId);
        return this.onERC721Received.selector;
    }
    
}