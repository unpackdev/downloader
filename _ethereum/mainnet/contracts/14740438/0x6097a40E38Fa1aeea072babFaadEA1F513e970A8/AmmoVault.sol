// SPDX-License-Identifier: UNLICENSED
import "./IERC20Upgradeable.sol";
import "./Math.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./console.sol";

pragma solidity ^0.8.4;

/**
    IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at 
    https://highstack.co in a contractor capacity.
    
    Highstack is not responsible for any malicious use or losses arising from using 
    or interacting with this smart contract.
**/


/**
 * @title ERC20 Claiming Vesting Vault for holders
 * @dev This vault is a claiming contract that allows users to register for
 * token vesting based on off chain signed txs (based on NFT holdings in this case)
 */

contract AmmoVault is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // ERC20 token being held by this contract
    IERC20Upgradeable public token;

    uint256 public tokensPerWei; // price expressed in wei.
    uint256 public openTime; // Time that registrations open
    uint256 public closeTime; // Time that registrations close
    uint256 public intervalDuration; // ie once a day, once a week etc where balances change.
    uint256 public totalIntervals; // ie total number of intervals AFTER initial claim;
    uint256 public initialClaimPercent; // ie 10% to claim immediately.

    struct UserInfo {
        uint256 totalTokens;
        uint256 intervalsClaimed;
        uint256 claimStart;
    }

    mapping(address => UserInfo) public users;

    receive() external payable {}

    function initialize(
        address _vestingToken,
        uint256 _tokensPerWei,
        uint256 _openTime
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(_vestingToken);
        tokensPerWei = _tokensPerWei;
        openTime = _openTime; // 1652130000 ideally

        // 10% claimed initially with 90% emitted at
        // 0.5% per day.
        initialClaimPercent = 10;
        totalIntervals = 180;
        intervalDuration = 86400;
    }

    /***********************/
    /***********************/
    /*** ADMIN FUNCTIONS ***/
    /***********************/
    /***********************/
    function setToken(address _tokenAddr) external onlyOwner {
        token = IERC20Upgradeable(_tokenAddr);
    }

    function setPrice(uint256 price) external onlyOwner {
        tokensPerWei = price;
    }

    function setTime(uint256 _openTime, uint256 _closeTime) external onlyOwner {
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function blacklistUser(address blacklistedAddress) public onlyOwner {
        // sets users token balance to zero but marks them as registered.
        // so future claims are all zero.
        users[blacklistedAddress] = UserInfo({
            totalTokens: 0,
            intervalsClaimed: 1,
            claimStart: block.timestamp
        });
    }

    function setVestingVariables(
        uint256 _intervalDuration,
        uint256 _totalIntervals,
        uint256 _initialClaimPercent
    ) public onlyOwner {
        intervalDuration = _intervalDuration;
        totalIntervals = _totalIntervals;
        initialClaimPercent = _initialClaimPercent;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = address(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    /***********************/
    /***********************/
    /*** PUBLIC FUNCTIONS **/
    /***********************/
    /***********************/

    function claim() public nonReentrant {
        UserInfo memory user = users[msg.sender];
        require(user.intervalsClaimed > 0, "Address not registered");
        require(
            totalIntervals - user.intervalsClaimed > 0,
            "None left to claim"
        );

        uint256 totalClaimableThisRound = totalClaimable(msg.sender);
        require(totalClaimableThisRound > 0, "Nothing to claim");

        user.intervalsClaimed++;
        users[msg.sender] = user;

        token.transfer(msg.sender, totalClaimableThisRound);
    }

    function whitelistRegister(
        uint256 amount,
        uint256 maxAmount,
        bytes32 msgHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable nonReentrant {
        require(amount <= msg.value * tokensPerWei, "Value below price");
        require(block.timestamp > openTime, "Registrations not open");
        require(block.timestamp < closeTime, "Registrations window closed");
        require(amount <= maxAmount, "Allocation Exceeded.");

        // Security check.
        bytes32 calculatedMsgHash = keccak256(
            abi.encodePacked(msg.sender, maxAmount)
        );
        require(calculatedMsgHash == msgHash, "Invalid hash");

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
            ),
            _v,
            _r,
            _s
        );

        require(owner() == signer, "Access denied");
        require(users[msg.sender].intervalsClaimed == 0, "Already Registered!");

        users[msg.sender] = UserInfo({
            totalTokens: amount,
            intervalsClaimed: 1,
            claimStart: block.timestamp
        });
        token.transfer(msg.sender, (amount * initialClaimPercent) / 100);
    }

    /***********************/
    /***********************/
    /*** VIEW FUNCTIONS ***/
    /***********************/
    /***********************/

    function totalClaimable(address userAddress)
        public
        view
        returns (uint256 totalClaimableThisRound)
    {
        UserInfo memory user = users[userAddress];

        uint256 totalAmountRemainingToClaim = user.totalTokens -
            ((user.totalTokens * initialClaimPercent) / 100);

        uint256 amountPerInterval = totalAmountRemainingToClaim /
            totalIntervals;

        uint256 intervalsElapsed = _intervalsElapsed(user.claimStart);

        totalClaimableThisRound =
            amountPerInterval *
            (intervalsElapsed - user.intervalsClaimed);
        // intervals claimed is always at minimum 1
        // so max that users can claim in a round
        // is the totalIntervals * amount per interval.
    }

    function nextClaimTime(address userAddress)
        public
        view
        returns (uint256 timestamp)
    {
        UserInfo memory user = users[userAddress];
        uint256 intervalsElapsed = _intervalsElapsed(user.claimStart);
        if ((intervalsElapsed) > totalIntervals || user.totalTokens == 0) {
            timestamp = 0;
        } else {
            timestamp = user.claimStart + (intervalsElapsed * intervalDuration);
        }
    }

    /***********************/
    /***********************/
    /** HELPER FUNCTIONS ***/
    /***********************/
    /***********************/

    function _intervalsElapsed(uint256 startTime)
        internal
        view
        returns (uint256 intervalsElapsed)
    {
        intervalsElapsed = ((block.timestamp - startTime) / intervalDuration);
        // note: division rounds down to nearest integer.

        intervalsElapsed = Math.min(intervalsElapsed, totalIntervals - 1) + 1;
        /** 
        for intervals elapsed: the first interval is already elapsed 
        on registration. We account for this actually since we alredy 
        mark the first interval as claimed upon registration.
        
        For maximum intervals: the number of claims here is equivalent
        to total intervals, but since the first is already claimed, 
        we subtract 1 from totalIntervals
        **/
    }
}
