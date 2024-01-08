// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./OwnableUpgradeable.sol";
import "./Address.sol";

import "./IContractsRegistry.sol";
import "./IPolicyBookFacade.sol";
import "./IPolicyBook.sol";
import "./IPolicyBookRegistry.sol";
import "./IShieldMining.sol";
import "./IUserLeveragePool.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract ShieldMining is IShieldMining, OwnableUpgradeable, ReentrancyGuard, AbstractDependant {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public policyBookFabric;
    IPolicyBookRegistry public policyBookRegistry;

    mapping(address => ShieldMiningInfo) public shieldMiningInfo;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) internal _rewards;

    /// @dev    block number to reward per block (to substrate)
    mapping(address => mapping(uint256 => uint256)) public endOfRewards;

    event ShieldMiningAssociated(address indexed policyBook, address indexed shieldToken);
    event ShieldMiningFilled(
        address indexed policyBook,
        address indexed shieldToken,
        uint256 amount,
        uint256 lastBlockWithReward
    );
    event ShieldMiningClaimed(address indexed user, address indexed policyBook, uint256 reward);
    event ShieldMiningRecovered(address indexed policyBook, uint256 amount);

    /// @dev    Check if the address for the policyBook correspond to an existing
    modifier isPolicyBookOrLeverage(address _policyBook) {
        require(
            policyBookRegistry.isPolicyBook(_policyBook),
            "SM: inexistant policyBook or leverage pool"
        );
        _;
    }

    modifier shieldMiningEnabled(address _policyBook) {
        require(
            address(shieldMiningInfo[_policyBook].rewardsToken) != address(0),
            "SM: no shield mining associated"
        );
        _;
    }

    modifier updateReward(address _policyBook, address account) {
        _updateReward(_policyBook, account);
        _;
    }

    function __ShieldMining_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        policyBookFabric = _contractsRegistry.getPolicyBookFabricContract();
    }

    function blocksWithRewardsPassed(address _policyBook, uint256 _to)
        public
        view
        override
        returns (uint256)
    {
        uint256 from = shieldMiningInfo[_policyBook].lastUpdateBlock;

        return from >= _to ? 0 : _to.sub(from);
    }

    function rewardPerToken(address _policyBook) public override returns (uint256) {
        uint256 totalPoolStaked = shieldMiningInfo[_policyBook].totalSupply;

        if (totalPoolStaked == 0) {
            return shieldMiningInfo[_policyBook].rewardPerTokenStored;
        }

        uint256 accumulatedReward;

        uint256 length = shieldMiningInfo[_policyBook].endsOfDistribution.length;
        if (length != 0) {
            for (uint256 i = 0; i < length; i++) {
                if (shieldMiningInfo[_policyBook].endsOfDistribution[0] > block.number) {
                    break;
                } else {
                    accumulatedReward += blocksWithRewardsPassed(
                        _policyBook,
                        shieldMiningInfo[_policyBook].endsOfDistribution[0]
                    )
                        .mul(shieldMiningInfo[_policyBook].rewardPerBlock)
                        .mul(10**uint256(shieldMiningInfo[_policyBook].decimals))
                        .div(totalPoolStaked);

                    shieldMiningInfo[_policyBook].lastUpdateBlock = shieldMiningInfo[_policyBook]
                        .endsOfDistribution[0];
                    _deleteEndBlock(_policyBook);
                }
            }
        }

        accumulatedReward += blocksWithRewardsPassed(_policyBook, block.number)
            .mul(shieldMiningInfo[_policyBook].rewardPerBlock)
            .mul(10**uint256(shieldMiningInfo[_policyBook].decimals))
            .div(totalPoolStaked);

        return shieldMiningInfo[_policyBook].rewardPerTokenStored.add(accumulatedReward);
    }

    function updateTotalSupply(
        address _policyBook,
        uint256 newTotalSupply,
        address liquidityProvider
    ) external override updateReward(_policyBook, liquidityProvider) {
        require(
            policyBookRegistry.isPolicyBookFacade(_msgSender()) || _msgSender() == _policyBook,
            "SM: No access"
        );

        if (shieldMiningInfo[_policyBook].totalSupply == 0) {
            uint256 blockElapsed =
                shieldMiningInfo[_policyBook].lastUpdateBlock.sub(
                    shieldMiningInfo[_policyBook].lastBlockBeforePause
                );

            // postpone for each
            for (uint256 i = 0; i < shieldMiningInfo[_policyBook].endsOfDistribution.length; i++) {
                uint256 amount =
                    endOfRewards[_policyBook][shieldMiningInfo[_policyBook].endsOfDistribution[i]];
                delete endOfRewards[_policyBook][
                    shieldMiningInfo[_policyBook].endsOfDistribution[i]
                ];
                shieldMiningInfo[_policyBook].endsOfDistribution[i] += blockElapsed;
                endOfRewards[_policyBook][
                    shieldMiningInfo[_policyBook].endsOfDistribution[i]
                ] = amount;
            }

            shieldMiningInfo[_policyBook].lastBlockBeforePause = 0;
        }

        if (newTotalSupply == 0) {
            shieldMiningInfo[_policyBook].lastBlockBeforePause = shieldMiningInfo[_policyBook]
                .lastUpdateBlock;
        }

        shieldMiningInfo[_policyBook].totalSupply = newTotalSupply;
    }

    function earned(address _policyBook, address _account) public override returns (uint256) {
        uint256 rewardsDifference =
            rewardPerToken(_policyBook).sub(userRewardPerTokenPaid[_account][_policyBook]);

        uint256 userLiquidity;
        if (policyBookRegistry.isUserLeveragePool(_policyBook)) {
            userLiquidity = IUserLeveragePool(_policyBook).userLiquidity(_account);
        } else {
            userLiquidity = IPolicyBookFacade(IPolicyBook(_policyBook).policyBookFacade())
                .userLiquidity(_account);
        }

        uint256 newlyAccumulated =
            userLiquidity.mul(rewardsDifference).div(
                10**uint256(shieldMiningInfo[_policyBook].decimals)
            );

        return _rewards[_account][_policyBook].add(newlyAccumulated);
    }

    function associateShieldMining(address _policyBook, address _shieldMiningToken)
        external
        override
        isPolicyBookOrLeverage(_policyBook)
    {
        require(_msgSender() == policyBookFabric || _msgSender() == owner(), "SM: no access");
        // should revert with "Address: not a contract" if it's an account
        _shieldMiningToken.functionCall(
            abi.encodeWithSignature("totalSupply()", ""),
            "SM: is not an ERC20"
        );

        delete shieldMiningInfo[_policyBook];

        shieldMiningInfo[_policyBook].totalSupply = IERC20(_policyBook).totalSupply();
        shieldMiningInfo[_policyBook].rewardsToken = IERC20(_shieldMiningToken);
        shieldMiningInfo[_policyBook].decimals = ERC20(_shieldMiningToken).decimals();

        emit ShieldMiningAssociated(_policyBook, _shieldMiningToken);
    }

    function fillShieldMining(
        address _policyBook,
        uint256 _amount,
        uint256 _duration
    ) external override shieldMiningEnabled(_policyBook) {
        require(_duration >= 22 && _duration <= 366, "SM: out of minimum/maximum duration");

        uint256 _rewardPerBlock =
            _amount.div(_duration).mul(PRECISION).div(BLOCKS_PER_DAY).div(PRECISION);
        require(_rewardPerBlock > 0, "SM: deposit too low");

        uint256 blocksAmount = _duration.mul(BLOCKS_PER_DAY);

        shieldMiningInfo[_policyBook].rewardsToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );

        _setRewards(_policyBook, _rewardPerBlock, block.number, blocksAmount);

        emit ShieldMiningFilled(
            _policyBook,
            address(shieldMiningInfo[_policyBook].rewardsToken),
            _amount,
            block.number + blocksAmount
        );
    }

    function getReward(address _policyBook)
        public
        override
        nonReentrant
        updateReward(_policyBook, _msgSender())
    {
        uint256 reward = _rewards[_msgSender()][_policyBook];

        if (reward > 0) {
            delete _rewards[_msgSender()][_policyBook];

            // transfer profit to the user
            shieldMiningInfo[_policyBook].rewardsToken.safeTransfer(_msgSender(), reward);

            emit ShieldMiningClaimed(_msgSender(), _policyBook, reward);
        }
    }

    /// @notice returns APY% with 10**5 precision
    function getAPY(address _policyBook, uint256 liquidityAdded_)
        external
        view
        override
        returns (uint256)
    {
        uint256 futureReward = _getFutureRewardTokens(_policyBook, block.number);

        if (shieldMiningInfo[_policyBook].totalSupply == 0 && liquidityAdded_ == 0) {
            return 0;
        } else {
            return
                futureReward.mul(10**5).div(
                    shieldMiningInfo[_policyBook].totalSupply.add(liquidityAdded_)
                );
        }
    }

    function recoverNonLockedRewardTokens(address _policyBook) external override onlyOwner {
        uint256 nonLockedTokens =
            shieldMiningInfo[_policyBook].rewardsToken.balanceOf(address(this)).sub(
                shieldMiningInfo[_policyBook].rewardTokensLocked
            );

        shieldMiningInfo[_policyBook].rewardsToken.safeTransfer(owner(), nonLockedTokens);

        emit ShieldMiningRecovered(_policyBook, nonLockedTokens);
    }

    function getShieldTokenAddress(address _policyBook) external view override returns (address) {
        return address(shieldMiningInfo[_policyBook].rewardsToken);
    }

    function getShieldMiningInfo(address _policyBook)
        external
        view
        override
        returns (ShieldMiningInfo memory _shieldMiningInfo)
    {
        _shieldMiningInfo = ShieldMiningInfo(
            shieldMiningInfo[_policyBook].rewardsToken,
            shieldMiningInfo[_policyBook].decimals,
            shieldMiningInfo[_policyBook].rewardPerBlock,
            shieldMiningInfo[_policyBook].lastUpdateBlock,
            shieldMiningInfo[_policyBook].lastBlockBeforePause,
            shieldMiningInfo[_policyBook].rewardPerTokenStored,
            shieldMiningInfo[_policyBook].rewardTokensLocked,
            shieldMiningInfo[_policyBook].totalSupply,
            shieldMiningInfo[_policyBook].endsOfDistribution
        );
    }

    function getUserRewardPaid(address _policyBook, address _account)
        external
        view
        override
        returns (uint256)
    {
        return userRewardPerTokenPaid[_account][_policyBook];
    }

    function getEndOfDistributionAmount(address _policyBook, uint256 _endBlock)
        external
        view
        returns (uint256)
    {
        return endOfRewards[_policyBook][_endBlock];
    }

    function _setRewards(
        address _policyBook,
        uint256 _rewardPerBlock,
        uint256 _startingBlock,
        uint256 _blocksAmount
    ) internal updateReward(_policyBook, address(0)) {
        shieldMiningInfo[_policyBook].rewardPerBlock += _rewardPerBlock;

        uint256 endBlock = _startingBlock.add(_blocksAmount).sub(1);

        // liquidity in the pool?
        if (shieldMiningInfo[_policyBook].totalSupply == 0) {
            if (shieldMiningInfo[_policyBook].lastBlockBeforePause == 0) {
                shieldMiningInfo[_policyBook].lastBlockBeforePause = shieldMiningInfo[_policyBook]
                    .lastUpdateBlock;
            } else {
                endBlock -= shieldMiningInfo[_policyBook].lastUpdateBlock.sub(
                    shieldMiningInfo[_policyBook].lastBlockBeforePause
                );
            }
        }

        shieldMiningInfo[_policyBook].endsOfDistribution = _newEndBlock(_policyBook, endBlock);
        endOfRewards[_policyBook][endBlock] += _rewardPerBlock;

        shieldMiningInfo[_policyBook].rewardTokensLocked = _getFutureRewardTokens(
            _policyBook,
            shieldMiningInfo[_policyBook].lastUpdateBlock
        );

        require(
            shieldMiningInfo[_policyBook].rewardTokensLocked <=
                shieldMiningInfo[_policyBook].rewardsToken.balanceOf(address(this)),
            "SM: Not enough tokens for the rewards"
        );
    }

    function _newEndBlock(address _policyBook, uint256 _endBlock)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory oldArray = shieldMiningInfo[_policyBook].endsOfDistribution;
        uint256 length = oldArray.length;
        uint256[] memory newArray = new uint256[](length + 1);
        bool inserted;

        for (uint256 i = 0; i < length; i++) {
            if (!inserted) {
                if (_endBlock < oldArray[i]) {
                    newArray[i] = _endBlock;
                    inserted = true;
                } else if (_endBlock > oldArray[i]) {
                    newArray[i] = oldArray[i];
                } else {
                    return oldArray;
                }
            } else {
                newArray[i] = oldArray[i - 1];
            }
        }

        if (!inserted) {
            newArray[length] = _endBlock;
        } else {
            newArray[length] = oldArray[length - 1];
        }

        return newArray;
    }

    function _deleteEndBlock(address _policyBook) internal {
        uint256[] memory oldArray = shieldMiningInfo[_policyBook].endsOfDistribution;
        uint256 length = oldArray.length;
        uint256[] memory newArray = new uint256[](length - 1);

        shieldMiningInfo[_policyBook].rewardPerBlock -= endOfRewards[_policyBook][oldArray[0]];
        delete endOfRewards[_policyBook][oldArray[0]];

        for (uint256 i = 0; i < length - 1; i++) {
            newArray[i] = oldArray[i + 1];
        }

        shieldMiningInfo[_policyBook].endsOfDistribution = newArray;
    }

    function _updateReward(address _policyBook, address account) internal {
        uint256 currentRewardPerToken = rewardPerToken(_policyBook);

        shieldMiningInfo[_policyBook].rewardPerTokenStored = currentRewardPerToken;
        shieldMiningInfo[_policyBook].lastUpdateBlock = block.number;

        if (account != address(0)) {
            _rewards[account][_policyBook] = earned(_policyBook, account);
            userRewardPerTokenPaid[account][_policyBook] = currentRewardPerToken;
        }
    }

    function _getFutureRewardTokens(address _policyBook, uint256 _from)
        internal
        view
        returns (uint256)
    {
        uint256 rewardPerBlock = shieldMiningInfo[_policyBook].rewardPerBlock;
        uint256 lastUpdateBlock = _from; // should be block.number
        uint256 futureReward;
        uint256[] memory endsBlock = shieldMiningInfo[_policyBook].endsOfDistribution;

        if (endsBlock.length != 0) {
            for (uint256 i = 0; i < endsBlock.length; i++) {
                uint256 blocksLeft = _calculateBlocksLeft(lastUpdateBlock, endsBlock[i]);
                lastUpdateBlock = endsBlock[i];
                futureReward += blocksLeft.mul(rewardPerBlock);
                rewardPerBlock -= endOfRewards[_policyBook][endsBlock[i]];
            }
        }

        return futureReward;
    }

    function _calculateBlocksLeft(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (block.number >= _to) return 0;

        if (block.number < _from) return _to.sub(_from).add(1);

        return _to.sub(block.number);
    }
}
