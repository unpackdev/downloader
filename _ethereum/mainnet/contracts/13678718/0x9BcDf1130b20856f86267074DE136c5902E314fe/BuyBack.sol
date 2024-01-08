// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Errors.sol";
import "./IAddressListFactory.sol";
import "./IVesperPool.sol";
import "./UsingSwapManager.sol";
import "./Batchable.sol";

contract BuyBack is UsingSwapManager, Batchable {
    using SafeERC20 for IERC20;

    IERC20 public vsp;
    IVesperPool public vVSP; // vVSP pool will received buyed back VSPs
    address public keepers; // sol-address-list address which contains addresses of keepers

    event MigratedAsset(IERC20 asset, uint256 amount);

    constructor(
        address _governor,
        address _weth,
        IVesperPool _vVSP,
        IAddressListFactory _listFactory,
        ISwapManager _swapManager
    ) UsingSwapManager(_weth, _swapManager) {
        require(address(_vVSP) != address(0), "vvsp-is-null");
        require(address(_listFactory) != address(0), "address-list-factory-is-null");

        governor = _governor;
        vVSP = _vVSP;
        vsp = vVSP.token();
        keepers = _listFactory.createList();
        require(IAddressList(keepers).add(_msgSender()), Errors.ADD_IN_LIST_FAILED);
    }

    modifier onlyKeeper() {
        require(IAddressList(keepers).contains(_msgSender()), "not-a-keeper");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Migrate assets to a new contract
     * @dev The caller has to set the addresses list since we don't maintain a list of them
     * @param _assets List of assets' address to transfer from
     * @param _to Assets recipient
     */
    function migrateAssets(address[] memory _assets, address _to) external onlyGovernor {
        require(_assets.length > 0, "assets-list-is-empty");
        require(_to != address(this), "new-contract-is-invalid");

        for (uint256 i = 0; i < _assets.length; ++i) {
            IERC20 _asset = IERC20(_assets[i]);
            uint256 _balance = _asset.balanceOf(address(this));
            _asset.safeTransfer(_to, _balance);
            emit MigratedAsset(_asset, _balance);
        }
    }

    ///////////////////////////// Only Keeper ///////////////////////////////

    /// @notice Perform a slippage-protected swap for VSP
    /// @dev The vVVSP is the beneficiary of the swap
    /// @dev Have to check allowance to routers before calling this
    function swapForVspAndTransferToVVSP(address _tokenIn, uint256 _amountIn) external onlyKeeper {
        if (_amountIn > 0) {
            uint256 _minAmtOut =
                (swapSlippage != 10000)
                    ? _calcAmtOutAfterSlippage(
                        _getOracleRate(_simpleOraclePath(_tokenIn, address(vsp)), _amountIn),
                        swapSlippage
                    )
                    : 1;
            _safeSwap(_tokenIn, address(vsp), _amountIn, _minAmtOut, address(vVSP));
        }
    }

    /// @notice Deposit vPool tokens and unwrap them
    function depositAndUnwrap(IVesperPool _vPool, uint256 _amount) external onlyKeeper {
        _vPool.transferFrom(_msgSender(), address(this), _amount);
        _vPool.withdraw(_amount);
    }

    /// @notice Withdraw (a.k.a. unwrap) underlying token from vPool
    function unwrap(IVesperPool _vPool, uint256 _amount) public onlyKeeper {
        _vPool.withdraw(_amount);
    }

    /// @notice Withdraw (a.k.a. unwrap) underlying token from vPool
    /// @dev Uses all held vPool tokens
    function unwrapAll(IVesperPool _vPool) external onlyKeeper {
        unwrap(_vPool, _vPool.balanceOf(address(this)));
    }

    /// @notice Transfer VSP tokens to vVSP
    function transferVspToVVSP(uint256 _amount) public onlyKeeper {
        vsp.safeTransfer(address(vVSP), _amount);
    }

    /// @notice Transfer VSP tokens to vVSP
    /// @dev Uses all held VSP tokens
    function transferAllVspToVVSP() external onlyKeeper {
        transferVspToVVSP(vsp.balanceOf(address(this)));
    }

    /// @notice Approve SwapManager routers if needed
    function doInfinityApproval(IERC20 _unwrapped) external onlyKeeper {
        _doInfinityApprovalIfNeeded(_unwrapped, type(uint256).max);
    }

    /**
     * @notice Add given address in provided address list.
     * @dev Use it to add keeper in keepers list and to add address in feeWhitelist
     * @param _addressToAdd address which we want to add in AddressList.
     */
    function addInKeepersList(address _addressToAdd) external onlyKeeper {
        require(IAddressList(keepers).add(_addressToAdd), Errors.ADD_IN_LIST_FAILED);
    }

    /**
     * @notice Remove given address from provided address list.
     * @dev Use it to remove keeper from keepers list and to remove address from feeWhitelist
     * @param _addressToRemove address which we want to remove from AddressList.
     */
    function removeFromKeepersList(address _addressToRemove) external onlyKeeper {
        require(IAddressList(keepers).remove(_addressToRemove), Errors.REMOVE_FROM_LIST_FAILED);
    }

    ///////////////////////////////////////////////////////////////////////////
}
