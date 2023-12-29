// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./AxelarExecutable.sol";
import "./IAxelarGateway.sol";
import "./IAxelarGasService.sol";

error NoDoubleStake();
error StakeBelowThreshhold();
error WithdrawBeforeLockupEnd();
error WithdrawOverBalance();
error AxelarBadSourceChain();
error AxelarBadSourceAddress();
error BadSourceAddress();

contract YespXStakeVerifier is Ownable, AxelarExecutable {
    enum DiscountTier {
        NO_TIER,
        TIER_1,
        TIER_2,
        TIER_3
    }
    mapping(DiscountTier => uint256) public discountThresholds;
    mapping(address => mapping(string => uint256)) public amountStakedPerChain;
    mapping(address => uint256) public amountStaked;
    mapping(address => uint256) public firstStakedTimestamp;
    mapping(address => uint256) public stakeModifiedTimestamp;
    mapping(address => uint256) public tickets;
    address[] public stakers;

    uint256 public numStakers;
    uint256 public totalStaked;
    uint256 public totalTickets;
    uint256 public modifiedTimestamp;
    uint256 public ticketStartTime;

    string public SOURCE_CHAIN; //TODO
    string public THIS_CHAIN; //TODO
    address public sourceAddressSameChain; //TODO
    string public sourceAddressCrossChain; //TODO

    constructor(
        string memory crossChainSourceChainName,
        string memory thisChainName,
        address _sourceAddressSameChain,
        string memory _sourceAddressCrossChain,
        address axelarExecutable
    ) AxelarExecutable(axelarExecutable) {
        discountThresholds[DiscountTier.TIER_1] = 1 * 10 ** 18; // 1 YESP;
        discountThresholds[DiscountTier.TIER_2] = 1 * 10 ** 6 * 10 ** 18; // 10m YESP;
        discountThresholds[DiscountTier.TIER_3] = 5 * 10 ** 6 * 10 ** 18; // 50m YESP;

        SOURCE_CHAIN = crossChainSourceChainName;
        THIS_CHAIN = thisChainName;
        sourceAddressSameChain = _sourceAddressSameChain;
        sourceAddressCrossChain = _sourceAddressCrossChain;
    }

    function updateTickets(address user) internal {
        if (stakeModifiedTimestamp[user] < ticketStartTime) {
            tickets[user] =
                amountStaked[user] *
                (block.timestamp - ticketStartTime);
        } else {
            tickets[user] =
                tickets[user] +
                amountStaked[user] *
                (block.timestamp - stakeModifiedTimestamp[user]);
        }
        stakeModifiedTimestamp[user] = block.timestamp;

        if (modifiedTimestamp < ticketStartTime) {
            totalTickets = totalStaked * (block.timestamp - ticketStartTime);
        } else {
            totalTickets =
                totalTickets +
                totalStaked *
                (block.timestamp - modifiedTimestamp);
        }
        modifiedTimestamp = block.timestamp;
    }

    function setTicketStartTime(uint256 startTime) external onlyOwner {
        ticketStartTime = startTime;
    }

    function isUserDiscountElegible(address user) external view returns (bool) {
        return amountStaked[user] >= discountThresholds[DiscountTier.TIER_1];
    }

    function userDiscountTier(
        address user
    ) external view returns (DiscountTier) {
        if (amountStaked[user] >= discountThresholds[DiscountTier.TIER_3])
            return (DiscountTier.TIER_3);
        if (amountStaked[user] >= discountThresholds[DiscountTier.TIER_2])
            return (DiscountTier.TIER_2);
        if (amountStaked[user] >= discountThresholds[DiscountTier.TIER_1])
            return (DiscountTier.TIER_1);
        return DiscountTier.NO_TIER;
    }

    function setSourceAddressSameChain(
        address sourceAddress_
    ) external onlyOwner {
        sourceAddressSameChain = sourceAddress_;
    }

    function setSourceAddressCrossChain(
        string calldata sourceAddress_
    ) external onlyOwner {
        sourceAddressCrossChain = sourceAddress_;
    }

    function adminSetDiscountThreshold(
        DiscountTier tier,
        uint256 threshold
    ) external onlyOwner {
        require(uint8(tier) <= uint8(DiscountTier.TIER_3), "Tier out of range");
        discountThresholds[tier] = threshold;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string.concat("0x", string(s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function executeFromSameChain(bytes calldata payload_) external {
        if (msg.sender != sourceAddressSameChain) {
            revert BadSourceAddress();
        }

        (address user, uint256 stakedAmount) = abi.decode(
            payload_,
            (address, uint256)
        );

        updateTickets(user);

        uint256 oldAmountStaked = amountStakedPerChain[user][THIS_CHAIN];
        amountStakedPerChain[user][THIS_CHAIN] = stakedAmount;

        amountStaked[user] =
            amountStaked[user] -
            oldAmountStaked +
            stakedAmount;

        totalStaked = totalStaked - oldAmountStaked + stakedAmount;

        if (firstStakedTimestamp[user] == 0) {
            firstStakedTimestamp[user] = block.timestamp;
            stakers.push(user);
            numStakers++;
        }
    }

    // handle for axelar setting isUserStaked data.
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        if (packHash(sourceChain_) != packHash(SOURCE_CHAIN))
            revert AxelarBadSourceChain();
        if (packHash(sourceAddress_) != packHash(sourceAddressCrossChain))
            revert AxelarBadSourceAddress();
        (address user, uint256 stakedAmount) = abi.decode(
            payload_,
            (address, uint256)
        );

        updateTickets(user);

        uint256 oldAmountStaked = amountStakedPerChain[user][SOURCE_CHAIN];
        amountStakedPerChain[user][SOURCE_CHAIN] = stakedAmount;

        amountStaked[user] =
            amountStaked[user] -
            oldAmountStaked +
            stakedAmount;

        totalStaked = totalStaked - oldAmountStaked + stakedAmount;

        if (firstStakedTimestamp[user] == 0) {
            firstStakedTimestamp[user] = block.timestamp;
            stakers.push(user);
            numStakers++;
        }
    }

    function packHash(
        string memory data
    ) internal pure returns (bytes32 dataHash) {
        dataHash = keccak256(abi.encode(data));
    }
}
