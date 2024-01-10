//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IVesting.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";
import "./SafeERC20Holder.sol";
import "./Merkle.sol";

contract Vesting is IVesting, Ownable, SafeERC20Holder, Merkle {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public startTimestamp;
    bytes32 public root;

    uint256 public fDay;
    uint256 public fMonth;
    uint256 public fYear;

    string[] public rounds = ['seed', 'strategic', 'private'];

    mapping(string => uint256) public quarters;
    mapping(address => uint256) public earned;

    constructor(address token_, address owner_) {
        token = IERC20(token_);

        fDay = 21;
        fMonth = 5;
        fYear = 2022;

        startTimestamp = BokkyPooBahsDateTimeLibrary.timestampFromDate(
            fYear,
            fMonth,
            fDay
        );

        quarters['seed'] = 4;
        quarters['strategic'] = 2;
        quarters['private'] = 2;

        transferOwnership(owner_);
    }

    /// @inheritdoc IVesting
    function claim(uint256[] memory allocations, bytes32[] memory proof) external {
        require(block.timestamp > startTimestamp, 'Vesting have not started');
        uint256 total = unclaimed(msg.sender, allocations, proof);
        require(
            token.balanceOf(address(this)) >= total,
            'Not enough tokens on Vesting contract'
        );
        earned[msg.sender] += total;
        require(total > 0, 'You cant claim more');
        token.safeTransfer(msg.sender, total);
        emit Claim(block.timestamp, msg.sender, total);
    }

    /// @inheritdoc IVesting
    function unclaimed(
        address user,
        uint256[] memory allocations,
        bytes32[] memory proof
    ) public view returns (uint256) {
        require(block.timestamp > startTimestamp, 'Vesting have not started');
        require(allocations.length == rounds.length, 'Wrong input');
        bytes32 leaf = toLeaf(allocations, user);

        require(verify(proof, root, leaf), 'Wrong proof');
        uint256 length = allocations.length;
        uint256 total;
        for (uint256 i = 0; i < length; i++) {
            string memory round = rounds[i];
            uint256 allocation = allocations[i];
            total += unclaimedPerRound(round, allocation);
        }

        return total - earned[user];
    }

    /// @inheritdoc IVesting
    function unclaimedPerRound(string memory round, uint256 allocation)
        public
        view
        returns (uint256)
    {
        uint256 quarters_ = quarters[round];

        uint256 day = BokkyPooBahsDateTimeLibrary.getDay(block.timestamp);
        uint256 month = BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp);
        uint256 year = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp);

        if (day < fDay) month--;

        uint256 monthsPast = (year - fYear) * 12 + month - fMonth;
        uint256 quartersPast = monthsPast / 4 + 1;

        uint256 result = (allocation * quartersPast) / quarters_;
        return result > allocation ? allocation : result;
    }

    function start() external onlyOwner {
        require(block.timestamp < startTimestamp, 'Vesting has been already started');

        startTimestamp = block.timestamp;
        fDay = BokkyPooBahsDateTimeLibrary.getDay(startTimestamp);
        fMonth = BokkyPooBahsDateTimeLibrary.getMonth(startTimestamp);
        fYear = BokkyPooBahsDateTimeLibrary.getYear(startTimestamp);

        emit Start(block.timestamp, msg.sender);
    }

    /// @inheritdoc IVesting
    function setRoot(bytes32 root_) external onlyOwner {
        root = root_;
        emit SetRoot(block.timestamp, msg.sender, root);
    }

    /// @inheritdoc IVesting
    function setQuarters(string memory round, uint256 newQuarters) external onlyOwner {
        quarters[round] = newQuarters;
        emit SetQuarters(block.timestamp, msg.sender, round, newQuarters);
    }

    /// @inheritdoc IVesting
    function setRounds(string[] memory rounds_) external onlyOwner {
        rounds = rounds_;
        emit SetRounds(block.timestamp, msg.sender, rounds_);
    }

    function withdraw(IERC20 token_, uint256 amount) external onlyOwner {
        _withdraw(token_, amount);
    }

    /// @dev calculate leaf from allocations and user
    /// @param allocations allocation of user
    /// @param user address of user
    function toLeaf(uint256[] memory allocations, address user)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(allocations, user));
    }
}
