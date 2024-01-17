/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IACL.sol";
import "./IAddressProvider.sol";
import "./IContractsRegister.sol";
import "./IAccountFactory.sol";
import "./IDataCompressor.sol";
import "./IPoolService.sol";
import "./IWETH.sol";
import "./IWETHGateway.sol";
import "./IPriceOracle.sol";
import "./ICreditFacade.sol";
import "./ICreditManagerV2.sol";
import "./ICreditAccount.sol";

// import "./IWETHGateway.sol";
// import "./IWETHGateway.sol";

contract GearboxRegistry {
    IERC20 public FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public STETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IERC20 public WSTETH = IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public CURVE_STETH_GATEWAY =
        0xEf0D72C594b28252BF7Ea2bfbF098792430815b1;
    address public UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public LIDO_STETH_GATEWAY =
        0x6f4b4aB5142787c05b7aB9A9692A0f46b997C29D;

    address internal _addressProvider =
        0xcF64698AFF7E5f27A11dff868AF228653ba53be0;
    address internal _wethCreditManager =
        0x5887ad4Cb2352E7F01527035fAa3AE0Ef2cE2b9B;

    constructor(address ap, address cm) {
        _setAddressProvider(ap);
        _setCreditManager(cm);
    }

    function adapter(address _allowedContract) public view returns (address) {
        return
            dataCompressor().getAdapter(
                address(creditManager()),
                _allowedContract
            );
    }

    function addressProvider() public view returns (IAddressProvider) {
        return IAddressProvider(_addressProvider);
    }

    function creditManager() public view returns (ICreditManagerV2) {
        return ICreditManagerV2(_wethCreditManager);
    }

    function creditAccount() public view returns (ICreditAccount) {
        return ICreditAccount(creditManager().creditAccounts(address(this)));
    }

    function acl() public view returns (IACL) {
        return IACL(addressProvider().getACL());
    }

    function contractsRegister() public view returns (IContractsRegister) {
        return IContractsRegister(addressProvider().getContractsRegister());
    }

    function accountFactory() public view returns (IAccountFactory) {
        return IAccountFactory(addressProvider().getAccountFactory());
    }

    function dataCompressor() public view returns (IDataCompressor) {
        return IDataCompressor(addressProvider().getDataCompressor());
    }

    function poolService() public view returns (IPoolService) {
        return IPoolService(creditManager().pool());
    }

    function gearToken() public view returns (IERC20) {
        return IERC20(addressProvider().getGearToken());
    }

    function weth() public view returns (IERC20) {
        return IERC20(addressProvider().getWethToken());
    }

    function wethGateway() public view returns (IWETHGateway) {
        return IWETHGateway(addressProvider().getWETHGateway());
    }

    function priceOracle() public view returns (IPriceOracleV2) {
        return IPriceOracleV2(addressProvider().getPriceOracle());
    }

    function creditFacade() public view returns (ICreditFacade) {
        return ICreditFacade(creditManager().creditFacade());
    }

    /// @dev Do not expose this method externally, discard the TE if this needs to be changed
    function _setAddressProvider(address ap) internal {
        _addressProvider = ap;
    }

    /// @dev Do not expose this method externally, discard the TE if this needs to be changed
    function _setCreditManager(address cm) internal {
        _wethCreditManager = cm;
    }

    function _setCurveStETHGateway(address gateway) internal {
        CURVE_STETH_GATEWAY = gateway;
    }
}
