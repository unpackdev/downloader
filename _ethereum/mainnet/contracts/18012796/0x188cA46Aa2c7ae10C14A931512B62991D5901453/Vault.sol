// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./Pausable.sol";
import "./SafeTransferLib.sol";
import "./ReentrancyGuard.sol";
import "./IMinter.sol";
import "./IStaker.sol";
import "./ERC4626.sol";
import "./ERC20.sol";
import "./ISwapper.sol";
import "./AOperator.sol";
import "./AFees.sol";
import "./Errors.sol";
import "./Allowance.sol";
import "./Owned2Step.sol";

/// @author 0xtekgrinder
/// @title Vault contract
/// @notice Auto compounding vault for the warlord protocol with token to deposit being WAR and asset being stkWAR
contract Vault is ERC4626, Pausable, ReentrancyGuard, AFees, AOperator {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when a staker is updated
     */
    event StakerUpdated(address oldStaker, address newStaker);
    /**
     * @notice Event emitted when a minter is updated
     */
    event MinterUpdated(address oldMinter, address newMinter);
    /**
     * @notice Event emitted when a swapper is updated
     */
    event SwapperUpdated(address oldSwapper, address newSwapper);

    /**
     * @notice Event emitted when reward have been harvested
     */
    event Harvested(uint256 amount);
    /**
     * @notice Event emitted when rewards are compounded into more stkWAR
     */
    event Compounded(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                          MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Address of the stkWAR token
     */
    address public staker;
    /**
     *  @notice Address of the WAR minter contract
     */
    address public minter;
    /**
     * @notice Address of the swapper contract
     */
    address public swapper;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address initialOwner,
        address initialStaker,
        address initialMinter,
        address initialSwapper,
        uint256 initialHarvestFee,
        address initialFeeRecipient,
        address initialFeeToken,
        address initialOperator,
        address definitiveAsset
    )
        Owned2Step(initialOwner)
        ERC4626(ERC20(definitiveAsset), "Tholgar Warlord Token", "tWAR")
        AFees(initialHarvestFee, initialFeeRecipient, initialFeeToken)
        AOperator(initialOperator)
    {
        if (initialStaker == address(0) || initialMinter == address(0) || initialSwapper == address(0)) {
            revert Errors.ZeroAddress();
        }

        staker = initialStaker;
        minter = initialMinter;
        swapper = initialSwapper;

        ERC20(definitiveAsset).safeApprove(initialStaker, type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice update the staker contract to a new one
     * @param newStaker the new staker contract
     * @custom:requires owner
     */
    function setStaker(address newStaker) external onlyOwner {
        if (newStaker == address(0)) revert Errors.ZeroAddress();
        address oldStaker = staker;

        staker = newStaker;
        emit StakerUpdated(oldStaker, newStaker);

        // Unstake all wars from old staker
        uint256 stakerBalance = ERC20(oldStaker).balanceOf(address(this));
        if (stakerBalance != 0) {
            IStaker(oldStaker).unstake(stakerBalance, address(this));
        }
        // revoke allowance from old staker
        ERC20(address(asset)).safeApprove(oldStaker, 0);

        // approve all war tokens to be spent by new staker
        ERC20(address(asset)).safeApprove(newStaker, type(uint256).max);

        // Restake all tokens
        uint256 warBalance = asset.balanceOf(address(this));
        if (warBalance != 0) {
            IStaker(newStaker).stake(warBalance, address(this));
        }
    }

    /**
     * @notice update the swapper contract to a new one
     * @param newSwapper the new swapper contract
     * @custom:requires owner
     */
    function setSwapper(address newSwapper) external onlyOwner {
        if (newSwapper == address(0)) revert Errors.ZeroAddress();

        address oldSwapper = swapper;
        swapper = newSwapper;

        emit SwapperUpdated(oldSwapper, newSwapper);
    }

    /**
     * @notice update the minter contract to a new one
     * @param newMinter the new minter contract
     * @custom:requires owner
     */
    function setMinter(address newMinter) external onlyOwner {
        if (newMinter == address(0)) revert Errors.ZeroAddress();

        address oldMinter = minter;
        minter = newMinter;

        emit MinterUpdated(oldMinter, newMinter);
    }

    /**
     * @notice Recover ERC2O tokens in the contract
     * @dev Recover ERC2O tokens in the contract
     * @param token Address of the ERC2O token
     * @return bool: success
     * @custom:requires owner
     */
    function recoverERC20(address token) external onlyOwner returns (bool) {
        if (token == address(0)) revert Errors.ZeroAddress();

        uint256 amount = ERC20(token).balanceOf(address(this));
        if (amount == 0) revert Errors.ZeroValue();

        ERC20(token).safeTransfer(owner, amount);

        return true;
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev totalAssets is the total number of stkWAR
     */
    function totalAssets() public view override returns (uint256) {
        uint256 assets = ERC20(staker).balanceOf(address(this));

        return assets;
    }

    /**
     * @custom:notpaused when not paused
     */
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256 shares) {
        return super.deposit(assets, receiver);
    }

    /**
     * @custom:notpaused when not paused
     */
    function mint(uint256 shares, address receiver) public override whenNotPaused returns (uint256 assets) {
        return super.mint(shares, receiver);
    }

    /**
     * @custom:notpaused when not paused
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256 shares)
    {
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @custom:notpaused when not paused
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256 assets)
    {
        return super.redeem(shares, receiver, owner);
    }

    /**
     * @dev stake assets after each deposit
     */
    function afterDeposit(uint256 assets, uint256 /* shares */ ) internal override {
        IStaker(staker).stake(assets, address(this));
    }

    /**
     * @dev unstake assets before each withdraw to have enough WAR to transfer
     */
    function beforeWithdraw(uint256 assets, uint256 /*shares */ ) internal override {
        IStaker(staker).unstake(assets, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                            HARVEST LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Harvest all rewards from staker
     * @dev calldatas should swap from all reward tokens to feeToken
     * @param tokensToHarvest tokens to harvest
     * @param tokensToSwap tokens to swap to feeToken
     * @param callDatas swapper routes to swap to feeToken
     * @custom:requires operator or owner
     */
    function harvest(address[] calldata tokensToHarvest, address[] calldata tokensToSwap, bytes[] calldata callDatas)
        external
        nonReentrant
        onlyOperatorOrOwner
    {
        address _swapper = swapper;
        address _feeToken = feeToken;
        uint256 oldFeeBalance = ERC20(_feeToken).balanceOf(address(this));

        // claim all harvastable rewards and send them to the swapper
        uint256 length = tokensToHarvest.length;
        for (uint256 i; i < length;) {
            address tokenToHarvest = tokensToHarvest[i];
            address recipient;
            if (tokenToHarvest == address(asset) || tokenToHarvest == address(_feeToken)) {
                recipient = address(this);
            } else {
                recipient = _swapper;
            }
            IStaker(staker).claimRewards(tokenToHarvest, recipient);
            unchecked {
                ++i;
            }
        }

        // swap to harvested tokens to feeToken
        ISwapper(_swapper).swap(tokensToSwap, callDatas);

        // transfer havestfee %oo to fee recipient
        uint256 harvestedAmount = ERC20(_feeToken).balanceOf(address(this)) - oldFeeBalance;
        ERC20(_feeToken).safeTransfer(feeRecipient, (harvestedAmount * harvestFee) / MAX_BPS);

        emit Harvested(harvestedAmount);
    }

    /**
     * @notice Turn all rewards into more staked assets
     * @param callDatas swapper routes to swap to more assets
     * @param tokensToMint tokens to mint more stkWAR
     * @param tokensToSwap tokens which includes the feeToken to swap to more assets
     * @custom:requires operator or owner
     */
    function compound(address[] calldata tokensToSwap, bytes[] calldata callDatas, address[] calldata tokensToMint)
        external
        nonReentrant
        onlyOperatorOrOwner
    {
        address _feeToken = feeToken;

        // swap feeToken to WeightedTokens with correct ratios
        ERC20(_feeToken).safeTransfer(swapper, ERC20(_feeToken).balanceOf(address(this)));
        ISwapper(swapper).swap(tokensToSwap, callDatas);

        // Mint more stkWAR
        uint256 length = tokensToMint.length;
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i; i < length;) {
            address token = tokensToMint[i];
            amounts[i] = ERC20(token).balanceOf(address(this));
            Allowance._approveTokenIfNeeded(token, minter);
            unchecked {
                ++i;
            }
        }
        IMinter(minter).mintMultiple(tokensToMint, amounts);
        uint256 stakedAmount = IStaker(staker).stake(asset.balanceOf(address(this)), address(this));

        emit Compounded(stakedAmount);
    }
}
