// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC1155Receiver.sol";
import "./IERC1155.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./IRewardVesting.sol";

struct Reward {
    uint256 numberOfHeros;
    uint256 withdrawnTokens;
    uint256 tokensAllotment;
    uint256 _initialTimestamp;
    bool isIntialized;
}

contract RewardVesting is Ownable, ERC1155Receiver, IRewardVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event WithdrawnTokens(address indexed investor, uint256 value);

    mapping(address => Reward) public rewardsInfo;

    uint256 public totalVestingDay = 182;

    address stakingContract;
    IERC20 public token;
    IERC1155 private heroAddress;

    uint256 public collectionId;

    // modifiers

    modifier onlyStakingcontract() {
        require(
            _msgSender() == stakingContract,
            "Only Staking Address allowed"
        );
        _;
    }

    constructor(
        address _token,
        address _heroAddress,
        address _stakingAddress
    ) {
        token = IERC20(_token);
        heroAddress = IERC1155(_heroAddress);
        stakingContract = _stakingAddress;
    }

    function changeHeroAddress(address _heroAddress) public onlyOwner {
        heroAddress = IERC1155(_heroAddress);
    }

    function changeRewardToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function changeCollectionId(uint256 newCollectionId) public onlyOwner {
        collectionId = newCollectionId;
    }

    function changeStaking(address _stakingAddress) public onlyOwner {
        stakingContract = _stakingAddress;
    }

    function addReward(address account, uint256 tokenAmount)
        external
        virtual
        override
        onlyStakingcontract
    {
        if (rewardsInfo[account].isIntialized) {
            rewardsInfo[account].tokensAllotment += tokenAmount;
        } else {
            rewardsInfo[account] = Reward(0, 0, tokenAmount, 0, true);
        }
    }

    function withdrawTokens() external {
        Reward storage reward = rewardsInfo[msg.sender];
        require(
            reward.numberOfHeros > 0,
            "You Need To DepositHero Before WithDrawing"
        );
        uint256 tokensAvailable = withdrawableTokens(reward);
        require(tokensAvailable > 0, "no tokens available for withdrawal");

        reward.withdrawnTokens = reward.withdrawnTokens.add(tokensAvailable);
        token.safeTransfer(_msgSender(), tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    function withdrawableTokens(Reward memory reward)
        public
        view
        returns (uint256 tokens)
    {
        uint256 availablePercentage = _calculateAvailablePercentage(
            reward._initialTimestamp,
            reward.numberOfHeros
        );
        uint256 noOfTokens = _calculatePercentage(
            reward.tokensAllotment,
            availablePercentage
        );
        uint256 tokensAvailable = noOfTokens.sub(reward.withdrawnTokens);
        return tokensAvailable;
    }

    function _calculateAvailablePercentage(
        uint256 intialTimeStamp,
        uint256 rate
    ) public view returns (uint256 availablePercentage) {
        if (rate == 0) {
            return 0;
        }

        uint256 remainingDistroPercentage = 100;
        uint256 currentTimeStamp = block.timestamp;
        uint256 vestingDays = totalVestingDay.div(rate);
        uint256 vestingDuration = BokkyPooBahsDateTimeLibrary.addDays(
            intialTimeStamp,
            vestingDays
        );

        uint256 noOfSecondsRemaining = uint256(totalVestingDay).mul(86400);

        uint256 everySecondReleasePercentage = remainingDistroPercentage
            .mul(1e18)
            .div(noOfSecondsRemaining);

        if (currentTimeStamp > intialTimeStamp) {
            if (currentTimeStamp < vestingDuration) {
                uint256 noOfSeconds = BokkyPooBahsDateTimeLibrary.diffSeconds(
                    intialTimeStamp,
                    currentTimeStamp
                );

                return noOfSeconds.mul(everySecondReleasePercentage);
            } else {
                return uint256(100).mul(1e18);
            }
        } else {
            return 0;
        }
    }

    function depositHeros(uint256 numberOfHeros) external {
        if (rewardsInfo[msg.sender].isIntialized) {
            rewardsInfo[msg.sender]._initialTimestamp = block.timestamp;
            rewardsInfo[msg.sender].numberOfHeros += numberOfHeros;
        } else {
            rewardsInfo[msg.sender] = Reward(
                numberOfHeros,
                0,
                0,
                block.timestamp,
                true
            );
        }
        heroAddress.safeTransferFrom(
            msg.sender,
            address(this),
            collectionId,
            numberOfHeros,
            ""
        );
    }

    function withDrawHeros(uint256 numberOfHeros) external {
        require(
            rewardsInfo[msg.sender].numberOfHeros >= numberOfHeros,
            "Heros Not Deposited"
        );
        rewardsInfo[msg.sender].tokensAllotment -= rewardsInfo[msg.sender]
            .withdrawnTokens;
        rewardsInfo[msg.sender].numberOfHeros -= numberOfHeros;
        rewardsInfo[msg.sender].withdrawnTokens = 0;
        heroAddress.safeTransferFrom(
            address(this),
            msg.sender,
            collectionId,
            numberOfHeros,
            ""
        );
    }

    /// @dev calculate percentage value from amount
    /// @param _amount amount input to find the percentage
    /// @param _percentage percentage for an amount
    function _calculatePercentage(uint256 _amount, uint256 _percentage)
        private
        pure
        returns (uint256 percentage)
    {
        return _amount.mul(_percentage).div(100).div(1e18);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
