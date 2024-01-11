// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./IERC1155.sol";
import "./ERC1155HolderUpgradeable.sol";

import "./INFTStaking.sol";
import "./IContractsRegistry.sol";
import "./IPolicyBookRegistry.sol";
import "./ILiquidityMiningStaking.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract NFTStaking is
    INFTStaking,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    AbstractDependant
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant PLATINUM_NFT_ID = 1;
    uint256 public constant GOLD_NFT_ID = 2;
    uint256 public constant SILVER_NFT_ID = 3;
    uint256 public constant BRONZE_NFT_ID = 4;

    uint256 public constant PLATINUM_NFT_DISCOUNT = 15 * PRECISION; // 0.15
    uint256 public constant GOLD_NFT_DISCOUNT = 10 * PRECISION; // 0.10
    uint256 public constant SILVER_NFT_BOOST = 20 * PRECISION; // 0.20
    uint256 public constant BRONZE_NFT_BOOST = 10 * PRECISION; // 0.10

    IPolicyBookRegistry public policyBookRegistry;
    ILiquidityMiningStaking public liquidityMiningStakingETH;
    ILiquidityMiningStaking public liquidityMiningStakingUSDT;
    IERC1155 public bmiUtilityNFT;

    bool public override enabledlockingNFTs;

    mapping(address => EnumerableSet.UintSet) internal _nftStakerTokens; // staker -> nfts

    bool isETHMainnet;

    event Locked(address _userAddr, uint256 _nftId);

    event Unlocked(address _userAddr, uint256 _nftId);

    modifier onlyPolicyBooks() {
        require(policyBookRegistry.isPolicyBook(_msgSender()), "NFTS: No access");
        _;
    }

    function __NFTStaking_init() external initializer {
        __Ownable_init();
        isETHMainnet = true;
        enabledlockingNFTs = true;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        if (isETHMainnet) {
            liquidityMiningStakingETH = ILiquidityMiningStaking(
                _contractsRegistry.getLiquidityMiningStakingETHContract()
            );
            // liquidityMiningStakingUSDT = ILiquidityMiningStaking(
            //     _contractsRegistry.getLiquidityMiningStakingUSDTContract()
            // );
        }
        bmiUtilityNFT = IERC1155(_contractsRegistry.getBMIUtilityNFTContract());
    }

    function lockNFT(uint256 _nftId) external override {
        require(!_nftStakerTokens[_msgSender()].contains(_nftId), "NFTS: Same NFT");

        bmiUtilityNFT.safeTransferFrom(_msgSender(), address(this), _nftId, 1, "");

        _nftStakerTokens[_msgSender()].add(_nftId);

        if (isETHMainnet) {
            if (_nftId == SILVER_NFT_ID || _nftId == BRONZE_NFT_ID) {
                _setLMStakingRewardMultiplier();
            }
        }

        emit Locked(_msgSender(), _nftId);
    }

    function unlockNFT(uint256 _nftId) external override {
        require(_nftStakerTokens[_msgSender()].contains(_nftId), "NFTS: No NFT locked");

        require(!enabledlockingNFTs, "NFTS: Not allowed");

        bmiUtilityNFT.safeTransferFrom(address(this), _msgSender(), _nftId, 1, "");

        _nftStakerTokens[_msgSender()].remove(_nftId);

        if (isETHMainnet) {
            if (_nftId == SILVER_NFT_ID || _nftId == BRONZE_NFT_ID) {
                _setLMStakingRewardMultiplier();
            }
        }

        emit Unlocked(_msgSender(), _nftId);
    }

    function getUserReductionMultiplier(address user)
        external
        view
        override
        onlyPolicyBooks
        returns (uint256)
    {
        uint256 _multiplier;

        if (_nftStakerTokens[user].contains(PLATINUM_NFT_ID)) {
            _multiplier = PLATINUM_NFT_DISCOUNT;
        } else if (_nftStakerTokens[user].contains(GOLD_NFT_ID)) {
            _multiplier = GOLD_NFT_DISCOUNT;
        }
        return _multiplier;
    }

    // @TODO: we should let DAO to enable/disable locking of the NFTs
    function enableLockingNFTs(bool _enabledlockingNFTs) external override onlyOwner {
        enabledlockingNFTs = _enabledlockingNFTs;
    }

    function configureNetwork(bool _isETHMainnet) external onlyOwner {
        isETHMainnet = _isETHMainnet;
    }

    /// @notice set reward multiplier for users who staked in LM staking contract based on NFT locked by users
    function _setLMStakingRewardMultiplier() internal {
        uint256 _multiplier;

        if (_nftStakerTokens[_msgSender()].contains(SILVER_NFT_ID)) {
            _multiplier = SILVER_NFT_BOOST;
        } else if (_nftStakerTokens[_msgSender()].contains(BRONZE_NFT_ID)) {
            _multiplier = BRONZE_NFT_BOOST;
        }

        liquidityMiningStakingETH.setRewardMultiplier(_msgSender(), _multiplier);
        liquidityMiningStakingUSDT.setRewardMultiplier(_msgSender(), _multiplier);
    }
}
