// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";

contract TwttPool is Ownable {

    address public admin;
    IERC20 public twtt;
    mapping(uint256 => bool) public withdrawal;
    uint256 public airdropFee;
    mapping(uint256 => bool) public airdrop;

    string public constant CONTRACT_NAME = "Twtt Pool Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant DEPOSIT_TYPEHASH = keccak256("Deposit(uint256 userId,uint256 amount)");
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256("Withdraw(uint256 withdrawId,uint256 amount,uint256 deadline)");
    bytes32 public constant PREMIUM_AIRDROP_TYPEHASH = keccak256("PremiumAirdrop(uint256 userId,string twitterId,uint256 TAS,uint256 amount)");

    uint256 public constant TEAM_ALLOCATION = 25_000_000 ether;
    uint256 public constant VESTING_DURATION = 180 days;
    uint256 public teamRewardRate = TEAM_ALLOCATION / VESTING_DURATION;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public teamLastClaimed;

    event Deposit(address user, uint256 userId, uint256 amount);
    event Withdraw(address user, uint256 withdrawId, uint256 amount, uint256 deadline);
    event PremiumAirdrop(address user, uint256 userId, string twitterId, uint256 TAS, uint256 amount);

    constructor(uint256 _startTime) {
        admin = msg.sender;
        airdropFee = 40000_000000_000000;

        startTime = _startTime;
        endTime = startTime + VESTING_DURATION;
        teamLastClaimed = startTime;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setTwtt(address _twtt) external onlyOwner {
        twtt = IERC20(_twtt);
    }

    function setAirdropFee(uint256 fee) external onlyOwner {
        airdropFee = fee;
    }

    function deposit(uint256 userId, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DEPOSIT_TYPEHASH, userId, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        twtt.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, userId, amount);
    }

    function withdraw(uint256 withdrawId, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(withdrawal[withdrawId] == false, 'Already Executed.');
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(WITHDRAW_TYPEHASH, withdrawId, amount, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        withdrawal[withdrawId] = true;
        safeTwttTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, withdrawId, amount, deadline);
    }

    function premiumAirdrop(uint256 userId, string calldata twitterId, uint256 TAS, uint256 amount, uint8 v, bytes32 r, bytes32 s) external payable {
        require(airdrop[userId] == false, 'Already Executed.');
        require(msg.value == airdropFee, 'Invalid fee');
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PREMIUM_AIRDROP_TYPEHASH, userId, keccak256(abi.encodePacked(twitterId)), TAS, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        airdrop[userId] = true;
        emit PremiumAirdrop(msg.sender, userId, twitterId, TAS, amount);
    }

    function safeTwttTransfer(address _to, uint256 _amount) internal {
        uint256 _twttBal = twtt.balanceOf(address(this));
        if (_twttBal > 0) {
            if (_amount > _twttBal) {
                twtt.transfer(_to, _twttBal);
            } else {
                twtt.transfer(_to, _amount);
            }
        }
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function feeWithdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function claimRewards(address to) external onlyOwner {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (teamLastClaimed >= _now) return;

        uint256 _pending = (_now - teamLastClaimed) * teamRewardRate;
        if (_pending > 0 && to != address(0)) {
            safeTwttTransfer(to, _pending);
            teamLastClaimed = block.timestamp;
        }
    }
}
