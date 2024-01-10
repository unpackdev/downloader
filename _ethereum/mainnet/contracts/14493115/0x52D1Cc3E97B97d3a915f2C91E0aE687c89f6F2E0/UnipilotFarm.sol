// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

//Utilities
import "./IUnipilotFarm.sol";
import "./ReentrancyGuard.sol";
import "./FullMath.sol";

// openzeppelin helpers
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

/// @title Unipilot Farm
/// @author @UnipilotDev
/// @notice Contract for staking Unipilot v2 lp's in farm and earn rewards

contract UnipilotFarm is IUnipilotFarm, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private immutable pilot;

    address public governance;
    uint256 public rewardPerBlock;
    uint256 private totalVaults;
    uint256 public farmingGrowthBlockLimit;

    mapping(uint256 => address) private vaults;

    /// @notice contains the vault data for each vault being operated in the farm
    mapping(address => VaultInfo) public vaultInfo;

    /// @notice contains the vault alt data for each vault being operated in the farm
    mapping(address => AltInfo) public vaultAltInfo;

    /// @notice contains the data for each user who are involved in the vaults farm
    mapping(address => mapping(address => UserInfo)) public userInfo;

    /// @notice contains the vaults which are active(whitelist == true)
    mapping(address => bool) public vaultWhitelist;

    constructor(
        address _governance,
        address _pilot,
        uint256 _rewardPerBlock
    ) {
        require(_governance != address(0) && _pilot != address(0), "ZA");
        require(_rewardPerBlock > 0, "IV");
        governance = _governance;
        pilot = _pilot;
        rewardPerBlock = _rewardPerBlock;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyGovernance() {
        require(msg.sender == governance, "NA");
        _;
    }

    /// @notice use to whitelist the vault. If the vault is being
    /// added for the first time it is added to the vault mapping
    /// @dev only called by governance
    /// @param _vault list of vaults to be add in farm
    /// @param _multiplier multiplier w.r.t vault index
    function initializer(
        address[] calldata _vault,
        uint256[] calldata _multiplier,
        RewardType[] calldata _rewardType,
        address[] calldata _rewardToken
    ) external override onlyGovernance {
        require(
            _vault.length == _multiplier.length &&
                _vault.length == _rewardType.length &&
                _vault.length == _rewardToken.length,
            "LNS"
        );

        uint256 blockNum = block.number;
        for (uint256 i = 0; i < _vault.length; i++) {
            require(
                _vault[i] != address(0) &&
                    _rewardToken[i] != address(0) &&
                    _multiplier[i] > 0,
                "IV"
            );
            require(
                IERC20(_rewardToken[i]).balanceOf(address(this)) > 0,
                "NEB"
            );

            VaultInfo storage vaultState = vaultInfo[_vault[i]];
            AltInfo storage vaultAltState = vaultAltInfo[_vault[i]];

            if (!vaultWhitelist[_vault[i]] && vaultState.totalLpLocked == 0) {
                if (
                    _rewardType[i] == RewardType.Alt ||
                    _rewardType[i] == RewardType.Dual
                ) {
                    vaultAltState.multiplier = _multiplier[i];
                    vaultAltState.startBlock = blockNum;
                    vaultAltState.lastRewardBlock = blockNum;
                    vaultAltState.rewardToken = _rewardToken[i];
                }
                insertVault(_vault[i], _multiplier[i], _rewardType[i]);
                emit Vault(
                    _vault[i],
                    rewardPerBlock,
                    _multiplier[i],
                    blockNum,
                    _rewardType[i],
                    _rewardToken[i]
                );
            } else {
                require(!vaultWhitelist[_vault[i]], "AI");
                if (vaultState.reward == RewardType.Dual) {
                    vaultState.lastRewardBlock = blockNum;
                    vaultAltState.lastRewardBlock = blockNum;
                    vaultAltState.multiplier = _multiplier[i];
                    vaultState.multiplier = _multiplier[i];
                } else if (vaultState.reward == RewardType.Alt) {
                    vaultAltState.lastRewardBlock = blockNum;
                    vaultAltState.multiplier = _multiplier[i];
                } else {
                    vaultState.lastRewardBlock = blockNum;
                    vaultState.multiplier = _multiplier[i];
                }
            }
            vaultWhitelist[_vault[i]] = true;
            emit VaultWhitelistStatus(_vault[i], true);
        }
    }

    /// @notice Deposit your lp for the specified vaults in the Unipilot farm
    /// @param _vault vault address on which you want to farm
    /// @param _amount the amount of tokens you want to deposit
    function stakeLp(address _vault, uint256 _amount)
        external
        override
        nonReentrant
    {
        require(_vault != address(0) && _amount > 0, "IV");
        require(farmingGrowthBlockLimit == 0, "LA");
        require(vaultWhitelist[_vault], "TNL");
        address caller = msg.sender;
        require(IERC20(_vault).balanceOf(caller) >= _amount, "NEB");
        uint256 blockNum = block.number;
        bool flag;
        VaultInfo storage vaultState = vaultInfo[_vault];
        AltInfo storage vaultAltState = vaultAltInfo[_vault];
        UserInfo storage userState = userInfo[_vault][caller];

        (uint256 reward, uint256 altReward, , ) = currentReward(_vault, caller);
        if (reward > 0 || altReward > 0) {
            claimReward(_vault);
            flag = true;
        }
        if (!flag) {
            if (vaultState.lastRewardBlock != vaultState.startBlock) {
                uint256 blockDiff = blockNum.sub(vaultState.lastRewardBlock);
                vaultState.globalReward = getGlobalReward(
                    _vault,
                    blockDiff,
                    vaultState.multiplier,
                    vaultState.globalReward,
                    0
                );
            }
        }

        if (
            vaultState.reward == RewardType.Dual ||
            vaultState.reward == RewardType.Alt
        ) {
            updateAltState(_vault);
            vaultAltState.lastRewardBlock = blockNum;
        }

        vaultState.totalLpLocked = vaultState.totalLpLocked.add(_amount);

        userInfo[_vault][caller] = UserInfo({
            reward: vaultState.globalReward,
            altReward: vaultAltState.globalReward,
            lpLiquidity: userState.lpLiquidity.add(_amount),
            vault: _vault
        });

        IERC20(vaultState.stakingToken).safeTransferFrom(
            caller,
            address(this),
            _amount
        );

        if (
            vaultState.reward == RewardType.Dual ||
            vaultState.reward == RewardType.Pilot
        ) {
            vaultState.lastRewardBlock = blockNum;
        }
        emit Deposit(caller, _vault, _amount, vaultState.totalLpLocked);
    }

    /// @notice Withdraw your lp as well as the accumulated reward if
    /// any from the farm.
    /// @param _vault vault where to earn reward
    /// @param _amount the amount of tokens want to withdraw
    function unstakeLp(address _vault, uint256 _amount)
        external
        override
        nonReentrant
    {
        require(_vault != address(0) && _amount > 0, "IA");
        address caller = msg.sender;
        VaultInfo storage vaultState = vaultInfo[_vault];
        UserInfo storage userState = userInfo[_vault][caller];
        require(
            userState.lpLiquidity >= _amount &&
                vaultState.totalLpLocked >= _amount,
            "AGTL"
        );

        claimReward(_vault);

        vaultState.totalLpLocked = vaultState.totalLpLocked.sub(_amount);
        userState.lpLiquidity = userState.lpLiquidity.sub(_amount);

        IERC20(_vault).safeTransfer(caller, _amount);

        emit Withdraw(caller, _vault, _amount);

        if (vaultState.totalLpLocked == 0) {
            if (vaultState.reward == RewardType.Dual) {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;

                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else if (vaultState.reward == RewardType.Alt) {
                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;
            }
        }

        if (userState.lpLiquidity == 0) {
            delete userInfo[_vault][caller];
        }
    }

    /// @notice Withdraw your accumulated rewards without withdrawing lp.
    /// @param _vault vault address from which you intend to claim the
    /// accumulated reward from
    /// @return reward of pilot for a particular user that was accumulated
    /// @return altReward of altToken for a particular user that was accumulated
    /// @return gr global reward
    /// @return altGr alt global reward
    function claimReward(address _vault)
        public
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        )
    {
        require(_vault != address(0), "ZA");
        address caller = msg.sender;
        uint256 blocknum = block.number;
        VaultInfo storage vaultState = vaultInfo[_vault];
        AltInfo storage vaultAltState = vaultAltInfo[_vault];
        UserInfo storage userState = userInfo[_vault][caller];

        (reward, altReward, gr, altGr) = currentReward(_vault, caller);

        require(reward > 0 || altReward > 0, "RZ");
        if (vaultState.reward == RewardType.Dual) {
            if (altReward > 0) {
                userState.altReward = altGr;
                vaultAltState.globalReward = altGr;
                vaultAltState.lastRewardBlock = blocknum;
            }
            if (reward > 0) {
                userState.reward = gr;
                vaultState.globalReward = gr;
                vaultState.lastRewardBlock = blocknum;
            }
        } else if (vaultState.reward == RewardType.Alt) {
            if (altReward > 0) {
                userState.altReward = altGr;
                vaultAltState.globalReward = altGr;
                vaultAltState.lastRewardBlock = blocknum;
            }
            if (reward > 0) {
                userState.reward = vaultState.globalReward;
            }
        } else {
            if (reward > 0) {
                userState.reward = gr;
                vaultState.globalReward = gr;
                vaultState.lastRewardBlock = blocknum;
            }

            if (altReward > 0) {
                userState.altReward = vaultAltState.globalReward;
            }
        }
        if (altReward > 0) {
            emit Reward(vaultAltState.rewardToken, caller, _vault, altReward);
            IERC20(vaultAltState.rewardToken).safeTransfer(caller, altReward);
        }
        if (reward > 0) {
            emit Reward(pilot, caller, _vault, reward);
            IERC20(pilot).safeTransfer(caller, reward);
        }
    }

    /// @notice Blacklist the vaults which are already whitelisted.
    /// No famring allowed on blacklisted vaults
    /// @dev only called by governance
    /// @param _vaults list of vaults
    function blacklistVaults(address[] calldata _vaults)
        external
        override
        onlyGovernance
    {
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (vaultInfo[_vaults[i]].reward == RewardType.Dual) {
                updateVaultState(_vaults[i]);
                updateAltState(_vaults[i]);
            } else if (vaultInfo[_vaults[i]].reward == RewardType.Alt) {
                updateAltState(_vaults[i]);
            } else {
                updateVaultState(_vaults[i]);
            }
            vaultWhitelist[_vaults[i]] = false;
            emit VaultWhitelistStatus(_vaults[i], false);
        }
    }

    /// @notice update the reward per block of the vaults
    /// @dev only called by governance
    /// @param _value of the reward to be set
    function updateRewardPerBlock(uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_value > 0, "IV");
        address[] memory vaults = vaultListed();
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaultWhitelist[vaults[i]]) {
                if (vaultInfo[vaults[i]].totalLpLocked != 0) {
                    if (vaultInfo[vaults[i]].reward == RewardType.Dual) {
                        updateVaultState(vaults[i]);
                        updateAltState(vaults[i]);
                    } else if (vaultInfo[vaults[i]].reward == RewardType.Alt) {
                        updateAltState(vaults[i]);
                    } else {
                        updateVaultState(vaults[i]);
                    }
                }
            }
        }
        emit RewardPerBlock(rewardPerBlock, rewardPerBlock = _value);
    }

    /// @notice update multiplier of a particular vault
    /// @dev only called by governance
    /// @param _vault vault address for which you want to update multiplier
    /// @param _value value of multiplier
    function updateMultiplier(address _vault, uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_vault != address(0) && _value > 0, "IV");
        require(
            vaultInfo[_vault].reward == RewardType.Pilot ||
                vaultInfo[_vault].reward == RewardType.Dual,
            "WM"
        );
        updateVaultState(_vault);
        emit Multiplier(
            _vault,
            pilot,
            vaultInfo[_vault].multiplier,
            vaultInfo[_vault].multiplier = _value
        );
    }

    /// @notice update alt multiplier of a particular vault
    /// @dev only called by governance
    /// @param _vault vault address for which you want to update multiplier
    /// @param _value value of multiplier
    function updateAltMultiplier(address _vault, uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_vault != address(0) && _value > 0, "IV");
        require(
            vaultInfo[_vault].reward == RewardType.Alt ||
                vaultInfo[_vault].reward == RewardType.Dual,
            "WM"
        );
        updateAltState(_vault);
        emit Multiplier(
            _vault,
            vaultAltInfo[_vault].rewardToken,
            vaultAltInfo[_vault].multiplier,
            vaultAltInfo[_vault].multiplier = _value
        );
    }

    /// @notice update governance to a new address
    /// @dev only called by governance
    /// @param _newGovernance new address of governance
    function updateGovernance(address _newGovernance)
        external
        override
        onlyGovernance
    {
        require(_newGovernance != address(0), "IA");

        emit GovernanceUpdated(governance, governance = _newGovernance);
    }

    /// @notice loops through the vaults mapping and returns a formulated array of vaults
    /// @dev only called by governance
    function vaultListed() public view returns (address[] memory) {
        uint256 vaultsLength = totalVaults;
        require(vaultsLength > 0, "NPE");
        address[] memory vaultList = new address[](vaultsLength);
        for (uint256 i = 0; i < vaultsLength; i++) {
            vaultList[i] = vaults[i + 1];
        }
        return vaultList;
    }

    /// @notice update reward type of the vault to either PILOT | ALT | DUAL
    /// @dev only called by governance
    /// @param _vault vault address for which you want to update reward type
    /// @param _rewardType type to which you want to change the reward to
    /// @param _altToken token address in which you want to give alt rewards
    function updateRewardType(
        address _vault,
        RewardType _rewardType,
        address _altToken
    ) external override onlyGovernance {
        require(_vault != address(0) && _altToken != address(0), "NAZ");
        AltInfo storage altState = vaultAltInfo[_vault];
        VaultInfo storage vaultState = vaultInfo[_vault];
        uint256 blockNumber = block.number;

        if (RewardType.Alt == _rewardType || RewardType.Dual == _rewardType) {
            require(IERC20(_altToken).balanceOf(address(this)) > 0, "NEB");
            altState.rewardToken = _altToken;
        }

        if (vaultInfo[_vault].reward == RewardType.Alt) {
            vaultState.lastRewardBlock = blockNumber;
            if (_rewardType == RewardType.Pilot) {
                altState.startBlock = blockNumber;
                updateAltState(_vault);
            }
        } else if (vaultInfo[_vault].reward == RewardType.Dual) {
            if (_rewardType == RewardType.Alt) {
                if (vaultState.totalLpLocked > 0) {
                    vaultState.startBlock = blockNumber;
                }
                updateVaultState(_vault);
            } else {
                altState.startBlock = blockNumber;
                updateAltState(_vault);
            }
        } else {
            altState.lastRewardBlock = blockNumber;
            if (_rewardType == RewardType.Alt) {
                if (vaultState.totalLpLocked > 0) {
                    vaultState.startBlock = blockNumber;
                }
                updateVaultState(_vault);
            }
        }
        emit RewardStatus(
            _vault,
            vaultInfo[_vault].reward,
            vaultInfo[_vault].reward = _rewardType,
            _altToken
        );
    }

    /// @notice Migrate funds to Governance address or in new Contract
    /// @dev only governance can call this
    /// @param _receiver address of new contract or wallet address
    /// @param _tokenAddress address of token which want to migrate
    /// @param _amount withdraw that amount which are required
    function migrateFunds(
        address _receiver,
        address _tokenAddress,
        uint256 _amount
    ) external override onlyGovernance {
        require(_receiver != address(0) && _tokenAddress != address(0), "NAZ");
        require(_amount > 0, "IV");
        IERC20(_tokenAddress).safeTransfer(_receiver, _amount);
        emit MigrateFunds(_receiver, _tokenAddress, _amount);
    }

    /// @notice Used to stop staking Lps in contract after block limit
    function updateFarmingLimit(uint256 _blockNumber)
        external
        override
        onlyGovernance
    {
        require(_blockNumber == 0 || _blockNumber > block.number, "BSG");
        emit UpdateFarmingLimit(
            farmingGrowthBlockLimit,
            farmingGrowthBlockLimit = _blockNumber
        );
        updateLastBlock(_blockNumber);
    }

    /// @notice Withdraw your lp
    /// @param _vault vault from where lp's will be unstaked without reward
    function emergencyUnstakeLp(address _vault) external override nonReentrant {
        require(_vault != address(0), "IA");
        address caller = msg.sender;
        VaultInfo storage vaultState = vaultInfo[_vault];
        UserInfo memory userState = userInfo[_vault][caller];
        require(
            userState.lpLiquidity > 0 && vaultState.totalLpLocked > 0,
            "AGTL"
        );
        IERC20(_vault).safeTransfer(caller, userState.lpLiquidity);
        vaultState.totalLpLocked = vaultState.totalLpLocked.sub(
            userState.lpLiquidity
        );
        if (vaultState.totalLpLocked == 0) {
            if (vaultState.reward == RewardType.Dual) {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;

                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else if (vaultState.reward == RewardType.Alt) {
                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;
            }
        }
        delete userInfo[_vault][caller];
    }

    ///@notice use to fetch reward of particular user in a vault
    ///@param _vault address of vault to query for
    ///@param _user address of user to query for
    function currentReward(address _vault, address _user)
        public
        view
        override
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        )
    {
        //gas optimisation using store for 1 SLOAD rather then n number
        //of SLOADS per each struct value count
        VaultInfo storage vaultState = vaultInfo[_vault];
        UserInfo storage userState = userInfo[_vault][_user];

        if (vaultState.reward == RewardType.Dual) {
            gr = verifyLimit(_vault, Direction.Pilot);
            reward = gr.sub(userState.reward);
            reward = FullMath.mulDiv(reward, userState.lpLiquidity, 1e18);
            altGr = verifyLimit(_vault, Direction.Alt);
            altReward = altGr.sub(userState.altReward);
            altReward = FullMath.mulDiv(altReward, userState.lpLiquidity, 1e18);
        } else if (vaultState.reward == RewardType.Alt) {
            altGr = verifyLimit(_vault, Direction.Alt);
            altReward = altGr.sub(userState.altReward);
            altReward = FullMath.mulDiv(altReward, userState.lpLiquidity, 1e18);

            if (userState.reward < vaultState.globalReward) {
                reward = vaultState.globalReward.sub(userState.reward);
                reward = FullMath.mulDiv(reward, userState.lpLiquidity, 1e18);
            }
        } else {
            gr = verifyLimit(_vault, Direction.Pilot);
            reward = gr.sub(userState.reward);
            reward = FullMath.mulDiv(reward, userState.lpLiquidity, 1e18);

            if (userState.altReward < vaultAltInfo[_vault].globalReward) {
                AltInfo memory vaultAltState = vaultAltInfo[_vault];
                altReward = vaultAltState.globalReward.sub(userState.altReward);
                altReward = FullMath.mulDiv(
                    altReward,
                    userState.lpLiquidity,
                    1e18
                );
            }
        }
    }

    /// @notice update PoolInfo and AltInfo global rewards and lastRewardBlock
    /// @dev only called by governance
    function updateLastBlock(uint256 _blockNumber) private {
        address[] memory vaults = vaultListed();
        for (uint256 i = 0; i < totalVaults; i++) {
            if (vaultInfo[vaults[i]].reward == RewardType.Dual) {
                if (_blockNumber > 0) {
                    updateVaultState(vaults[i]);
                    updateAltState(vaults[i]);
                } else {
                    vaultInfo[vaults[i]].lastRewardBlock = block.number;
                    vaultAltInfo[vaults[i]].lastRewardBlock = block.number;
                }
            } else if (vaultInfo[vaults[i]].reward == RewardType.Alt) {
                if (_blockNumber > 0) {
                    updateAltState(vaults[i]);
                } else {
                    vaultAltInfo[vaults[i]].lastRewardBlock = block.number;
                }
            } else {
                if (_blockNumber > 0) {
                    updateVaultState(vaults[i]);
                } else {
                    vaultInfo[vaults[i]].lastRewardBlock = block.number;
                }
            }
        }
    }

    ///@notice use for reading global reward of Unipilot farm
    ///@param _vault address of vault
    ///@param _blockDiff difference of the blocks for which you want the global reward
    ///@param _multiplier multiplier of the vaults
    ///@param _lastGlobalReward last global reward that was calculated
    function getGlobalReward(
        address _vault,
        uint256 _blockDiff,
        uint256 _multiplier,
        uint256 _lastGlobalReward,
        uint24 _direction
    ) private view returns (uint256 _globalReward) {
        _globalReward = _direction == 0
            ? vaultInfo[_vault].globalReward
            : vaultAltInfo[_vault].globalReward;

        if (vaultWhitelist[_vault]) {
            if (vaultInfo[_vault].totalLpLocked > 0) {
                _globalReward = FullMath.mulDiv(
                    rewardPerBlock,
                    _multiplier,
                    1e18
                );

                _globalReward = FullMath
                    .mulDiv(
                        _blockDiff.mul(_globalReward),
                        1e18,
                        vaultInfo[_vault].totalLpLocked
                    )
                    .add(_lastGlobalReward);
            }
        }
    }

    ///@notice used to update vault states, call where required
    ///@param _vault address of the vault for which you want to update the state
    function updateVaultState(address _vault) private {
        VaultInfo storage vaultState = vaultInfo[_vault];
        if (vaultState.totalLpLocked > 0) {
            uint256 blockDiff = (block.number).sub(vaultState.lastRewardBlock);
            vaultState.globalReward = getGlobalReward(
                _vault,
                blockDiff,
                vaultState.multiplier,
                vaultState.globalReward,
                0
            );
            vaultState.lastRewardBlock = block.number;
        }
    }

    ///@notice update vault alt states, call where required
    ///@param _vault address of the vault for which you want to update the state
    function updateAltState(address _vault) private {
        AltInfo storage altState = vaultAltInfo[_vault];

        if (altState.lastRewardBlock != altState.startBlock) {
            uint256 blockDiff = (block.number).sub(altState.lastRewardBlock);
            altState.globalReward = getGlobalReward(
                _vault,
                blockDiff,
                altState.multiplier,
                altState.globalReward,
                1
            );
            altState.lastRewardBlock = block.number;
        }
    }

    ///@notice Add vault in Unipilot Farm called inside initializer
    ///@param _vault address of vault to add
    ///@param _multiplier value of multiplier to set for particular vault
    function insertVault(
        address _vault,
        uint256 _multiplier,
        RewardType _rewardType
    ) private {
        if (vaultInfo[_vault].startBlock == 0) {
            totalVaults++;
        }
        vaults[totalVaults] = _vault;
        vaultInfo[_vault] = VaultInfo({
            startBlock: block.number,
            globalReward: 0,
            lastRewardBlock: block.number,
            totalLpLocked: 0,
            multiplier: _multiplier,
            stakingToken: _vault,
            reward: _rewardType
        });
    }

    ///@notice check the limit to see if the farmingGrowthBlockLimit was crossed or not
    ///@param _vault address of vault
    ///@param _check enum value to check whether we want to verify Limit for Pilot or Alt
    function verifyLimit(address _vault, Direction _check)
        private
        view
        returns (uint256 globalReward)
    {
        Cache memory state;

        if (_check == Direction.Pilot) {
            VaultInfo storage vaultState = vaultInfo[_vault];
            state = Cache({
                globalReward: vaultState.globalReward,
                lastRewardBlock: vaultState.lastRewardBlock,
                multiplier: vaultState.multiplier,
                direction: 0
            });
        } else if (_check == Direction.Alt) {
            AltInfo storage vaultAltInfo = vaultAltInfo[_vault];
            state = Cache({
                globalReward: vaultAltInfo.globalReward,
                lastRewardBlock: vaultAltInfo.lastRewardBlock,
                multiplier: vaultAltInfo.multiplier,
                direction: 1
            });
        }

        if (
            state.lastRewardBlock < farmingGrowthBlockLimit &&
            block.number >= farmingGrowthBlockLimit
        ) {
            globalReward = getGlobalReward(
                _vault,
                farmingGrowthBlockLimit.sub(state.lastRewardBlock),
                state.multiplier,
                state.globalReward,
                state.direction
            );
        } else if (
            state.lastRewardBlock > farmingGrowthBlockLimit &&
            farmingGrowthBlockLimit > 0
        ) {
            globalReward = state.globalReward;
        } else {
            uint256 blockDifference = (block.number).sub(state.lastRewardBlock);
            globalReward = getGlobalReward(
                _vault,
                blockDifference,
                state.multiplier,
                state.globalReward,
                state.direction
            );
        }
    }
}
