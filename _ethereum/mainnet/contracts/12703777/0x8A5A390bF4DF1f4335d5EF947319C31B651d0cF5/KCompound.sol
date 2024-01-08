// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./IKCompound.sol";
import "./LibCompound.sol";

/**
 * @title Compound plugin for the HidingVault
 * @author KeeperDAO
 * @dev This is the contract logic for the HidingVault compound plugin.
 *  
 * This contract holds the compound position account details for the users, and allows 
 * users to manage their compound positions by depositing, withdrawing funds, repaying  
 * existing loans and borrowing.
 * 
 * This contract allows JITU to underwrite loans that are close to getting liquidated so that 
 * only friendly keepers can liquidate the position, resulting in lower liquidation fees to 
 * the user. Once a position is either liquidated or comes back to a safe LTV (Loan-To-Value)
 * ratio JITU should claim back the assets provided to underwrite the loan.
 * 
 * To migrate an existing compound position we flash lend cTokens greater than the total 
 * existing compound position value, borrow all the assets that are currently borrowed by the        
 * user and repay the user's loans. Once all the loans are repaid transfer over the assets from the 
 * user, then repay the ETH flash loan borrowed in the beginning. `migrate()` function is used by 
 * the user to migrate a compound  position over. The user has to approve all the cTokens he owns 
 * to this contract before calling the `migrate()` function.        
 */
contract KCompound is IKCompound {
    using LibCToken for CToken;

    address constant JITU = 0x8AeA7B58409B4124cBc92dA298C9b2AAFA605B4c;

    /**
     * @dev revert if the caller is not JITU
     */
    modifier onlyJITU() {
        require(msg.sender == JITU, "KCompoundPosition: caller is not the MEV protector");
        _;
    }

    /**
     * @dev revert if the caller is not the owner
     */
    modifier onlyOwner() {
        require(msg.sender == LibCompound.owner(), "KCompoundPosition: caller is not the owner");
        _;
    }
    
    /**
     * @dev revert if the position is underwritten
     */
    modifier whenNotUnderwritten() {
        require(!compound_isUnderwritten(), "LibCompound: operation not allowed when underwritten");
        _;
    }

    /**
     * @dev revert if the position is not underwritten
     */
    modifier whenUnderwritten() {
        require(compound_isUnderwritten(), "LibCompound: operation not allowed when underwritten");
        _;
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_deposit(CToken _cToken, uint256 _amount) external payable override {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.pullAndApproveUnderlying(msg.sender, address(_cToken), _amount);
        _cToken.mint(_amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_withdraw(address payable _to, CToken _cToken, uint256 _amount) external override onlyOwner whenNotUnderwritten {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.redeemUnderlying(_amount);
        _cToken.transferUnderlying(_to, _amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_borrow(address payable _to, CToken _cToken, uint256 _amount) external override onlyOwner whenNotUnderwritten {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.borrow(_amount);
        _cToken.transferUnderlying(_to, _amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_repay(CToken _cToken, uint256 _amount) external payable override {
        require(_cToken.isListed(), "KCompound: unsupported cToken address");
        _cToken.pullAndApproveUnderlying(msg.sender, address(_cToken), _amount);
        _cToken.repayBorrow(_amount);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_preempt(
        address _liquidator,
        CToken _cTokenRepay,
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external payable override onlyJITU returns (uint256) {
        return LibCompound.preempt(_cTokenRepay, _liquidator, _repayAmount, _cTokenCollateral);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_migrate(
        address _account, 
        uint256 _amount, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external override onlyJITU {
        LibCompound.migrate(
            _account,
            _amount,
            _collateralMarkets,
            _debtMarkets
        );
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_underwrite(CToken _cToken, uint256 _tokens) external payable override onlyJITU whenNotUnderwritten {    
        LibCompound.underwrite(_cToken, _tokens);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_reclaim() external override onlyJITU whenUnderwritten {
        LibCompound.reclaim();
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_enterMarkets(address[] memory _markets) external override onlyOwner {
        LibCompound.enterMarkets(_markets);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_balanceOfUnderlying(CToken _cToken) external override returns (uint256) {
        return LibCompound.balanceOfUnderlying(_cToken);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_balanceOf(CToken _cToken) external view override returns (uint256) {
        return LibCompound.balanceOf(_cToken);
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_unhealth() external override view returns (uint256) {
        return LibCompound.unhealth();
    }

    /**
     * @inheritdoc IKCompound
     */
    function compound_isUnderwritten() public override view returns (bool) {
        return LibCompound.isUnderwritten();
    }
}