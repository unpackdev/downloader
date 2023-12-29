// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.21;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IMatchWhitelistSale.sol";
import "./IDOConstants.sol";

contract MatchPublicSale is OwnableUpgradeable, ReentrancyGuardUpgradeable, IDOConstants {
    using SafeERC20 for IERC20;

    uint256 public ethTargetAmount;

    uint256 public totalEthersReceived;

    address public matchToken;
    address public matchWhitelistSale;

    // Whether the owner has claimed the ether received
    bool public alreadyClaimedByOwner;

    // Amount of match tokens have been allocated to this contract
    // Only after this is true, users can claim their match tokens
    uint256 public matchTokenAllocated;

    struct UserInfo {
        uint256 amount;
        bool claimed; // ! not used, no meaning
    }
    mapping(address => UserInfo) public users;

    // ! Added 2023-12-21
    // ! Contract updated for the new vesting logic
    uint256 public constant TGE = 30; // 30% of match tokens are released at TGE
    uint256 public constant VESTING_TIME = 365 days; // 365 days vesting period

    uint256 public tgeTimestamp;

    // How many match tokens have been claimed by the user
    mapping(address => uint256) public userClaimedAmount;

    // ! End of added 2023-12-21

    event PublicSaleInitialized(uint256 ethTarget);
    event PublicRoundPurchased(address indexed user, uint256 amount);
    event MatchTokenAllocated(uint256 amount);
    event MatchTokenClaimed(address indexed user, uint256 amount);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    // After public sale is end, this return value is the final amount of match tokens to public sale
    function totalPublicAllocation() public view returns (uint256) {
        uint256 totalEthersReceivedByWhitelist = IMatchWhitelistSale(matchWhitelistSale).totalEthersReceived();

        // Total ETH = Min(375ETH, Ethers Received by WL & Public)
        // Total Match = 1500000 (fixed)
        uint256 portionToPublic = (totalEthersReceived * SCALE) /
            (totalEthersReceivedByWhitelist + totalEthersReceived);

        return (MATCH_CAP_TOTAL * portionToPublic) / SCALE;
    }

    function userClaimableAmount(address _user) public view returns (uint256) {
        uint256 allocation = totalPublicAllocation();

        // If not received any ether, no claimable amount
        if (totalEthersReceived == 0) return 0;

        // If the user has not purchased or already claimed, no claimable amount
        if (users[_user].amount == 0) {
            return 0;
        }

        return (allocation * users[_user].amount) / totalEthersReceived;
    }

    function userCurrentRelease(address _user) public view returns (uint256) {
        uint256 totalAmount = userClaimableAmount(_user);

        if (block.timestamp <= tgeTimestamp) return 0;
        if (block.timestamp >= tgeTimestamp + VESTING_TIME) return totalAmount;

        uint256 tgeAmount = (totalAmount * TGE) / 100;

        uint256 timePassed = block.timestamp - tgeTimestamp;
        uint256 vestingAmount = ((totalAmount - tgeAmount) * timePassed) / VESTING_TIME;

        return tgeAmount + vestingAmount;
    }

    function currentMatchPrice() public view returns (uint256) {
        uint256 ethersReceivedByWhitelist = IMatchWhitelistSale(matchWhitelistSale).totalEthersReceived();

        uint256 totalEthers = totalEthersReceived + ethersReceivedByWhitelist;

        return (totalEthers * SCALE) / MATCH_CAP_TOTAL;
    }

    function setMatchToken(address _matchToken) external onlyOwner {
        matchToken = _matchToken;
    }

    function setMatchWhitelistSale(address _matchWhitelistSale) external onlyOwner {
        matchWhitelistSale = _matchWhitelistSale;
    }

    function setTGETimestamp(uint256 _tgeTimestamp) external onlyOwner {
        tgeTimestamp = _tgeTimestamp;
    }

    function initializePublicSale() external {
        require(ethTargetAmount == 0, "Already initialized");
        require(block.timestamp >= WL_END, "Whitelist sale not ended");

        // 375 ETH - whitelist received ether = public sale target amount
        ethTargetAmount = ETH_CAP_TOTAL - IMatchWhitelistSale(matchWhitelistSale).totalEthersReceived();

        emit PublicSaleInitialized(matchTokenAllocated);
    }

    /**
     * @notice Purchase match tokens by sending ethers
     *
     *
     */
    function purchase() external payable nonReentrant {
        require(_withinPeriod(), "IDO public sale not start/finish");
        require(msg.value > 0, "No ether sent");
        require(ethTargetAmount > 0, "Public sale not initialized");

        // Check if overflow
        require(totalEthersReceived + msg.value <= ethTargetAmount, "ETH cap exceeded");

        // Update user and total record
        users[msg.sender].amount += msg.value;
        totalEthersReceived += msg.value;

        emit PublicRoundPurchased(msg.sender, msg.value);
    }

    // Allocate match tokens to users and then can be claimed
    // Only after the public round is also finished
    function allocateMatchTokens() external onlyOwner {
        require(block.timestamp > PUB_END, "IDO public sale not finished");

        uint256 allocation = totalPublicAllocation();
        IERC20(matchToken).safeTransferFrom(msg.sender, address(this), allocation);

        matchTokenAllocated = allocation;

        emit MatchTokenAllocated(allocation);
    }

    // Claim match tokens
    function claim() external nonReentrant {
        require(block.timestamp > tgeTimestamp && tgeTimestamp > 0, "TGE is not reached yet");
        require(matchTokenAllocated > 0, "Match tokens not allocated yet");

        uint256 releasedAmount = userCurrentRelease(msg.sender);
        require(releasedAmount > 0, "No match token to claim");

        // ! Added 2023-12-21
        uint256 amountToClaim = releasedAmount - userClaimedAmount[msg.sender];
        userClaimedAmount[msg.sender] += amountToClaim;

        IERC20(matchToken).safeTransfer(msg.sender, amountToClaim);

        emit MatchTokenClaimed(msg.sender, amountToClaim);
    }

    // Owner claim all funds out of the contract
    function claimFund() external onlyOwner {
        require(block.timestamp > PUB_END, "IDO is not finished yet");
        require(!alreadyClaimedByOwner, "Already claimed by owner");

        alreadyClaimedByOwner = true;

        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Claim failed");
    }

    function _withinPeriod() internal view returns (bool) {
        return block.timestamp >= PUB_START && block.timestamp <= PUB_END;
    }
}
