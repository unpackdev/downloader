// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./LibCToken.sol";
import "./IJITUCompound.sol";
import "./JITUCore.sol";

/**
 * @title Compound extension for JITU (Just-In-Time-Underwriter)
 * @author KeeperDAO
 * @notice This contract allows whitelisted keepers to add buffer to compound positions that 
 * are slightly above water, so that in the case they go underwater the keepers can
 * preempt a liquidation.
 */
contract JITUCompound is JITUCore, IJITUCompound {
    using LibCToken for CToken;
    using SafeERC20 for IERC20;

    mapping (address=>bool) public unprotected;

    /** Events */
    event Underwritten(
        address indexed _vault,
        address indexed _underwriter, 
        address indexed _token, 
        uint256 _amount
    );
    event Reclaimed(address indexed _vault, address indexed _underwriter);
    event Repaid(address indexed _vault);
    event Preempted(
        address indexed _vault, 
        address indexed _keeper, 
        address _repayToken, 
        uint256 _repayAmount, 
        address _collateralToken,
        uint256 _seizedAmount
    );
    event ProtectionRemoved(address indexed _vault);
    event ProtectionAdded(address indexed _vault);

    /**
     * @notice initialize the contract state
     */
    constructor (LiquidityPoolLike _liquidityPool, IERC721 _nft) JITUCore(_liquidityPool, _nft) {}

    /** External override Functions */

    /**
     * @inheritdoc IJITUCompound
     */
    function borrow(CToken _cToken, uint256 _amount) external override onlyOwner {
        require(_cToken.isListed(), "JITUCompound: unsupported cToken address");
        liquidityPool.adapterBorrow(
                _cToken.underlying(),
                _amount,
                abi.encodeWithSelector(this.borrowCallback.selector, _cToken, _amount)
            );
    }

    /** 
     * @dev this function should only be called by the BorrowerProxy.
     * @dev expects the LiquidityPool contract to transfer ERC20 tokens before
     * calling this function (this is validated during _cToken.mint(...)). 
     * @dev expects the LiqudityPool contract to set msg.value = _amount, (this 
     * is validated during _cToken.mint(...))
     *
     * @param _cToken the address of the cToken
     * @param _amount the amount of underlying tokens
     */
    function borrowCallback(CToken _cToken, uint256 _amount) external payable {
        require(msg.sender == liquidityPool.borrower(), 
            "JITUCompound: unsupported cToken address");
        _deposit(_cToken, _amount);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function repay(CToken _cToken, uint256 _amount) external override payable onlyOwner {
        _cToken.redeemUnderlying(_amount);
        _cToken.approveUnderlying(address(liquidityPool), _amount);
        if (address(_cToken) == address(LibCToken.CETHER)) {
            liquidityPool.adapterRepay{ value: _amount }(address(this), _cToken.underlying(), _amount);
        } else {
            liquidityPool.adapterRepay(address(this), _cToken.underlying(), _amount);
        }
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function underwrite(address _vault, CToken _cToken, uint256 _tokens) 
        external override valid(_vault) onlyWhitelistedUnderwriter {
        require(!unprotected[_vault], "JITUCompound: unprotected vault");
        require(_cToken.isListed(), "JITUCompound: unsupported cToken address");
        require(_cToken.transfer(_vault, _tokens), "JITUCompound: failed to transfer cTokens");
        IKCompound(_vault).compound_underwrite(_cToken, _tokens);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function reclaim(address _vault) external override valid(_vault) 
        onlyWhitelistedUnderwriter {  
        IKCompound(_vault).compound_reclaim();
        emit Reclaimed(_vault, msg.sender);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function removeProtection(address _vault, bool _permanent) external override onlyVaultOwner(_vault) {  
        unprotected[_vault] = _permanent;
        IKCompound(_vault).compound_reclaim();
        emit ProtectionRemoved(_vault);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function protect(address _vault) external override onlyVaultOwner(_vault) {  
        unprotected[_vault] = false;
        emit ProtectionAdded(_vault);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function withdrawCOMP(address _to, uint256 _amount) external override onlyOwner {
        IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888).safeTransfer(_to, _amount);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function migrate(
        IKCompound _vault,
        address _account, 
        uint256 _tokens, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external override onlyVaultOwner(address(_vault)) {
        CToken cToken = CToken(_collateralMarkets[0]);
        require(cToken.isListed(), "JITUCompound: unsupported cToken address"); 
        require(
            cToken.transfer(address(_vault), _tokens), 
            "JITUCompound: failed to transfer cTokens"
        );
        _vault.compound_migrate(_account, _tokens, _collateralMarkets, _debtMarkets);
    }

    /**
     * @inheritdoc IJITUCompound
     */
    function preempt(
        address _vault, 
        CToken _cTokenRepaid, 
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external override payable valid(_vault) onlyWhitelistedKeeper returns (uint256) {
        require(_cTokenRepaid.isListed(), "KCompound: invalid _cTokenRepaid address");
        require(_cTokenCollateral.isListed(), "KCompound: invalid _cTokenCollateral address");
        uint256 seizedAmount = IKCompound(_vault).compound_preempt{ value: msg.value }(
            msg.sender, 
            _cTokenRepaid, 
            _repayAmount, 
            _cTokenCollateral
        );
        emit Preempted(
            address(_vault), 
            msg.sender, 
            address(_cTokenRepaid), 
            _repayAmount, 
            address(_cTokenCollateral),
            seizedAmount
        );
        return seizedAmount;
    }

    /** Internal Functions */
    function _deposit(CToken _cToken, uint256 _amount) internal {
        _cToken.approveUnderlying(address(_cToken), _amount);
        _cToken.mint(_amount);
    }
}