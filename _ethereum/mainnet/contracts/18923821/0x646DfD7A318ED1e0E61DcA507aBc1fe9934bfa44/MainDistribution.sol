// SPDX-License-Identifier: unlicensed

pragma solidity 0.8.19;

import "./EnumerableSet.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable2Step.sol";
import "./IDex.sol";

error InvalidSignature();
error InvalidMerkleProof();
error ClaimingPaused();
error UnsufficientEthAllocation();
error AlreadyClaimed();
error InvalidMerkleRoot();
error UnsufficientEthBalance();
error UnsufficientReachBalance();
error InvalidTokenAddress();
error InvalidPrice();

/**
 * @title ReachDistribution
 * @dev This contract manages the distribution of Reach tokens and Ether based on Merkle proofs.
 */
contract ReachMainDistribution is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Events
    event Received(address indexed sender, uint256 amount);
    event RewardsClaimed(
        address indexed account,
        uint256 ethAmount,
        uint256 reachAmount,
        uint256 indexed version,
        uint256 timestamp
    );
    event TopUp(address indexed user, uint256 balance, uint256 timestamp);
    event DistributionSet(
        bytes32 indexed merkleRoot,
        uint256 ethAmount,
        uint256 reachAmount
    );
    event MissionCreated(string missionId, uint256 amount);

    // State variables
    struct Claims {
        uint256 eth;
        uint256 reach;
    }

    struct Config {
        uint256 swapPercentage;
        uint256 leaderboardPercentage;
        uint256 rsPercentage;
        uint256 affiliateLeaderboardPercentage;
        uint256 affiliateRsPercentage;
    }

    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => Claims) public claims;
    uint256 public currentVersion;
    mapping(address => uint256) public lastClaimedVersion;
    address public reachToken;
    bool public paused;
    bytes32 public merkleRoot;
    uint256 public creditPrice = 25 ether;
    uint256 public feesCollected;
    uint256 public leaderboardPool;
    uint256 public rsPool;
    Config public config;

    /**
     * @dev Constructor for ReachDistribution contract.
     * @param _reachToken Address of the reach token.
     */
    constructor(address _reachToken) {
        reachToken = _reachToken;
        config = Config({
            swapPercentage: 800,
            leaderboardPercentage: 875,
            rsPercentage: 125,
            affiliateLeaderboardPercentage: 600,
            affiliateRsPercentage: 400
        });
    }

    // External functions
    /*
     * @notice Creates a new mission
     * @param _missionId The ID of the new mission
     * @param _amount The amount allocated to the new mission
     */
    function createMission(
        string memory _missionId,
        uint256 _amount
    ) external payable {
        require(_amount > 0, "Amount must be greater than 0.");
        require(_amount == msg.value, "Incorrect amount sent.");

        uint256 amountToSwap = (_amount * config.swapPercentage) / 1000;
        swapEth(amountToSwap, address(this));
        emit MissionCreated(_missionId, _amount);
    }

    /**
     * @dev Allows users to top up their credit balance.
     * @param _amount The amount of credits to add.
     */
    function topUp(uint256 _amount) external {
        uint256 price = _amount * creditPrice;
        IERC20(reachToken).safeTransferFrom(msg.sender, address(this), price);

        feesCollected += price;

        emit TopUp(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev sets the percentages for the contract
     * @param _swapPercentage The percentage of the swap
     * @param _leaderboardPercentage The percentage of the leaderboard
     * @param _rsPercentage The percentage of the rs
     * @param _affiliateLeaderboardPercentage The percentage of the affiliate leaderboard
     * @param _affiliateRsPercentage The percentage of the affiliate rs
     */
    function setPercentages(
        uint256 _swapPercentage,
        uint256 _leaderboardPercentage,
        uint256 _rsPercentage,
        uint256 _affiliateLeaderboardPercentage,
        uint256 _affiliateRsPercentage
    ) external onlyOwner {
        config = Config({
            swapPercentage: _swapPercentage,
            leaderboardPercentage: _leaderboardPercentage,
            rsPercentage: _rsPercentage,
            affiliateLeaderboardPercentage: _affiliateLeaderboardPercentage,
            affiliateRsPercentage: _affiliateRsPercentage
        });
    }

    /**
     * @dev Toggles the pausing state of the contract.
     */
    function toggleClaiming() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Withdraws all Reach tokens to the owner's address.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = IERC20(reachToken).balanceOf(address(this));
        require(balance > feesCollected, "No fees to withdraw.");
        IERC20(reachToken).safeTransfer(owner(), feesCollected);
    }

    /**
     * @dev Allows users to claim their rewards.
     * @param _merkleProof The merkle proof for the claim.
     * @param _ethAmount The ETH amount to claim.
     * @param _reachAmount The Reach token amount to claim.
     */
    function claimRewards(
        bytes32[] calldata _merkleProof,
        uint256 _ethAmount,
        uint256 _reachAmount
    ) external nonReentrant {
        if (paused) revert ClaimingPaused();
        if (lastClaimedVersion[msg.sender] == currentVersion)
            revert AlreadyClaimed();
        if (!verifyProof(_merkleProof, _ethAmount, _reachAmount))
            revert InvalidMerkleProof();

        lastClaimedVersion[msg.sender] = currentVersion;
        claims[msg.sender] = Claims({eth: _ethAmount, reach: _reachAmount});

        if (_ethAmount > 0) payable(msg.sender).transfer(_ethAmount);
        if (_reachAmount > 0)
            IERC20(reachToken).safeTransfer(msg.sender, _reachAmount);

        emit RewardsClaimed(
            msg.sender,
            _ethAmount,
            _reachAmount,
            currentVersion,
            block.timestamp
        );
    }

    // Public functions
    /**
     * @dev Sets the price for purchasing credits.
     * @param _price The new price for credits.
     */
    function setCreditPrice(uint256 _price) public onlyOwner {
        if (_price == 0) {
            revert InvalidPrice();
        }
        creditPrice = _price;
    }

    /**
     * @dev Creates a new distribution of rewards.
     * @param _merkleRoot The merkle root of the distribution.
     * @param _ethAmount The total ETH amount for the distribution.
     * @param _reachAmount The total Reach token amount for the distribution.
     */
    function createDistribution(
        bytes32 _merkleRoot,
        uint256 _ethAmount,
        uint256 _reachAmount
    ) public onlyOwner {
        if (_merkleRoot == bytes32(0)) revert InvalidMerkleRoot();
        if (address(this).balance < _ethAmount) revert UnsufficientEthBalance();
        if (IERC20(reachToken).balanceOf(address(this)) < _reachAmount)
            revert UnsufficientReachBalance();

        currentVersion++;
        merkleRoot = _merkleRoot;
        emit DistributionSet(_merkleRoot, _ethAmount, _reachAmount);
    }

    /**
     * @dev Sets the Reach token address.
     * @param _token The new Reach token address.
     */
    function setReachAddress(address _token) public onlyOwner {
        if (_token == address(0) || IERC20(_token).totalSupply() == 0) {
            revert InvalidTokenAddress();
        }
        reachToken = _token;
    }

    // Fallback function
    /**
     * @dev Fallback function to receive Ether.
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Internal functions
    /**
     * @dev Verifies the Merkle proof for a claim.
     * @param _merkleProof The Merkle proof.
     * @param _ethAmount The ETH amount in the claim.
     * @param _reachAmount The Reach token amount in the claim.
     * @return bool True if the proof is valid, false otherwise.
     */
    function verifyProof(
        bytes32[] calldata _merkleProof,
        uint256 _ethAmount,
        uint256 _reachAmount
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, _ethAmount, _reachAmount)
        );
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    // Override functions
    /**
     * @dev Prevents renouncing ownership.
     */
    function renounceOwnership() public virtual override onlyOwner {
        revert("Can't renounce ownership");
    }

    function swapEth(uint _ethAmount, address _origin) public payable {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = reachToken;

        uint256 balanceBefore = IERC20(reachToken).balanceOf(address(this));
        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, address(this), block.timestamp + 5);

        uint256 balanceAfter = IERC20(reachToken).balanceOf(address(this));
        uint256 outputAmount = balanceAfter - balanceBefore;
        // output the amount of tokens received
        //if swap is called within this contract
        if (_origin == address(this)) {
            leaderboardPool +=
                (outputAmount * config.leaderboardPercentage) /
                1000;
            rsPool += (outputAmount * config.rsPercentage) / 1000;
        } else {
            leaderboardPool +=
                (outputAmount * config.affiliateLeaderboardPercentage) /
                1000;
            rsPool += (outputAmount * config.affiliateRsPercentage) / 1000;
        }
    }
}
