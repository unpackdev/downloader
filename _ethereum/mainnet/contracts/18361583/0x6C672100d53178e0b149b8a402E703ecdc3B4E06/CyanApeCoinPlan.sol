// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./ICyanApeCoinVault.sol";
import "./IApeCoinStaking.sol";
import "./IFactory.sol";
import "./IWalletApeCoin.sol";
import "./ICyanApeCoinPlan.sol";
import "./AddressProvider.sol";

error InvalidSignature();
error InvalidAddress();
error InvalidRate();
error PlanAlreadyExists();
error InvalidBlockNumber();
error LoanAmountExceedsPoolCap();

/// @title Cyan Payment Plan - Main logic of loaning and staking ApeCoin
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract CyanApeCoinPlan is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    AddressProvider private constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event AutoCompounded();
    event CreatedPlan(uint256 indexed planId);
    event Completed(uint256 indexed planId);
    event UpdatedCyanSigner(address indexed signer);
    event UpdatedWalletFactory(address indexed factory);
    event ClaimedServiceFee(uint256 indexed amount);
    event UpdatedServiceFeeRate(uint256 indexed serviceFeeRate);

    mapping(uint256 => ICyanApeCoinPlan.PaymentPlan) public paymentPlan;
    uint256 public claimableServiceFee;
    uint256 public serviceFeeRate;

    bytes32 public constant CYAN_ROLE = keccak256("CYAN_ROLE");
    address private cyanSigner;
    address private walletFactory;

    // ApeStakingPool ids
    uint256 public constant APECOIN_POOL_ID = 0;
    uint256 public constant BAYC_POOL_ID = 1;
    uint256 public constant MAYC_POOL_ID = 2;
    uint256 public constant BAKC_POOL_ID = 3;

    ICyanApeCoinVault public cyanApeCoinVault;

    function initialize(
        uint256 _serviceFeeRate,
        address _cyanSigner,
        address _cyanSuperAdmin,
        address _walletFactory,
        address _cyanApeCoinVaultAddress
    ) external initializer {
        if (
            _cyanSigner == address(0) ||
            _cyanSuperAdmin == address(0) ||
            _walletFactory == address(0) ||
            _cyanApeCoinVaultAddress == address(0)
        ) {
            revert InvalidAddress();
        }

        if (_serviceFeeRate > 10000) {
            revert InvalidRate();
        }

        serviceFeeRate = _serviceFeeRate;
        cyanSigner = _cyanSigner;
        walletFactory = _walletFactory;
        cyanApeCoinVault = ICyanApeCoinVault(_cyanApeCoinVaultAddress);

        getApeCoin().approve(_cyanApeCoinVaultAddress, type(uint256).max);
        getApeCoin().approve(address(getApeStaking()), type(uint256).max);

        _setupRole(DEFAULT_ADMIN_ROLE, _cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        __AccessControl_init();
        __ReentrancyGuard_init();

        emit UpdatedServiceFeeRate(_serviceFeeRate);
        emit UpdatedCyanSigner(_cyanSigner);
        emit UpdatedWalletFactory(_walletFactory);
    }

    function getPoolCap(uint256 poolId) private view returns (uint96) {
        IApeCoinStaking apeStaking = getApeStaking();
        uint16 lastRewardsRangeIndex = apeStaking.pools(poolId).lastRewardsRangeIndex;
        return apeStaking.getTimeRangeBy(poolId, lastRewardsRangeIndex).capPerPosition;
    }

    function calculateNumbers(ICyanApeCoinPlan.PaymentPlan memory plan, uint256 interestRate)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        IApeCoinStaking apeStaking = getApeStaking();
        uint256 stakedAmount = apeStaking.nftPosition(plan.poolId, plan.tokenId).stakedAmount;
        uint256 rewards = apeStaking.pendingRewards(plan.poolId, plan.cyanWalletAddress, plan.tokenId);

        uint256 interestFee = ((plan.loanedAmount * rewards * interestRate) / stakedAmount) / 10000;
        uint256 serviceFee = (rewards * serviceFeeRate) / 10000;

        rewards -= (interestFee + serviceFee);

        return (rewards, interestFee, serviceFee, stakedAmount);
    }

    function calculateApeCoinPoolNumbers(address cyanWalletAddress)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IApeCoinStaking.DashboardStake memory dashboard = getApeStaking().getApeCoinStake(cyanWalletAddress);
        return (dashboard.deposited, dashboard.unclaimed, (dashboard.unclaimed * serviceFeeRate) / 10000);
    }

    /**
     * @notice Creating Ape coin staking plan with BAYC
     * @param planId Plan ID
     * @param tokenId BAYC token ID
     * @param loanAmount Loaned ApeCoin amount
     * @param rewardStakeToCyanVault If enabled stake rewards to CyanVault, otherwise to ApeCoin pool
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createBaycPlan(
        uint256 planId,
        uint32 tokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external nonReentrant {
        if (paymentPlan[planId].cyanWalletAddress != address(0)) revert PlanAlreadyExists();

        verifySignature(planId, signedBlockNum, loanAmount, tokenId, BAYC_POOL_ID, rewardStakeToCyanVault, signature);
        (address mainAddress, address cyanWalletAddress) = getUserAddresses(msg.sender);

        // Transfer underlying NFT if it's not in the Cyan wallet
        transferItemByAddressId("BAYC", tokenId, mainAddress, cyanWalletAddress);
        uint224 alreadyStakedAmount = uint224(getApeStaking().nftPosition(BAYC_POOL_ID, tokenId).stakedAmount);
        uint224 stakeAmount = getPoolCap(BAYC_POOL_ID) - alreadyStakedAmount;
        if (loanAmount > 0) {
            if (loanAmount <= stakeAmount) {
                // Transfer ApeCoin to user's Cyan wallet
                cyanApeCoinVault.lend(cyanWalletAddress, loanAmount, BAYC_POOL_ID);
            } else {
                revert LoanAmountExceedsPoolCap();
            }
        }

        // Stake ape coin and lock the NFT
        IWalletApeCoin wallet = IWalletApeCoin(cyanWalletAddress);
        wallet.executeModule(abi.encodeWithSelector(IWalletApeCoin.depositBAYCAndLock.selector, tokenId, stakeAmount));

        ICyanApeCoinPlan.PaymentPlan memory plan = ICyanApeCoinPlan.PaymentPlan(
            BAYC_POOL_ID,
            tokenId,
            loanAmount,
            cyanWalletAddress,
            rewardStakeToCyanVault
                ? ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT
                : ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_APESTAKING
        );
        paymentPlan[planId] = plan;
        emit CreatedPlan(planId);
    }

    /**
     * @notice Creating Ape coin staking plan with MAYC
     * @param planId Plan ID
     * @param tokenId MAYC token ID
     * @param loanAmount Loaned ApeCoin amount
     * @param rewardStakeToCyanVault If enabled stake rewards to CyanVault, otherwise to ApeCoin pool
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createMaycPlan(
        uint256 planId,
        uint32 tokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external nonReentrant {
        if (paymentPlan[planId].cyanWalletAddress != address(0)) revert PlanAlreadyExists();

        verifySignature(planId, signedBlockNum, loanAmount, tokenId, MAYC_POOL_ID, rewardStakeToCyanVault, signature);
        (address mainAddress, address cyanWalletAddress) = getUserAddresses(msg.sender);

        // Transfer underlying NFT if it's not in the Cyan wallet
        transferItemByAddressId("MAYC", tokenId, mainAddress, cyanWalletAddress);
        uint224 alreadyStakedAmount = uint224(getApeStaking().nftPosition(MAYC_POOL_ID, tokenId).stakedAmount);
        uint224 stakeAmount = getPoolCap(MAYC_POOL_ID) - alreadyStakedAmount;
        if (loanAmount > 0) {
            if (loanAmount <= stakeAmount) {
                // Transfer ApeCoin to user's Cyan wallet
                cyanApeCoinVault.lend(cyanWalletAddress, loanAmount, MAYC_POOL_ID);
            } else {
                revert LoanAmountExceedsPoolCap();
            }
        }

        // Stake ape coin and lock the NFT
        IWalletApeCoin wallet = IWalletApeCoin(cyanWalletAddress);
        wallet.executeModule(abi.encodeWithSelector(IWalletApeCoin.depositMAYCAndLock.selector, tokenId, stakeAmount));

        ICyanApeCoinPlan.PaymentPlan memory plan = ICyanApeCoinPlan.PaymentPlan(
            MAYC_POOL_ID,
            tokenId,
            loanAmount,
            cyanWalletAddress,
            rewardStakeToCyanVault
                ? ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT
                : ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_APESTAKING
        );
        paymentPlan[planId] = plan;
        emit CreatedPlan(planId);
    }

    /**
     * @notice Creating Ape coin staking plan with BAYC & BAKC
     * @param planId Plan ID
     * @param baycTokenId BAYC token ID
     * @param bakcTokenId BAKC token ID
     * @param loanAmount Loaned ApeCoin amount
     * @param rewardStakeToCyanVault If enabled stake rewards to CyanVault, otherwise to ApeCoin pool
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createBakcPlanWithBAYC(
        uint256 planId,
        uint32 baycTokenId,
        uint32 bakcTokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external nonReentrant {
        verifyBakcSignature(
            planId,
            loanAmount,
            baycTokenId,
            bakcTokenId,
            BAKC_POOL_ID,
            BAYC_POOL_ID,
            signedBlockNum,
            rewardStakeToCyanVault,
            signature
        );

        createBakcPlan(planId, loanAmount, baycTokenId, bakcTokenId, getERC721("BAYC"), rewardStakeToCyanVault);
    }

    /**
     * @notice Creating Ape coin staking plan with MAYC & BAKC
     * @param planId Plan ID
     * @param maycTokenId MAYC token ID
     * @param bakcTokenId BAKC token ID
     * @param loanAmount Loaned ApeCoin amount
     * @param rewardStakeToCyanVault If enabled stake rewards to CyanVault, otherwise to ApeCoin pool
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createBakcPlanWithMAYC(
        uint256 planId,
        uint32 maycTokenId,
        uint32 bakcTokenId,
        uint224 loanAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external nonReentrant {
        verifyBakcSignature(
            planId,
            loanAmount,
            maycTokenId,
            bakcTokenId,
            BAKC_POOL_ID,
            MAYC_POOL_ID,
            signedBlockNum,
            rewardStakeToCyanVault,
            signature
        );

        createBakcPlan(planId, loanAmount, maycTokenId, bakcTokenId, getERC721("MAYC"), rewardStakeToCyanVault);
    }

    function createBakcPlan(
        uint256 planId,
        uint224 loanAmount,
        uint32 mainTokenId,
        uint32 bakcTokenId,
        IERC721Upgradeable mainCollection,
        bool rewardStakeToCyanVault
    ) private {
        if (paymentPlan[planId].cyanWalletAddress != address(0)) revert PlanAlreadyExists();

        (address mainAddress, address cyanWalletAddress) = getUserAddresses(msg.sender);
        // Transfer underlying NFTs if it's not in the Cyan wallet
        if (mainCollection.ownerOf(mainTokenId) != cyanWalletAddress) {
            mainCollection.safeTransferFrom(mainAddress, cyanWalletAddress, mainTokenId);
        }

        transferItemByAddressId("BAKC", bakcTokenId, mainAddress, cyanWalletAddress);
        uint224 alreadyStakedAmount = uint224(getApeStaking().nftPosition(BAKC_POOL_ID, bakcTokenId).stakedAmount);
        uint224 stakeAmount = getPoolCap(BAKC_POOL_ID) - alreadyStakedAmount;
        if (loanAmount > 0) {
            if (loanAmount <= stakeAmount) {
                // Transfer ApeCoin to user's Cyan wallet
                cyanApeCoinVault.lend(cyanWalletAddress, loanAmount, BAKC_POOL_ID);
            } else {
                revert LoanAmountExceedsPoolCap();
            }
        }

        IWalletApeCoin wallet = IWalletApeCoin(cyanWalletAddress);
        wallet.executeModule(
            abi.encodeWithSelector(
                IWalletApeCoin.depositBAKCAndLock.selector,
                address(mainCollection),
                mainTokenId,
                bakcTokenId,
                stakeAmount
            )
        );

        ICyanApeCoinPlan.PaymentPlan memory plan = ICyanApeCoinPlan.PaymentPlan(
            BAKC_POOL_ID,
            bakcTokenId,
            loanAmount,
            cyanWalletAddress,
            rewardStakeToCyanVault
                ? ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT
                : ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_APESTAKING
        );
        paymentPlan[planId] = plan;
        emit CreatedPlan(planId);
    }

    /**
     * @notice Creating Ape coin staking plan to ApeCoin pool
     * @param planId Plan ID
     * @param stakeAmount Stake ApeCoin amount
     * @param rewardStakeToCyanVault If enabled stake rewards to CyanVault, otherwise to ApeCoin pool
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createApeCoinPlan(
        uint256 planId,
        uint256 stakeAmount,
        bool rewardStakeToCyanVault,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external nonReentrant {
        if (paymentPlan[planId].cyanWalletAddress != address(0)) revert PlanAlreadyExists();

        verifyApeCoinPlanSignature(
            planId,
            signedBlockNum,
            stakeAmount,
            APECOIN_POOL_ID,
            rewardStakeToCyanVault,
            signature
        );
        (, address cyanWalletAddress) = getUserAddresses(msg.sender);

        // Stake ape coin and lock the NFT
        IWalletApeCoin wallet = IWalletApeCoin(cyanWalletAddress);
        wallet.executeModule(abi.encodeWithSelector(IWalletApeCoin.depositApeCoinAndLock.selector, stakeAmount));

        ICyanApeCoinPlan.PaymentPlan memory plan = ICyanApeCoinPlan.PaymentPlan(
            APECOIN_POOL_ID,
            0,
            0,
            cyanWalletAddress,
            rewardStakeToCyanVault
                ? ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT
                : ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_APESTAKING
        );
        paymentPlan[planId] = plan;
        emit CreatedPlan(planId);
    }

    /**
     * @notice Complete NFT staking plan
     * @param planId Payment Plan ID
     */
    function complete(uint256 planId) external nonReentrant {
        ICyanApeCoinPlan.PaymentPlan memory plan = paymentPlan[planId];

        require(plan.cyanWalletAddress != address(0), "CyanApeCoinPlan: plan does not exist");
        require(
            plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_APESTAKING ||
                plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT,
            "CyanApeCoinPlan: plan is not active"
        );
        require(plan.poolId != APECOIN_POOL_ID, "CyanApeCoinPlan: plan is ApeCoin plan");

        if (msg.sender != paymentPlan[planId].cyanWalletAddress) {
            address mainWalletAddress = getMainWalletAddress(paymentPlan[planId].cyanWalletAddress);
            require(msg.sender == mainWalletAddress, "CyanApeCoinPlan: Must be plan owner to complete");
        }

        uint256 poolInterestRate = cyanApeCoinVault.interestRates(plan.poolId);
        (uint256 rewards, uint256 interestFee, uint256 serviceFee, uint256 stakedAmount) = calculateNumbers(
            plan,
            poolInterestRate
        );

        IWalletApeCoin wallet = IWalletApeCoin(plan.cyanWalletAddress);
        bytes4 withdrawFunctionSelector;
        if (plan.poolId == BAYC_POOL_ID) {
            withdrawFunctionSelector = IWalletApeCoin.withdrawBAYCAndUnlock.selector;
        } else if (plan.poolId == MAYC_POOL_ID) {
            withdrawFunctionSelector = IWalletApeCoin.withdrawMAYCAndUnlock.selector;
        } else {
            withdrawFunctionSelector = IWalletApeCoin.withdrawBAKCAndUnlock.selector;
        }
        wallet.executeModule(abi.encodeWithSelector(withdrawFunctionSelector, plan.tokenId));

        claimableServiceFee += serviceFee;

        if (plan.loanedAmount > 0) {
            cyanApeCoinVault.pay(plan.loanedAmount, interestFee, plan.poolId);
        }
        paymentPlan[planId].status = ICyanApeCoinPlan.PaymentPlanStatus.COMPLETED;

        uint256 depositAmount = stakedAmount + rewards - plan.loanedAmount;
        if (depositAmount > 0) {
            if (plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT) {
                cyanApeCoinVault.deposit(ICyanApeCoinVault.DepositInfo(plan.cyanWalletAddress, depositAmount));
            } else {
                IApeCoinStaking apeStaking = getApeStaking();
                apeStaking.depositApeCoin(depositAmount, plan.cyanWalletAddress);
            }
        }

        emit Completed(planId);
    }

    /**
     * @notice Complete ApeCoin staking plan
     * @param planId Payment Plan ID
     */
    function completeApeCoinPlan(uint256 planId) external nonReentrant {
        ICyanApeCoinPlan.PaymentPlan memory plan = paymentPlan[planId];

        require(plan.cyanWalletAddress != address(0), "CyanApeCoinPlan: plan does not exist");
        require(
            plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_APESTAKING ||
                plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT,
            "CyanApeCoinPlan: plan is not active"
        );
        require(plan.poolId == APECOIN_POOL_ID, "CyanApeCoinPlan: plan is not ApeCoin plan");

        if (msg.sender != paymentPlan[planId].cyanWalletAddress) {
            address mainWalletAddress = getMainWalletAddress(paymentPlan[planId].cyanWalletAddress);
            require(msg.sender == mainWalletAddress, "CyanApeCoinPlan: Must be plan owner to complete");
        }

        (uint256 deposited, , uint256 serviceFee) = calculateApeCoinPoolNumbers(paymentPlan[planId].cyanWalletAddress);

        IWalletApeCoin wallet = IWalletApeCoin(plan.cyanWalletAddress);
        wallet.executeModule(
            abi.encodeWithSelector(IWalletApeCoin.withdrawApeCoinAndUnlock.selector, deposited, serviceFee)
        );

        claimableServiceFee += serviceFee;

        paymentPlan[planId].status = ICyanApeCoinPlan.PaymentPlanStatus.COMPLETED;

        emit Completed(planId);
    }

    function autoCompound(uint256[] calldata planIds) external nonReentrant onlyRole(CYAN_ROLE) {
        uint256 totalInterestFee;
        uint256 totalServiceFee;
        uint256[4] memory poolInterestRates = cyanApeCoinVault.getPoolInterestRates();

        ICyanApeCoinVault.DepositInfo[] memory deposits = new ICyanApeCoinVault.DepositInfo[](planIds.length);
        IApeCoinStaking apeStaking = getApeStaking();

        for (uint256 ind; ind < planIds.length; ) {
            ICyanApeCoinPlan.PaymentPlan memory plan = paymentPlan[planIds[ind]];

            require(plan.cyanWalletAddress != address(0), "CyanApeCoinPlan: plan does not exist");
            require(
                plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_APESTAKING ||
                    plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT,
                "CyanApeCoinPlan: plan is not active"
            );
            IWalletApeCoin wallet = IWalletApeCoin(plan.cyanWalletAddress);
            uint256 rewards;
            if (plan.poolId == APECOIN_POOL_ID) {
                (, uint256 unclaimed, uint256 serviceFee) = calculateApeCoinPoolNumbers(plan.cyanWalletAddress);
                rewards = unclaimed - serviceFee;
                require(rewards > 0, "CyanApeCoinPlan: not enough rewards");

                wallet.executeModule(abi.encodeWithSelector(IWalletApeCoin.autoCompoundApeCoinPool.selector));

                totalServiceFee += serviceFee;
            } else {
                (uint256 _rewards, uint256 interestFee, uint256 serviceFee, ) = calculateNumbers(
                    plan,
                    poolInterestRates[plan.poolId]
                );
                rewards = _rewards;
                require(rewards > 0, "CyanApeCoinPlan: not enough rewards");

                wallet.executeModule(
                    abi.encodeWithSelector(IWalletApeCoin.autoCompound.selector, plan.poolId, plan.tokenId)
                );

                totalServiceFee += serviceFee;
                totalInterestFee += interestFee;
            }
            if (plan.status == ICyanApeCoinPlan.PaymentPlanStatus.ACTIVE_ACCRUE_CYANVAULT) {
                deposits[ind] = ICyanApeCoinVault.DepositInfo(plan.cyanWalletAddress, rewards);
            } else {
                deposits[ind] = ICyanApeCoinVault.DepositInfo(plan.cyanWalletAddress, 0);
                apeStaking.depositApeCoin(rewards, plan.cyanWalletAddress);
            }
            unchecked {
                ++ind;
            }
        }

        claimableServiceFee += totalServiceFee;

        cyanApeCoinVault.earn(totalInterestFee);
        cyanApeCoinVault.depositBatch(deposits);

        emit AutoCompounded();
    }

    function verifySignature(
        uint256 planId,
        uint256 signedBlockNum,
        uint224 amount,
        uint32 tokenId,
        uint256 poolId,
        bool rewardStakeToCyanVault,
        bytes calldata signature
    ) private view {
        if (signedBlockNum > block.number) revert InvalidBlockNumber();
        if (signedBlockNum + 50 < block.number) revert InvalidSignature();

        bytes32 msgHash = keccak256(
            abi.encodePacked(planId, tokenId, signedBlockNum, amount, poolId, rewardStakeToCyanVault)
        );
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        if (signedHash.recover(signature) != cyanSigner) revert InvalidSignature();
    }

    function verifyBakcSignature(
        uint256 planId,
        uint224 amount,
        uint32 mainTokenId,
        uint32 bakcTokenId,
        uint256 poolId,
        uint256 mainPoolId,
        uint256 signedBlockNum,
        bool rewardStakeToCyanVault,
        bytes calldata signature
    ) private view {
        if (signedBlockNum > block.number) revert InvalidBlockNumber();
        if (signedBlockNum + 50 < block.number) revert InvalidSignature();

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                planId,
                amount,
                mainTokenId,
                bakcTokenId,
                poolId,
                mainPoolId,
                signedBlockNum,
                rewardStakeToCyanVault
            )
        );
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        if (signedHash.recover(signature) != cyanSigner) revert InvalidSignature();
    }

    function verifyApeCoinPlanSignature(
        uint256 planId,
        uint256 signedBlockNum,
        uint256 amount,
        uint256 poolId,
        bool rewardStakeToCyanVault,
        bytes calldata signature
    ) private view {
        if (signedBlockNum > block.number) revert InvalidBlockNumber();
        if (signedBlockNum + 50 < block.number) revert InvalidSignature();

        bytes32 msgHash = keccak256(abi.encodePacked(planId, signedBlockNum, amount, poolId, rewardStakeToCyanVault));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        if (signedHash.recover(signature) != cyanSigner) revert InvalidSignature();
    }

    function getUserAddresses(address caller) private returns (address, address) {
        address mainAddress = caller;
        address cyanWalletAddress = IFactory(walletFactory).getOrDeployWallet(caller);
        if (cyanWalletAddress == caller) {
            mainAddress = IFactory(walletFactory).getWalletOwner(cyanWalletAddress);
        }
        return (mainAddress, cyanWalletAddress);
    }

    /**
     * @notice Getting main wallet address by Cyan wallet address
     * @param cyanWalletAddress Cyan wallet address
     */
    function getMainWalletAddress(address cyanWalletAddress) private view returns (address) {
        return IFactory(walletFactory).getWalletOwner(cyanWalletAddress);
    }

    /**
     * @notice Updating Cyan signer address
     * @param _cyanSigner New Cyan signer address
     */
    function updateCyanSignerAddress(address _cyanSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_cyanSigner == address(0)) revert InvalidAddress();
        cyanSigner = _cyanSigner;
        emit UpdatedCyanSigner(_cyanSigner);
    }

    /**
     * @notice Claiming collected service fee amount
     */
    function claimServiceFee() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ClaimedServiceFee(claimableServiceFee);
        getApeCoin().safeTransfer(msg.sender, claimableServiceFee);
        claimableServiceFee = 0;
    }

    /**
     * @notice Updating Cyan wallet factory address that used for deploying new wallets
     * @param factory New Cyan wallet factory address
     */
    function updateWalletFactoryAddress(address factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (factory == address(0)) revert InvalidAddress();
        walletFactory = factory;
        emit UpdatedWalletFactory(factory);
    }

    /**
     * @notice Updating Cyan service fee rate
     * @param feeRate New service fee rate
     */
    function updateServiceFeeRate(uint256 feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (feeRate > 10000) revert InvalidRate();
        serviceFeeRate = feeRate;
        emit UpdatedServiceFeeRate(feeRate);
    }

    /**
     * @notice Approve ApeCoin to Cyan Vault
     * @param vaultAddress Cyan Vault Address
     */
    function updateCyanVaultAddress(address vaultAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (vaultAddress == address(0)) revert InvalidAddress();

        IERC20Upgradeable apeCoin = getApeCoin();
        apeCoin.approve(address(cyanApeCoinVault), 0);

        cyanApeCoinVault = ICyanApeCoinVault(vaultAddress);
        apeCoin.approve(vaultAddress, type(uint256).max);
    }

    /**
     * @notice Approve the max amount of ApeCoin for the ApeCoin staking contract
     */
    function apeCoinApproval() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        getApeCoin().approve(address(getApeStaking()), type(uint256).max);
    }

    function getERC721(bytes32 id) private view returns (IERC721Upgradeable) {
        return IERC721Upgradeable(addressProvider.addresses(id));
    }

    function getApeStaking() private view returns (IApeCoinStaking) {
        return IApeCoinStaking(addressProvider.addresses("APE_COIN_STAKING"));
    }

    function getApeCoin() private view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(addressProvider.addresses("APE_COIN"));
    }

    function transferItemByAddressId(
        bytes32 id,
        uint256 tokenId,
        address mainAddress,
        address cyanWalletAddress
    ) private {
        IERC721Upgradeable collection = getERC721(id);
        if (collection.ownerOf(tokenId) != cyanWalletAddress) {
            collection.safeTransferFrom(mainAddress, cyanWalletAddress, tokenId);
        }
    }
}
