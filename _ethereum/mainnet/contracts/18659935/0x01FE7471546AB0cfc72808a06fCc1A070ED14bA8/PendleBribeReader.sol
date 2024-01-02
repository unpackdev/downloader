// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IMasterPenpieReader.sol";
import "./IPendleStakingReader.sol";
import "./IPenpieBribeManagerReader.sol";
import "./IPendleVoteManagerReader.sol";
import "./IPendleVotingControllerUpgReader.sol";
import "./IPVeToken.sol";

/// @title PendleBribeReader
/// @author Magpie Team

contract PendleBribeReader is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct ERC20TokenInfo {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }

    struct VePendleBribeInfo {
        uint256 currentEpochEndTime;
        uint256 userTotalVePendle;
        uint64 userTotalVoted;
        uint64 userVotable;
        uint256 totalVePendle;
        uint256 exactCurrentEpoch;
        ApprovedToken[] approvedTokens;
        VePendleBribePool[] pools;
    }

    struct ApprovedToken {
        address token;
        ERC20TokenInfo tokenInfo;
        uint256 balanceOf;
        uint256 addBribeAllowance;
    }

    struct BribePool {
        uint256 poolId;
        uint256 totalVoteInVlPenpie;
        uint256 userVotedForPoolInVlPenpie;
        address market;
        bool isActive;
        uint256 chainId;
        Bribe[] previousBribes;
        Bribe[] currentBribes;
    }

    //pool.market, pool.chainId, pool.userVoted, pool.poolId, pool.isActive, pool.previousBribes, pool.currentBribes
    struct VePendleBribePool {
        uint256 poolId;
        uint256 userVoted;
        address market;
        bool isActive;
        uint256 chainId;
        Bribe[] previousBribes;
        Bribe[] currentBribes;
    }

    struct Bribe {
        address token;
        ERC20TokenInfo tokenInfo;
        uint256 amount;
    }

    /* ============ State Variables ============ */

    IPenpieBribeManagerReader public penpieBribeManager;
    IPendleStakingReader public pendleStaking;
    IPendleVoteManagerReader public penpieVoteManager;
    IPendleVotingControllerUpgReader public pendleVotingControllerUpgReader;

    /* ============ Events ============ */

    /* ============ Errors ============ */

    /* ============ Constructor ============ */

    function __PenpieReader_init(
        IPenpieBribeManagerReader _penpieBribeManager,
        IPendleStakingReader _pendleStaking,
        IPendleVoteManagerReader _penpieVoteManager,
        IPendleVotingControllerUpgReader _pendleVotingControllerUpgReader
    ) public initializer {
        __Ownable_init();
        penpieBribeManager = _penpieBribeManager;
        pendleStaking = _pendleStaking;
        penpieVoteManager = _penpieVoteManager;
        pendleVotingControllerUpgReader = _pendleVotingControllerUpgReader;
    }

    /* ============ External Getters ============ */

    function getERC20TokenInfo(address token) public view returns (ERC20TokenInfo memory) {
        ERC20TokenInfo memory tokenInfo;
        tokenInfo.tokenAddress = token;
        if (token == address(1)) {
            tokenInfo.symbol = "ETH";
            tokenInfo.decimals = 18;
            return tokenInfo;
        }
        ERC20 tokenContract = ERC20(token);
        tokenInfo.symbol = tokenContract.symbol();
        tokenInfo.decimals = tokenContract.decimals();
        return tokenInfo;
    }

    function getVePendleBribeInfo(address account) public view returns (VePendleBribeInfo memory) {
        VePendleBribeInfo memory info;
        info.currentEpochEndTime = penpieBribeManager.getCurrentEpochEndTime();
        info.userTotalVoted = 0;
        info.userTotalVePendle = IPVeToken(pendleStaking.vePendle()).balanceOf(account);
        info.totalVePendle = IPVeToken(pendleStaking.vePendle()).totalSupplyStored();

        address[] memory approvedTokensAddress = penpieBribeManager.getApprovedTokens();
        ApprovedToken[] memory approvedTokens = new ApprovedToken[](approvedTokensAddress.length);
        for (uint256 i = 0; i < approvedTokensAddress.length; i++) {
            ApprovedToken memory approvedToken;
            approvedToken.token = approvedTokensAddress[i];
            approvedToken.tokenInfo = getERC20TokenInfo(approvedTokensAddress[i]);
            if (account != address(0)) {
                approvedToken.balanceOf = ERC20(approvedToken.token).balanceOf(account);
                approvedToken.addBribeAllowance = ERC20(approvedToken.token).allowance(
                    account,
                    address(penpieBribeManager)
                );
            }
            approvedTokens[i] = approvedToken;
        }
        info.approvedTokens = approvedTokens;

        uint256 poolCount = penpieVoteManager.getPoolsLength();
        VePendleBribePool[] memory pools = new VePendleBribePool[](poolCount);
        address[] memory marketList = new address[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
            pools[i] = getVePendleBribePoolInfo(i);
            marketList[i] = pools[i].market;
        }
        info.pools = pools;
        if (account != address(0) && address(pendleVotingControllerUpgReader) != address(0)) {
            IPendleVotingControllerUpgReader.UserPoolData[] memory userVoted;
            (info.userTotalVoted, userVoted) = pendleVotingControllerUpgReader.getUserData(
                account,
                marketList
            );
            for (uint256 i = 0; i < poolCount; ++i) {
                pools[i].userVoted = userVoted[i].weight;
            }
            info.userVotable = (info.userTotalVePendle > 0) ? 1e18 - info.userTotalVoted : 0;
        }
        uint256 exactCurrentEpoch = penpieBribeManager.exactCurrentEpoch();
        info.exactCurrentEpoch = exactCurrentEpoch;
        if (exactCurrentEpoch >= 0) {
            if (exactCurrentEpoch > 0) {
                _fillInVePendleBribeInAllPools(exactCurrentEpoch - 1, poolCount, pools, false);
            }

            _fillInVePendleBribeInAllPools(exactCurrentEpoch, poolCount, pools, true);
        }

        return info;
    }

    function getVePendleBribePoolInfo(
        uint256 poolId
    ) public view returns (VePendleBribePool memory) {
        VePendleBribePool memory bribePool;
        bribePool.poolId = poolId;
        (bribePool.market, , bribePool.chainId, bribePool.isActive) = penpieVoteManager.poolInfos(
            poolId
        );

        return bribePool;
    }

    /* ============ Internal Functions ============ */

    function _fillInVePendleBribeInAllPools(
        uint256 _epoch,
        uint256 _poolCount,
        VePendleBribePool[] memory _pools,
        bool _isCurrentEpoch
    ) internal view {
        IPenpieBribeManagerReader.IBribe[][] memory bribes = penpieBribeManager
            .getBribesInAllPoolsForVePendle(_epoch);

        for (uint256 i = 0; i < _poolCount; ++i) {
            uint256 size = bribes[i].length;
            Bribe[] memory poolBribe = new Bribe[](size);
            for (uint256 m = 0; m < size; ++m) {
                address token = bribes[i][m]._token;
                uint256 amount = bribes[i][m]._amount;
                Bribe memory temp;
                temp.token = token;
                temp.amount = amount;
                temp.tokenInfo = getERC20TokenInfo(token);
                poolBribe[m] = temp;
            }
            if (_isCurrentEpoch) _pools[i].currentBribes = poolBribe;
            else _pools[i].previousBribes = poolBribe;
        }
    }

    /* ============ Admin Functions ============ */

}
