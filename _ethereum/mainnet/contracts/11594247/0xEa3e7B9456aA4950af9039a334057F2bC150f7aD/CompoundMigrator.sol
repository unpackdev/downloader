pragma solidity ^0.6.0;

import "./GasBurner.sol";
import "./ProxyPermission.sol";

import "./ILendingPool.sol";
import "./CTokenInterface.sol";

import "./CompoundSaverHelper.sol";
import "./CompoundProxies.sol";


/// @title Imports Compound position from the account to DSProxy
contract CompoundMigrator is CompoundSaverHelper, GasBurner, ProxyPermission {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
    address public constant compoundProxies = 0x54e72304286b952b2D67f59B5b2E05F8153246f1;

    function importLoan(address _cCollateralToken, address _cBorrowToken, address _compoundImportFlashLoan) external burnGas(20) {
        address user = CompoundProxies(compoundProxies).proxiesUser(address(this));

        uint loanAmount = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(user);
        bytes memory paramsData = abi.encode(_cCollateralToken, _cBorrowToken, user, address(this));

        givePermission(_compoundImportFlashLoan);

        lendingPool.flashLoan(payable(_compoundImportFlashLoan), getUnderlyingAddr(_cBorrowToken), loanAmount, paramsData);

        removePermission(_compoundImportFlashLoan);
    }
}