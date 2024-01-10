// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20.sol";
import "./ITreasury.sol";
import "./INFTXInventoryStaking.sol";
import "./INFTXLPStaking.sol";

import "./IAllocator.sol";

import "./FloorAccessControlled.sol";


/**
 * Contract deploys reserves from treasury into NFTX vaults,
 * earning interest and rewards.
 */

contract NFTXAllocator is IAllocator, FloorAccessControlled {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
     * @notice describes the token used for staking in NFTX.
     */

    struct stakingTokenData {
        uint256 vaultId;
        address rewardToken;
        bool isLiquidityPool;
        bool exists;
    }

    event TreasuryAssetDeployed(address token, uint256 amount, uint256 value);
    event TreasuryAssetReturned(address token, uint256 amount, uint256 value);

    // NFTX Inventory Staking contract
    INFTXInventoryStaking internal immutable inventoryStaking;

    // NFTX Liquidity Staking contract
    INFTXLPStaking internal immutable liquidityStaking;

    // Floor Treasury contract
    ITreasury internal immutable treasury;

    // Corresponding NFTX token vault data for tokens
    mapping (address => stakingTokenData) public stakingTokenInfo;

    // Corresponding xTokens for tokens
    mapping (address => address) public dividendTokenMapping;


    /**
     * @notice initialises the construct with no additional logic.
     */

    constructor (
        address _authority,
        address _inventoryStaking,
        address _liquidityStaking,
        address _treasury
    ) FloorAccessControlled(IFloorAuthority(_authority)) {
        inventoryStaking = INFTXInventoryStaking(_inventoryStaking);
        liquidityStaking = INFTXLPStaking(_liquidityStaking);

        treasury = ITreasury(_treasury);
    }


    /**
     * Deprecated in favour of harvestAll(address _token).
     */

    function harvest(address _token, uint256 _amount) external override {
        revert("Method is deprecated in favour of harvestAll(address _token)");
    }


    /**
     * @notice claims rewards from the vault.
     */

    function harvestAll(address _token) external override onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];

        // We only want to allow harvesting from a specified liquidity pool mapping
        require(stakingToken.exists, "Unsupported token");
        require(stakingToken.isLiquidityPool, "Must be liquidity staking token");

        // Send a request to the treasury to claim rewards from the NFTX liquidity staking pool
        treasury.claimNFTXRewards(
            address(liquidityStaking),
            stakingToken.vaultId,
            stakingToken.rewardToken
        );
    }


    /**
     * @notice sends any ERC20 token in the contract to caller.
     */

    function rescue(address _token) external override onlyGovernor {
        // If the token is known, then we shouldn't be able to rescue it
        require(!stakingTokenInfo[_token].exists, "Known token cannot be rescued");

        // Get the amount of token held on contract
        uint256 _amount = IERC20(_token).balanceOf(address(this));

        // Confirm that we hold some of the specified token
        require(_amount > 0, "Token not held in contract");

        // Send to Governor
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }


    /**
     * @notice There should be no rewards held in the allocator, but any dust has formed
     * then we can use this check to claim rewards to the allocator and transfer it
     * to the governor.
     * 
     * @param _token address Address of the staking token
     */

    function rescueRewards(address _token) external onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];

        // We only want to allow harvesting from a specified liquidity pool mapping
        require(stakingToken.exists, "Unsupported token");
        require(stakingToken.isLiquidityPool, "Must be liquidity staking token");

        INFTXLPStaking(address(liquidityStaking)).claimRewards(stakingToken.vaultId);

        uint256 rewardTokenBalance = IERC20(stakingToken.rewardToken).balanceOf(address(this));
        if (rewardTokenBalance > 0) {
            IERC20(stakingToken.rewardToken).safeTransfer(msg.sender, rewardTokenBalance);
        }
    }


    /**
     * @notice withdraws asset from treasury, deposits asset into NFTX staking.
     */

    function deposit(address _token, uint256 _amount) external override onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];
        address dividendToken = dividendTokenMapping[_token];

        require(stakingToken.exists, "Unsupported staking token");
        require(dividendToken != address(0), "Unsupported dividend token");

        // Ensure that a calculator exists for the `dividendToken`
        require(treasury.bondCalculator(dividendToken) != address(0), "Unsupported xToken calculator");

        // Retrieve amount of asset from treasury, decreasing total reserves
        treasury.allocatorManage(_token, _amount);

        uint256 value = treasury.tokenValue(_token, _amount);
        emit TreasuryAssetDeployed(_token, _amount, value);

        // Approve and deposit into inventory pool, returning xToken
        if (stakingToken.isLiquidityPool) {
            IERC20(_token).safeApprove(address(liquidityStaking), _amount);
            liquidityStaking.deposit(stakingToken.vaultId, _amount);
        } else {
            IERC20(_token).safeApprove(address(inventoryStaking), _amount);
            inventoryStaking.deposit(stakingToken.vaultId, _amount);
        }
    }

    /**
     * @notice Withdraws from staking pool, and deposits asset into treasury.
     */

    function withdraw(address _token, uint256 _amount) external override onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];
        address dividendToken = dividendTokenMapping[_token];

        require(stakingToken.exists, "Unsupported staking token");
        require(dividendToken != address(0), "Unsupported dividend token");

        // Retrieve amount of asset from treasury, decreasing total reserves
        treasury.allocatorManage(dividendToken, _amount);

        uint256 valueWithdrawn = treasury.tokenValue(dividendToken, _amount);
        emit TreasuryAssetDeployed(dividendToken, _amount, valueWithdrawn);

        // Approve and withdraw from staking pool, returning asset and potentially reward tokens
        if (stakingToken.isLiquidityPool) {
            IERC20(dividendToken).safeApprove(address(liquidityStaking), _amount);
            liquidityStaking.withdraw(stakingToken.vaultId, _amount);
        } else {
            IERC20(dividendToken).safeApprove(address(inventoryStaking), _amount);
            inventoryStaking.withdraw(stakingToken.vaultId, _amount); 
        }

        // Get the balance of the returned vToken or vTokenWeth
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 value = treasury.tokenValue(_token, balance);

        // Deposit the token back into the treasury, increasing total reserves and minting 0 FLOOR
        IERC20(_token).safeApprove(address(treasury), balance);
        treasury.deposit(balance, _token, value);

        emit TreasuryAssetReturned(_token, balance, value);
    }

    /**
     * @notice Staked positions return an xToken which should be regularly deposited
     * back into the Treasury to account for their value. This cannot be done
     * in the same transaction as `deposit()` because of a 2 second timelock in NFTX.
     */

    function depositXTokenToTreasury(address _token) external onlyGovernor {
        stakingTokenData memory stakingToken = stakingTokenInfo[_token];
        address dividendToken = dividendTokenMapping[_token];

        require(stakingToken.exists, "Unsupported staking token");
        require(dividendToken != address(0), "Unsupported dividend token");

        // Get the balance of the xToken
        uint256 balance = IERC20(dividendToken).balanceOf(address(this));
        uint256 value = treasury.tokenValue(dividendToken, balance);

        // Deposit the xToken back into the treasury, increasing total reserves and minting 0 FLOOR
        IERC20(dividendToken).safeApprove(address(treasury), balance);
        treasury.deposit(balance, dividendToken, value);

        emit TreasuryAssetReturned(dividendToken, balance, value);
    }

    /**
     * @notice adds asset and corresponding xToken to mapping
     */

    function setDividendToken(address _token, address _xToken) external override onlyGovernor {
        require(_token != address(0), "Token: Zero address");
        require(_xToken != address(0), "xToken: Zero address");

        dividendTokenMapping[_token] = _xToken;
    }


    /**
     * @notice remove xToken mapping
     */

    function removeDividendToken(address _token) external override onlyGovernor {
        delete dividendTokenMapping[_token];
    }


    /**
     * @notice set vault mapping
     */

    function setStakingToken(address _token, address _rewardToken, uint256 _vaultId, bool _isLiquidityPool) external override onlyGovernor {
        require(_token != address(0), "Cannot set vault for NULL token");

        // Set up our vault mapping information
        stakingTokenInfo[_token] = stakingTokenData({
            vaultId: _vaultId,
            isLiquidityPool: _isLiquidityPool,
            rewardToken: _rewardToken,
            exists: true
        });
    }


    /**
     * @notice remove vault mapping
     */

    function removeStakingToken(address _token) external override onlyGovernor {
        delete stakingTokenInfo[_token];
    }

}
