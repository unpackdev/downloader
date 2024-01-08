// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./LibCToken.sol";
import "./LibHidingVault.sol";

/**
 * @title Buffer accounting library for KCompound
 * @author KeeperDAO
 * @dev This library handles existing compound position migration.
 * @dev This library implements all the logic for the individual kCompound
 *      position contracts.
 */
library LibCompound {
    using LibCToken for CToken;

    //  KCOMPOUND_STORAGE_POSITION = keccak256("keeperdao.hiding-vault.compound.storage")
    bytes32 constant KCOMPOUND_STORAGE_POSITION = 0x4f39ec42b5bbf77786567b02cbf043f85f0f917cbaa97d8df56931d77a999205;

    /**
     * State for LibCompound 
     */
    struct State {
        uint256 bufferAmount;
        CToken bufferToken;
    }

    /**
     * @notice Load the LibCompound State for the given user
     */
    function state() internal pure returns (State storage s) {
        bytes32 position = KCOMPOUND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /**
     * @dev this function will be called by the KeeperDAO's LiquidityPool.
     * @param _account The address of the compund position owner.
     * @param _tokens The amount that is being flash lent.
     */
    function migrate(
        address _account, 
        uint256 _tokens, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) internal {
        // Enter markets
        enterMarkets(_collateralMarkets);

        // Migrate all the cToken Loans.
        if (_debtMarkets.length != 0) migrateLoans(_debtMarkets, _account);

        // Migrate all the assets from compound.
        if (_collateralMarkets.length != 0) migrateFunds(_collateralMarkets, _account);
        
        // repay CETHER
        require(
            CToken(_collateralMarkets[0]).transfer(msg.sender, _tokens), 
            "LibCompound: failed to return funds during migration"
        );
    }

    /**
     * @notice this function borrows required amount of ETH/ERC20 tokens,  
     * repays the ETH/ERC20 loan (if it exists) on behalf of the  
     * compound position owner.
     */
    function migrateLoans(address[] memory _cTokens, address _account) private {
        for (uint32 i = 0; i < _cTokens.length; i++) {
            CToken cToken = CToken(_cTokens[i]);
            uint256 borrowBalance = cToken.borrowBalanceCurrent(_account);
            cToken.borrow(borrowBalance);
            cToken.approveUnderlying(address(cToken), borrowBalance);
            cToken.repayBorrowBehalf(_account, borrowBalance);
        }
    }

    /**
     * @notice transfer all the assets from the account.
     */
    function migrateFunds(address[] memory _cTokens, address _account) private {
        for (uint32 i = 0; i < _cTokens.length; i++) {
            CToken cToken = CToken(_cTokens[i]);
            require(cToken.transferFrom(
                _account, 
                address(this), 
                cToken.balanceOf(_account)
            ), "LibCompound: failed to transfer CETHER");       
        }
    }

    /**
     * @notice Prempt liquidation for positions underwater if the provided 
     *         buffer is not considered on the Compound Protocol.
     *
     * @param _liquidator The address of the liquidator.
     * @param _cTokenRepaid The repay cToken address.
     * @param _repayAmount The amount that should be repaid.
     * @param _cTokenCollateral The collateral cToken address.
     */    
    function preempt(
        CToken _cTokenRepaid,
        address _liquidator,
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) internal returns (uint256) {
        // Check whether the user's position is liquidatable, and if it is
        // return the amount of tokens that can be seized for the given loan,
        // token pair.
        uint seizeTokens = seizeTokenAmount(
            address(_cTokenRepaid), 
            address(_cTokenCollateral), 
            _repayAmount
        );

        // This is a preemptive liquidation, so it would just repay the given loan
        // and seize the corresponding amount of tokens.
        _cTokenRepaid.pullAndApproveUnderlying(_liquidator, address(_cTokenRepaid), _repayAmount);
        _cTokenRepaid.repayBorrow(_repayAmount);
        require(_cTokenCollateral.transfer(_liquidator, seizeTokens), "LibCompound: failed to transfer cTokens");
        return seizeTokens;
    }

    /**
     * @notice Allows JITU to underwrite this contract, by providing cTokens.
     *
     * @param _cToken The address of the token.
     * @param _tokens The tokens being transferred.
     */
    function underwrite(CToken _cToken, uint256 _tokens) internal { 
        require(_tokens * 3 <= _cToken.balanceOf(address(this)), 
            "LibCompound: underwrite pre-conditions not met");
        State storage s = state();
        s.bufferToken = _cToken;
        s.bufferAmount = _tokens;
        blacklistCTokens();
    }

    /**
     * @notice Allows JITU to reclaim the cTokens it provided.
     */
    function reclaim() internal {
        State storage s = state();
        require(s.bufferToken.transfer(msg.sender, s.bufferAmount), "LibCompound: failed to return cTokens");
        s.bufferToken = CToken(address(0));
        s.bufferAmount = 0;
        whitelistCTokens();
    }

    /**
     * @notice Blacklist all the collateral assets.
     */
    function blacklistCTokens() internal {
        address[] memory cTokens = LibCToken.COMPTROLLER.getAssetsIn(address(this));
        for (uint32 i = 0; i < cTokens.length; i++) {
            LibHidingVault.state().recoverableTokensBlacklist[cTokens[i]] = true;
        }
    }

    /**
     * @notice Whitelist all the collateral assets.
     */
    function whitelistCTokens() internal {
        address[] memory cTokens = LibCToken.COMPTROLLER.getAssetsIn(address(this));
        for (uint32 i = 0; i < cTokens.length; i++) {
            LibHidingVault.state().recoverableTokensBlacklist[cTokens[i]] = false;
        }
    }

    /**
     * @notice check whether the position is liquidatable, 
     *         if it is calculate the amount of tokens 
     *         that can be seized.
     *
     * @param cTokenRepaid the token that is being repaid.
     * @param cTokenSeized the token that is being seized.
     * @param repayAmount the amount being repaid.
     *
     * @return the amount of tokens that need to be seized.
     */
    function seizeTokenAmount(
        address cTokenRepaid,
        address cTokenSeized,
        uint repayAmount
    ) internal returns (uint) {
        State storage s = state();

        // accrue interest
        require(CToken(cTokenRepaid).accrueInterest() == 0, "LibCompound: failed to accrue interest on cTokenRepaid");
        require(CToken(cTokenSeized).accrueInterest() == 0, "LibCompound: failed to accrue interest on cTokenSeized");

        // The borrower must have shortfall in order to be liquidatable
        (uint err, , uint shortfall) = LibCToken.COMPTROLLER.getHypotheticalAccountLiquidity(address(this), address(s.bufferToken), s.bufferAmount, 0);
        require(err == 0, "LibCompound: failed to get account liquidity");
        require(shortfall != 0, "LibCompound: insufficient shortfall to liquidate");

        // The liquidator may not repay more than what is allowed by the closeFactor 
        uint borrowBalance = CToken(cTokenRepaid).borrowBalanceStored(address(this));
        uint maxClose = mulScalarTruncate(LibCToken.COMPTROLLER.closeFactorMantissa(), borrowBalance);
        require(repayAmount <= maxClose, "LibCompound: repay amount cannot exceed the max close amount");

        // Calculate the amount of tokens that can be seized
        (uint errCode2, uint seizeTokens) = LibCToken.COMPTROLLER
            .liquidateCalculateSeizeTokens(cTokenRepaid, cTokenSeized, repayAmount);
        require(errCode2 == 0, "LibCompound: failed to calculate seize token amount");

        // Check that the amount of tokens being seized is less than the user's 
        // cToken balance
        uint256 seizeTokenCollateral = CToken(cTokenSeized).balanceOf(address(this));
        if (cTokenSeized == address(s.bufferToken)) {
            seizeTokenCollateral = seizeTokenCollateral - s.bufferAmount;
        }
        require(seizeTokenCollateral >= seizeTokens, "LibCompound: insufficient liquidity");

        return seizeTokens;
    }

    /**
     * @notice calculates the collateral value of the given cToken amount. 
     * @dev collateral value means the amount of loan that can be taken without 
     *      falling below the collateral requirement.
     *
     * @param _cToken the compound token we are calculating the collateral for.
     * @param _tokens number of compound tokens.
     *
     * @return max borrow value for the given compound tokens in USD.
     */
    function collateralValueInUSD(CToken _cToken, uint256 _tokens) internal view returns (uint256) {
        // read the exchange rate from the cToken
        uint256 exchangeRate = _cToken.exchangeRateStored();

        // read the collateralFactor from the LibCToken.COMPTROLLER
        (, uint256 collateralFactor, ) = LibCToken.COMPTROLLER.markets(address(_cToken));

        // read the underlying token prive from the Compound's oracle
        uint256 oraclePrice = LibCToken.COMPTROLLER.oracle().getUnderlyingPrice(_cToken);
        require(oraclePrice != 0, "LibCompound: failed to get underlying price from the oracle");

        return mulExp3AndScalarTruncate(collateralFactor, exchangeRate, oraclePrice, _tokens);
    }

    /**
     * @notice Calculate the given cToken's underlying token balance of the caller.
     *
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance in the given token.
     */
    function balanceOfUnderlying(CToken _cToken) internal returns (uint256) {
        return mulScalarTruncate(_cToken.exchangeRateCurrent(), balanceOf(_cToken));
    } 

    /**
     * @notice Calculate the given cToken's balance of the caller.
     *
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function balanceOf(CToken _cToken) internal view returns (uint256) {
        State storage s = state();
        uint256 cTokenBalance = _cToken.balanceOf(address(this));
        if (s.bufferToken == _cToken) {
            cTokenBalance -= s.bufferAmount;
        }
        return cTokenBalance;
    } 

    /**
     * @notice new markets can be entered by calling this function.
     */
    function enterMarkets(address[] memory _cTokens) internal {
        uint[] memory retVals = LibCToken.COMPTROLLER.enterMarkets(_cTokens);
        for (uint i; i < retVals.length; i++) {
            require(retVals[i] == 0, "LibCompound: failed to enter market");
        }
    }

    /**
     * @notice existing markets can be exited by calling this function
     */
    function exitMarket(address _cToken) internal {
        require(
            LibCToken.COMPTROLLER.exitMarket(_cToken) == 0, 
            "LibCompound: failed to exit a market"
        );
    }

    /**
     * @notice unhealth of the given account, the position is underwater 
     * if this value is greater than 100
     * @dev if the account is empty, this fn returns an unhealth of 0
     *
     * @return unhealth of the account 
     */
    function unhealth() internal view returns (uint256) {
        uint256 totalCollateralValue;
        State storage s = state();

        address[] memory cTokens = LibCToken.COMPTROLLER.getAssetsIn(address(this));
        // calculate the total collateral value of this account
        for (uint i = 0; i < cTokens.length; i++) {
            totalCollateralValue = totalCollateralValue + collateralValue(CToken(cTokens[i]));
        }
        if (totalCollateralValue > 0) {
            uint256 totalBorrowValue;

            // get the account liquidity
            (uint err, uint256 liquidity, uint256 shortFall) = 
                LibCToken.COMPTROLLER.getHypotheticalAccountLiquidity(
                    address(this),
                    address(s.bufferToken),
                    s.bufferAmount,
                    0
                );
            require(err == 0, "LibCompound: failed to calculate account liquidity");

            if (liquidity == 0) {
                totalBorrowValue = totalCollateralValue + shortFall;
            } else {
                totalBorrowValue = totalCollateralValue - liquidity;
            }

            return (totalBorrowValue * 100) / totalCollateralValue;
        }
        return 0;
    }

    /**
     * @notice calculate the collateral value of the given cToken
     *
     * @return collateral value of the given cToken
     */
    function collateralValue(CToken cToken) internal view returns (uint256) {
        State storage s = state();
        uint256 bufferAmount;
        if (s.bufferToken == cToken) {
            bufferAmount = s.bufferAmount;
        }
        return collateralValueInUSD(
            cToken, 
            cToken.balanceOf(address(this)) - bufferAmount
        );
    }

    /**
     * @notice checks whether the given position is underwritten or not
     *
     * @return underwritten status of the caller
     */
    function isUnderwritten() internal view returns (bool) {
        State storage s = state();
        return (s.bufferAmount != 0 && s.bufferToken != CToken(address(0)));
    }

    /**
     * @notice checks the owner of this vault
     *
     * @return address of the owner
     */
    function owner() internal view returns (address) {
        return LibHidingVault.state().nft.ownerOf(uint256(uint160(address(this))));
    }

    /** Exponential Math */
    function mulExp3AndScalarTruncate(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256) {
        return mulScalarTruncate(mulExp(mulExp(a, b), c), d);
    }

    function mulExp(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a * _b + 5e17) / 1e18;
    }

    function mulScalarTruncate(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a * _b) / 1e18;
    }
}

interface Weth {
    function balanceOf(address owner) external view returns (uint);
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address spender, uint256 amount) external returns (bool);
}

interface NFT {
    function jitu() external view returns (address);
    function ownerOf(uint256 _tokenID) external view returns (address);
}