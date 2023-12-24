// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.21;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IMatchPublicSale.sol";
import "./IDOConstants.sol";

contract MatchWhitelistSale is OwnableUpgradeable, ReentrancyGuardUpgradeable, IDOConstants {
    using SafeERC20 for IERC20;

    uint256 public totalEthersReceived;

    address public matchToken;
    address public matchPublicSale;

    // Merkle root of the whitelist
    bytes32 public merkleRoot;

    // Whether the owner has claimed the ether received
    bool public alreadyClaimedByOwner;

    // Amount of match tokens finally have been allocated to this contract
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

    event WhitelistRoundPurchased(address indexed user, uint256 amount);
    event MatchTokenAllocated(uint256 amount);
    event MatchTokenClaimed(address indexed user, uint256 amount);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    function isSoldOut() public view returns (bool) {
        return totalEthersReceived == ETH_CAP_WL;
    }

    // How many match tokens are finally allocated to whitelist round users
    // After public sale is end, this return value is the final amount of match tokens to whitelist sale
    function totalWhitelistAllocation() public view returns (uint256) {
        uint256 totalEthersReceivedByPublic = IMatchPublicSale(matchPublicSale).totalEthersReceived();

        // Total ETH = Ethers Received by WL & Public <= 375 ETH
        // Total Match = 1500000 (fixed)
        uint256 portionToWhitelist = (totalEthersReceived * SCALE) /
            (totalEthersReceivedByPublic + totalEthersReceived);

        return (MATCH_CAP_TOTAL * portionToWhitelist) / SCALE;
    }

    // How many match tokens can user claim
    // This is not accurate when the sale is not end
    // It will change with time until the sale is end
    function userClaimableAmount(address _user) public view returns (uint256) {
        uint256 allocation = totalWhitelistAllocation();

        if (totalEthersReceived == 0) return 0;

        // If the user has not purchased or already claimed, no claimable amount
        if (users[_user].amount == 0 || users[_user].claimed) {
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

    // Current match price
    // It will change with time until the sale is end
    function currentMatchPrice() public view returns (uint256) {
        uint256 ethersReceivedByPublicSale = IMatchPublicSale(matchPublicSale).totalEthersReceived();

        uint256 totalEthers = totalEthersReceived + ethersReceivedByPublicSale;

        return (totalEthers * SCALE) / MATCH_CAP_TOTAL;
    }

    function setMatchToken(address _matchToken) external onlyOwner {
        matchToken = _matchToken;
    }

    function setMatchPublicSaleContract(address _matchPublicSale) external onlyOwner {
        matchPublicSale = _matchPublicSale;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function purchase(bytes32[] memory _proof) external payable nonReentrant {
        require(_withinPeriod(), "IDO is not started or finished");
        require(msg.value > 0, "No ether sent");
        require(totalEthersReceived + msg.value <= ETH_CAP_WL, "ETH cap exceeded");

        // Verify if the user provides correct proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");

        users[msg.sender].amount += msg.value;
        totalEthersReceived += msg.value;

        emit WhitelistRoundPurchased(msg.sender, msg.value);
    }

    function setTGETimestamp(uint256 _tgeTimestamp) external onlyOwner {
        tgeTimestamp = _tgeTimestamp;
    }

    // Allocate match tokens to users and then can be claimed
    // Only after the public round is also finished
    function allocateMatchTokens() external onlyOwner {
        require(block.timestamp > PUB_END, "IDO is not finished yet");

        uint256 allocation = totalWhitelistAllocation();
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
        return block.timestamp >= WL_START && block.timestamp <= WL_END;
    }
}
