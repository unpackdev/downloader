// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./CyanApeCoinVault.sol";
import "./IFactory.sol";
import "./IWalletApeCoin.sol";
import "./IApeCoinStaking.sol";

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
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event AutoCompounded();
    event CreatedPlan(uint256 indexed planId);
    event Completed(uint256 indexed planId);
    event UpdatedCyanSigner(address indexed signer);
    event UpdatedWalletFactory(address indexed factory);
    event ClaimedServiceFee(uint256 indexed amount);
    event UpdatedServiceFeeRate(uint256 indexed serviceFeeRate);

    enum PaymentPlanStatus {
        NONE,
        ACTIVE,
        COMPLETED
    }
    struct PaymentPlan {
        uint256 poolId;
        uint32 tokenId;
        uint224 loanedAmount;
        address cyanWalletAddress;
        PaymentPlanStatus status;
    }
    mapping(uint256 => PaymentPlan) public paymentPlan;
    uint256 public claimableServiceFee;
    uint256 public serviceFeeRate;

    bytes32 public constant CYAN_ROLE = keccak256("CYAN_ROLE");
    address private cyanSigner;
    address private walletFactory;

    // ApeStakingPool ids
    uint256 public constant BAYC_POOL_ID = 1;
    uint256 public constant MAYC_POOL_ID = 2;
    uint256 public constant BAKC_POOL_ID = 3;

    // Yuga contracts
    IApeCoinStaking public constant apeStaking = IApeCoinStaking(0x5954aB967Bc958940b7EB73ee84797Dc8a2AFbb9);
    IERC20Upgradeable public constant apeCoin = IERC20Upgradeable(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
    IERC721Upgradeable public constant BAYC = IERC721Upgradeable(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC721Upgradeable public constant MAYC = IERC721Upgradeable(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
    IERC721Upgradeable public constant BAKC = IERC721Upgradeable(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623);

    CyanApeCoinVault public cyanApeCoinVault;

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
        cyanApeCoinVault = CyanApeCoinVault(_cyanApeCoinVaultAddress);

        apeCoin.approve(_cyanApeCoinVaultAddress, type(uint256).max);

        _setupRole(DEFAULT_ADMIN_ROLE, _cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        __AccessControl_init();
        __ReentrancyGuard_init();

        emit UpdatedServiceFeeRate(_serviceFeeRate);
        emit UpdatedCyanSigner(_cyanSigner);
        emit UpdatedWalletFactory(_walletFactory);
    }

    function getPoolCap(uint256 poolId) private view returns (uint96) {
        uint16 lastRewardsRangeIndex = apeStaking.pools(poolId).lastRewardsRangeIndex;
        return apeStaking.getTimeRangeBy(poolId, lastRewardsRangeIndex).capPerPosition;
    }

    function calculateNumbers(PaymentPlan memory plan, uint256 interestRate)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 stakedAmount = apeStaking.nftPosition(plan.poolId, plan.tokenId).stakedAmount;
        uint256 rewards = apeStaking.pendingRewards(plan.poolId, plan.cyanWalletAddress, plan.tokenId);

        uint256 interestFee = ((plan.loanedAmount * rewards * interestRate) / stakedAmount) / 10000;
        uint256 serviceFee = (rewards * serviceFeeRate) / 10000;

        rewards -= (interestFee + serviceFee);

        return (rewards, interestFee, serviceFee, stakedAmount);
    }

    /**
     * @notice Creating Ape coin staking plan with BAYC
     * @param planId Plan ID
     * @param tokenId BAYC token ID
     * @param loanAmount Loaned ApeCoin amount
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createBaycPlan(
        uint256 planId,
        uint32 tokenId,
        uint224 loanAmount,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external nonReentrant {
        if (paymentPlan[planId].status != PaymentPlanStatus.NONE) revert PlanAlreadyExists();

        verifySignature(planId, signedBlockNum, loanAmount, tokenId, BAYC_POOL_ID, signature);
        (address mainAddress, address cyanWalletAddress) = getUserAddresses(msg.sender);

        // Transfer underlying NFT if it's not in the Cyan wallet
        if (BAYC.ownerOf(tokenId) != cyanWalletAddress) {
            BAYC.safeTransferFrom(mainAddress, cyanWalletAddress, tokenId);
        }
        uint224 alreadyStakedAmount = uint224(apeStaking.nftPosition(BAYC_POOL_ID, tokenId).stakedAmount);
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

        PaymentPlan memory plan = PaymentPlan(
            BAYC_POOL_ID,
            tokenId,
            loanAmount,
            cyanWalletAddress,
            PaymentPlanStatus.ACTIVE
        );
        paymentPlan[planId] = plan;
        emit CreatedPlan(planId);
    }

    /**
     * @notice Creating Ape coin staking plan with MAYC
     * @param planId Plan ID
     * @param tokenId MAYC token ID
     * @param loanAmount Loaned ApeCoin amount
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createMaycPlan(
        uint256 planId,
        uint32 tokenId,
        uint224 loanAmount,
        uint256 signedBlockNum,
        bytes calldata signature
    ) external nonReentrant {
        if (paymentPlan[planId].status != PaymentPlanStatus.NONE) revert PlanAlreadyExists();

        verifySignature(planId, signedBlockNum, loanAmount, tokenId, MAYC_POOL_ID, signature);
        (address mainAddress, address cyanWalletAddress) = getUserAddresses(msg.sender);

        // Transfer underlying NFT if it's not in the Cyan wallet
        if (MAYC.ownerOf(tokenId) != cyanWalletAddress) {
            MAYC.safeTransferFrom(mainAddress, cyanWalletAddress, tokenId);
        }
        uint224 alreadyStakedAmount = uint224(apeStaking.nftPosition(MAYC_POOL_ID, tokenId).stakedAmount);
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

        PaymentPlan memory plan = PaymentPlan(
            MAYC_POOL_ID,
            tokenId,
            loanAmount,
            cyanWalletAddress,
            PaymentPlanStatus.ACTIVE
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
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createBakcPlanWithBAYC(
        uint256 planId,
        uint32 baycTokenId,
        uint32 bakcTokenId,
        uint224 loanAmount,
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
            signature
        );

        createBakcPlan(planId, loanAmount, baycTokenId, bakcTokenId, BAYC);
    }

    /**
     * @notice Creating Ape coin staking plan with MAYC & BAKC
     * @param planId Plan ID
     * @param maycTokenId MAYC token ID
     * @param bakcTokenId BAKC token ID
     * @param loanAmount Loaned ApeCoin amount
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createBakcPlanWithMAYC(
        uint256 planId,
        uint32 maycTokenId,
        uint32 bakcTokenId,
        uint224 loanAmount,
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
            signature
        );

        createBakcPlan(planId, loanAmount, maycTokenId, bakcTokenId, MAYC);
    }

    function createBakcPlan(
        uint256 planId,
        uint224 loanAmount,
        uint32 mainTokenId,
        uint32 bakcTokenId,
        IERC721Upgradeable mainCollection
    ) private {
        if (paymentPlan[planId].status != PaymentPlanStatus.NONE) revert PlanAlreadyExists();

        (address mainAddress, address cyanWalletAddress) = getUserAddresses(msg.sender);
        // Transfer underlying NFTs if it's not in the Cyan wallet
        if (mainCollection.ownerOf(mainTokenId) != cyanWalletAddress) {
            mainCollection.safeTransferFrom(mainAddress, cyanWalletAddress, mainTokenId);
        }
        if (BAKC.ownerOf(bakcTokenId) != cyanWalletAddress) {
            BAKC.safeTransferFrom(mainAddress, cyanWalletAddress, bakcTokenId);
        }
        uint224 alreadyStakedAmount = uint224(apeStaking.nftPosition(BAKC_POOL_ID, bakcTokenId).stakedAmount);
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

        PaymentPlan memory plan = PaymentPlan(
            BAKC_POOL_ID,
            bakcTokenId,
            loanAmount,
            cyanWalletAddress,
            PaymentPlanStatus.ACTIVE
        );
        paymentPlan[planId] = plan;
        emit CreatedPlan(planId);
    }

    /**
     * @notice Make a payment for the payment plan
     * @param planId Payment Plan ID
     */
    function complete(uint256 planId) external nonReentrant {
        PaymentPlan memory plan = paymentPlan[planId];

        require(plan.status == PaymentPlanStatus.ACTIVE, "CyanApeCoinPlan: plan is not active");
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
        paymentPlan[planId].status = PaymentPlanStatus.COMPLETED;

        uint256 depositAmount = stakedAmount + rewards - plan.loanedAmount;
        if (depositAmount > 0) {
            cyanApeCoinVault.deposit(CyanApeCoinVault.DepositInfo(plan.cyanWalletAddress, depositAmount));
        }

        emit Completed(planId);
    }

    function autoCompound(uint256[] calldata planIds) external nonReentrant onlyRole(CYAN_ROLE) {
        uint256 totalInterestFee;
        uint256 totalServiceFee;
        uint256[4] memory poolInterestRates = cyanApeCoinVault.getPoolInterestRates();

        CyanApeCoinVault.DepositInfo[] memory deposits = new CyanApeCoinVault.DepositInfo[](planIds.length);

        for (uint256 ind; ind < planIds.length; ) {
            PaymentPlan memory plan = paymentPlan[planIds[ind]];

            require(plan.status == PaymentPlanStatus.ACTIVE, "CyanApeCoinPlan: plan is not active");

            (uint256 rewards, uint256 interestFee, uint256 serviceFee, ) = calculateNumbers(
                plan,
                poolInterestRates[plan.poolId]
            );
            require(rewards > 0, "CyanApeCoinPlan: not enough rewards");

            IWalletApeCoin wallet = IWalletApeCoin(plan.cyanWalletAddress);
            wallet.executeModule(
                abi.encodeWithSelector(
                    IWalletApeCoin.autoCompound.selector,
                    plan.poolId,
                    plan.tokenId,
                    rewards + interestFee + serviceFee
                )
            );

            totalServiceFee += serviceFee;
            totalInterestFee += interestFee;

            deposits[ind] = CyanApeCoinVault.DepositInfo(plan.cyanWalletAddress, rewards);

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
        bytes calldata signature
    ) private view {
        if (signedBlockNum > block.number) revert InvalidBlockNumber();
        if (signedBlockNum + 50 < block.number) revert InvalidSignature();

        bytes32 msgHash = keccak256(abi.encodePacked(planId, tokenId, signedBlockNum, amount, poolId));
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
        bytes calldata signature
    ) private view {
        if (signedBlockNum > block.number) revert InvalidBlockNumber();
        if (signedBlockNum + 50 < block.number) revert InvalidSignature();

        bytes32 msgHash = keccak256(
            abi.encodePacked(planId, amount, mainTokenId, bakcTokenId, poolId, mainPoolId, signedBlockNum)
        );
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
        apeCoin.safeTransfer(msg.sender, claimableServiceFee);
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
        apeCoin.approve(address(cyanApeCoinVault), 0);

        cyanApeCoinVault = CyanApeCoinVault(vaultAddress);
        apeCoin.approve(vaultAddress, type(uint256).max);
    }
}
