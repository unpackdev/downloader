// SPDX-License-Identifier: unlicensed

pragma solidity 0.8.19;

import "./EnumerableSet.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable2Step.sol";
import "./IDex.sol";
import "./console.sol";

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
contract ReachAffiliateDistribution is Ownable2Step, ReentrancyGuard {
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
        uint256 globalPool;
        uint256 leaderboardPercentage;
        uint256 amountToSwap;
    }

    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => Claims) public claims;
    uint256 public currentVersion;
    mapping(address => uint256) public lastClaimedVersion;
    address public reachToken;
    bool public paused;
    bytes32 public merkleRoot;
    uint256 public leaderboardPool;
    uint256 public globalPool;
    Config public config;
    uint256 public transferThreshold = 50_000 ether;
    address public mainDistribution;

    /**
     * @dev Constructor for ReachDistribution contract.
     * @param _reachToken Address of the reach token.
     * @param _owner Address of the owner.
     * @param _mainDistribution Address of the main distribution.
     */
    constructor(
        address _reachToken,
        address _owner,
        address _mainDistribution
    ) {
        reachToken = _reachToken;
        config = Config({
            globalPool: 3125,
            leaderboardPercentage: 6875,
            amountToSwap: 80
        });
        mainDistribution = _mainDistribution;
        _transferOwnership(_owner);
    }

    // External functions
    /**
     * @dev Sets the main distribution address.
     * @param _mainDistribution The address of the new main distribution.
     */
    function setMainDistribution(address _mainDistribution) public onlyOwner {
        mainDistribution = _mainDistribution;
    }

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
        uint256 amountToSwap = (_amount * config.amountToSwap) / 100;

        swapEth(amountToSwap);
        emit MissionCreated(_missionId, _amount);
    }

    /**
     * @dev Sets the transfer threshold.
     * @param _threshold The new transfer threshold.
     */
    function setTransferThreshold(uint256 _threshold) external onlyOwner {
        transferThreshold = _threshold;
    }

    /**
     * @dev sets the percentages for the contract
     * @param _globalPool The percentage of the swap
     * @param _leaderboardPercentage The percentage of the leaderboard
     * @param _amountToSwap The percentage of the swap
     */
    function setPercentages(
        uint256 _globalPool,
        uint256 _leaderboardPercentage,
        uint256 _amountToSwap
    ) external onlyOwner {
        config = Config({
            globalPool: _globalPool,
            leaderboardPercentage: _leaderboardPercentage,
            amountToSwap: _amountToSwap
        });
    }

    /**
     * @dev Toggles the pausing state of the contract.
     */
    function toggleClaiming() external onlyOwner {
        paused = !paused;
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

    function swapEth(uint _ethAmount) public payable {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = reachToken;

        uint256 balanceBefore = IERC20(reachToken).balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, address(this), block.timestamp + 5);
        uint256 balanceAfter = IERC20(reachToken).balanceOf(address(this));
        uint256 outputAmount = balanceAfter - balanceBefore;
        leaderboardPool +=
            (outputAmount * config.leaderboardPercentage) /
            10000;
        globalPool += (outputAmount * config.globalPool) / 10000;

        if (globalPool > transferThreshold) {
            uint256 amountToTransfer = globalPool;
            globalPool = 0;
            IERC20(reachToken).safeTransfer(mainDistribution, amountToTransfer);
        }
    }
}
