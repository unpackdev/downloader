// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Errors.sol";
import "./TransferHelper.sol";
import "./SettingStorage.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IERC20Burnable.sol";
import "./IWETH.sol";
import "./ISettings.sol";
import "./IVault.sol";
import "./IStaking.sol";
import "./IExchange.sol";
import "./IGovernor.sol";
import "./Strings.sol";
import "./DataTypes.sol";

contract TokenVaultTreasury is SettingStorage, OwnableUpgradeable {
    //
    IERC20[] public rewardTokens;
    mapping(IERC20 => bool) public isRewardToken;
    mapping(IERC20 => uint256) public poolBalances;

    address public vaultToken;

    uint256 public createdAt;
    uint256 public epochTotal;
    uint256 public epochNum;
    uint256 public epochDuration;

    bool public isEnded;

    bool public stakingPoolEnabled;
    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

    event Shared(
        IERC20 _token,
        uint256 poolSharedAmt,
        uint256 incomeSharedAmt,
        uint256 incomePoolAmt
    );
    event End(uint256 epochNumber);

    constructor(address _settings) SettingStorage(_settings) {}

    function initialize(
        address _vaultToken,
        uint256 _epochDuration,
        uint256 _epochTotal
    ) public initializer {
        __Ownable_init();
        // init data
        require(_vaultToken != address(0), "no zero address");
        vaultToken = _vaultToken;
        createdAt = block.timestamp;
        epochDuration = _epochDuration;
        epochNum = 0;
        epochTotal = epochNum + _epochTotal;
    }

    modifier onlyGovernor() {
        require(
            address(_getGovernor()) == _msgSender(),
            Errors.VAULT_NOT_GOVERNOR
        );
        _;
    }

    function stakingInitialize(uint256 _epochTotal) external onlyOwner {
        require(!stakingPoolEnabled, Errors.VAULT_TREASURY_STAKING_ENABLED);
        require(
            epochNum < epochTotal || _epochTotal > 0,
            Errors.VAULT_TREASURY_EPOCH_INVALID
        );
        epochNum = _getEpochNumer();
        if (epochTotal == 0 || epochNum >= epochTotal) {
            epochTotal = epochNum + _epochTotal;
        }
        // flag enble staking
        stakingPoolEnabled = true;
    }

    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function addRewardToken(address _addr) external onlyOwner {
        IERC20 _rewardToken = IERC20(_addr);
        require(
            !isRewardToken[_rewardToken] && address(_rewardToken) != address(0),
            Errors.VAULT_REWARD_TOKEN_INVALID
        );
        require(rewardTokens.length < 25, Errors.VAULT_REWARD_TOKEN_INVALID);
        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;
        poolBalances[_rewardToken] = 0;
    }

    modifier validRewardToken(IERC20 _rewardToken) {
        require(isRewardToken[_rewardToken], Errors.VAULT_REWARD_TOKEN_INVALID);
        _;
    }

    function _getEpochNumer() private view returns (uint256) {
        return (block.timestamp - createdAt) / epochDuration;
    }

    function _isStaking() private view returns (bool) {
        return stakingPoolEnabled;
    }

    /**
     * get realtime treasury balance base on current epoch
     */
    function getPoolBalanceToken(IERC20 _token)
        public
        view
        validRewardToken(_token)
        returns (uint256)
    {
        uint256 poolBalance;
        uint256 _epochNum = _getEpochNumer();
        (poolBalance, ) = getPoolSharedToken(_token, _epochNum);
        return poolBalance;
    }

    function getBalanceVeToken() public view returns (uint256) {
        return _getStaking().balanceOf(address(this));
    }

    /**
     * get realtime treasury balance and share balance (balane will be share to staking contract) base on current epoch
     */
    function getPoolSharedToken(IERC20 _token, uint256 _epochNow)
        internal
        view
        returns (uint256 poolBalance, uint256 poolSharedAmt)
    {
        poolBalance = poolBalances[_token];
        if (_isStaking()) {
            if (poolBalance > 0) {
                if (_epochNow > epochTotal) {
                    poolSharedAmt = poolBalance;
                } else {
                    if (_epochNow > epochNum) {
                        poolSharedAmt =
                            (poolBalance * (_epochNow - epochNum)) /
                            (epochTotal - epochNum);
                    }
                }
                poolBalance -= poolSharedAmt;
            }
        } else {
            poolBalance = (_token.balanceOf(address(this)) +
                IExchange(IVault(vaultToken).exchange())
                    .getNewShareExchangeFeeRewardToken(address(_token)));
        }
        return (poolBalance, poolSharedAmt);
    }

    /**
     * get realtime income balance, this balance is income for trading fee, 70% will be shrare to admin, 30% will be share staking, if not staking will store treasury balance
     */
    function getIncomeSharedToken(IERC20 _token, bool _exchange)
        internal
        view
        returns (uint256 incomeSharedAmt, uint256 incomePoolAmt)
    {
        uint256 _tokenBalance = _token.balanceOf(address(this));
        if (_exchange) {
            _tokenBalance += IExchange(IVault(vaultToken).exchange())
                .getNewShareExchangeFeeRewardToken(address(_token));
        }
        if (_tokenBalance > 0) {
            uint256 poolBalance = poolBalances[_token];
            if (_tokenBalance > poolBalance) {
                uint256 incomeBalance = (_tokenBalance - poolBalance);
                if (_isStaking()) {
                    incomeSharedAmt = incomeBalance;
                } else {
                    incomePoolAmt = incomeBalance;
                }
            }
        }
        return (incomeSharedAmt, incomePoolAmt);
    }

    /**
     * get realtime for pool balance and imcome balance
     */
    function getNewSharedToken(IERC20 _token)
        external
        view
        returns (
            uint256 poolSharedAmt,
            uint256 incomeSharedAmt,
            uint256 incomePoolAmt
        )
    {
        uint256 _epochNum = _getEpochNumer();
        return _getNewSharedToken(_token, _epochNum, true);
    }

    /**
     * get realtime for pool balance and imcome balance
     */
    function _getNewSharedToken(
        IERC20 _token,
        uint256 _epochNum,
        bool _exchange
    )
        internal
        view
        returns (
            uint256 poolSharedAmt,
            uint256 incomeSharedAmt,
            uint256 incomePoolAmt
        )
    {
        {
            uint256 _poolSharedAmt;
            (, _poolSharedAmt) = getPoolSharedToken(_token, _epochNum);
            poolSharedAmt = _poolSharedAmt;
        }
        {
            uint256 _incomeSharedAmt;
            uint256 _incomePoolAmt;
            (_incomeSharedAmt, _incomePoolAmt) = getIncomeSharedToken(
                _token,
                _exchange
            );
            incomeSharedAmt = _incomeSharedAmt;
            incomePoolAmt = _incomePoolAmt;
        }
        return (poolSharedAmt, incomeSharedAmt, incomePoolAmt);
    }

    /**
     * for staking contract call for get reward
     */
    function shareTreasuryRewardToken() external {
        _shareTreasuryRewardToken();
    }

    function _shareTreasuryRewardToken() internal {
        // exchange share
        IExchange(IVault(vaultToken).exchange()).shareExchangeFeeRewardToken();
        //
        uint256 _epochNum = _getEpochNumer();
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];
            uint256 poolSharedAmt;
            uint256 incomeSharedAmt;
            uint256 incomePoolAmt;
            (
                poolSharedAmt,
                incomeSharedAmt,
                incomePoolAmt
            ) = _getNewSharedToken(_token, _epochNum, false);
            if (poolSharedAmt > 0) {
                TransferHelper.safeTransfer(
                    _token,
                    IVault(vaultToken).staking(),
                    poolSharedAmt
                );
                poolBalances[_token] -= poolSharedAmt;
            }
            if (incomeSharedAmt > 0) {
                TransferHelper.safeTransfer(
                    _token,
                    IVault(vaultToken).staking(),
                    incomeSharedAmt
                );
            }
            if (incomePoolAmt > 0) {
                poolBalances[_token] += incomePoolAmt;
            }
            emit Shared(_token, poolSharedAmt, incomeSharedAmt, incomePoolAmt);
        }
        epochNum = _epochNum;
    }

    /**
     * for vault contract call start aution or redeem, share lastest reward, and burn treasury balance, transfer weth to vault address
     */
    function end() external onlyOwner {
        require(!isEnded, "no end");
        // share reward
        _shareTreasuryRewardToken();
        // withdraw and burn token
        IStaking _staking = _getStaking();
        IVault _vault = _getVault();
        uint256 stkBalance = _staking.balanceOf(address(this));
        if (stkBalance > 0) {
            _staking.redeemFToken(stkBalance);
        }
        _vault.burn(_vault.balanceOf(address(this)));
        // transfer reward to vault
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];
            uint256 _balane = _token.balanceOf(address(this));
            if (_balane > 0) {
                TransferHelper.safeTransfer(
                    _token,
                    address(vaultToken),
                    _balane
                );
            }
            poolBalances[_token] = 0;
        }
        // update end
        isEnded = true;
        emit End(epochNum);
    }

    function _getVault() internal view returns (IVault) {
        return IVault(vaultToken);
    }

    function _getStaking() internal view returns (IStaking) {
        return IStaking(_getVault().staking());
    }

    function _getGovernor() internal view returns (IGovernor) {
        return IGovernor(_getVault().government());
    }

    function initializeGovernorToken() external onlyOwner {
        IStaking _staking = _getStaking();
        IVault _vault = _getVault();
        if (_vault.nftGovernor() != address(0)) {
            require(_staking.balanceOf(address(this)) == 0, "bad balance");
            uint256 veBalance = ((_vault.totalSupply() *
                ISettings(settings).votingMinTokenPercent()) / 10000);
            _vault.approve(address(_staking), veBalance);
            _staking.convertFTokenToVeToken(veBalance);
            // delegate for goverment
            _getStaking().delegate(address(this));
        }
    }

    function createNftGovernorVoteFor(uint256 proposalId) external {
        require(_getVault().nftGovernor() != address(0), "bad nft governor");
        require(_getStaking().balanceOf(address(this)) > 0, "bad balance");
        // calldata for castVote
        bytes memory _castVotedata = abi.encodeWithSignature(
            "castVote(uint256,uint8)",
            proposalId,
            1
        );
        // calldata for proposalTargetCall
        bytes memory _targetCalldata = abi.encodeWithSignature(
            "proposalTargetCall(address,uint256,bytes)",
            _getVault().nftGovernor(),
            0,
            _castVotedata
        );
        // params for propose
        address[] memory targets = new address[](1);
        targets[0] = address(_getVault());
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = _targetCalldata;
        // governor propose
        _getGovernor().propose(
            targets,
            values,
            calldatas,
            string(
                abi.encodePacked(
                    "This Sub-DAO proposal was created to allow participants to vote For (Yes) on the original proposal #",
                    Strings.toString(proposalId)
                )
            )
        );
    }

    event ProposalERC20Spend(IERC20 token, address recipient, uint256 amount);

    function proposalERC20Spend(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external onlyGovernor {
        // share reward before spend
        _shareTreasuryRewardToken();
        // transfer
        TransferHelper.safeTransfer(_token, _recipient, _amount);
        // update pool balance after spend
        poolBalances[_token] = _token.balanceOf(address(this));
        // emit event
        emit ProposalERC20Spend(_token, _recipient, _amount);
    }
}
