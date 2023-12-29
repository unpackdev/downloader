// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

contract DUELStaking is Ownable {
    address public duelToken;
    address moderator;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint32 durationDays;
        bytes32 lastClaimedCheckpoint;
    }
    mapping(address => Stake[]) public walletStakes;
    mapping(address => bytes32) public lastClaimedCheckpoint;
    bytes32 public currentCheckpoint;

    event Staked(address wallet, uint256 amount, uint32 periodDays);
    event Unstaked(address wallet, Stake stakeInfo);

    constructor(address _duelToken) Ownable(msg.sender) {
        duelToken = _duelToken;
    }

    function updateStakeCheckpoint(bytes32 newCheckpoint) external {
        require(
            _msgSender() == moderator || _msgSender() == owner(),
            "Access forbidden"
        );
        currentCheckpoint = newCheckpoint;
    }

    function stakeDUEL(uint256 amount, uint32 periodDays) external {
        IERC20(duelToken).transferFrom(_msgSender(), address(this), amount);
        Stake memory newStake = Stake({
            amount: amount,
            startTime: block.timestamp,
            durationDays: periodDays,
            lastClaimedCheckpoint: ""
        });

        walletStakes[_msgSender()].push(newStake);
        emit Staked(_msgSender(), amount, periodDays);
    }

    function stakeFor(
        address wallet,
        uint256 amount,
        uint32 periodDays
    ) public {
        require(_msgSender() == duelToken, "Access forbidden");

        IERC20(duelToken).transferFrom(owner(), address(this), amount);
        Stake memory newStake = Stake({
            amount: amount,
            startTime: block.timestamp,
            durationDays: periodDays,
            lastClaimedCheckpoint: ""
        });

        walletStakes[wallet].push(newStake);
        emit Staked(wallet, amount, periodDays);
    }

    function getStakesLength(address wallet) external view returns (uint256) {
        return walletStakes[wallet].length;
    }

    function getStake(
        address wallet,
        uint16 index
    )
        public
        view
        returns (
            Stake memory stakeInfo,
            uint256 poolShareFactor,
            uint256 poolShareBase
        )
    {
        stakeInfo = walletStakes[wallet][index];

        poolShareBase = 10000;
        uint256 totalDuel = IERC20(duelToken).balanceOf(address(this));
        poolShareFactor = (stakeInfo.amount * poolShareBase) / totalDuel;
    }

    function claimStake(
        uint16 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        (Stake memory stakeInfo, , ) = getStake(_msgSender(), index);
        require(stakeInfo.amount > 0, "Stake not active");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, currentCheckpoint, leaf),
            "Incorrect proof"
        );
        require(
            lastClaimedCheckpoint[_msgSender()] != currentCheckpoint,
            "Stake already claimed till today"
        );

        lastClaimedCheckpoint[_msgSender()] = currentCheckpoint;
        IERC20(duelToken).transferFrom(owner(), _msgSender(), amount);
    }

    function unstake(uint16 index) external {
        (Stake memory stakeInfo, , ) = getStake(_msgSender(), index);
        require(stakeInfo.amount > 0, "Stake not active");

        require(
            block.timestamp >=
                stakeInfo.startTime + stakeInfo.durationDays * 1 days,
            "Stake still locked"
        );

        delete walletStakes[_msgSender()][index];
        IERC20(duelToken).transfer(_msgSender(), stakeInfo.amount);
        emit Unstaked(_msgSender(), stakeInfo);
    }
}
