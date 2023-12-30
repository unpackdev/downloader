pragma solidity ^0.6.0;

import "./MCDSaverProxy.sol";
import "./ConstantAddresses.sol";
import "./FlashLoanLogger.sol";


abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
}

contract AutomaticProxyV2 is MCDSaverProxy {

    address payable public constant MCD_SAVER_FLASH_LOAN = 0xCcFb21Ced87762a1d8425F867a7F8Ec2dFfaBE92;
    address public constant AAVE_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    function automaticBoost(
        uint[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable {
        uint256 maxDebt = getMaxDebt(_data[0], manager.ilks(_data[0]));
        uint256 debtAmount = _data[1];

        if (maxDebt >= debtAmount) {
            boost(_data, _joinAddr, _exchangeAddress, _callData);
            return;
        }

        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        uint256 loanAmount = sub(debtAmount, maxDebt);
        uint maxLiq = getAvailableLiquidity(_joinAddr);

        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(_data, _joinAddr, _exchangeAddress, _callData, false);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, DAI_ADDRESS, loanAmount, paramsData);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 0);

        logger.logFlashLoan("AutomaticBoost", loanAmount, _data[0], msg.sender);
    }

    function automaticRepay(
        uint256[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable {
        uint collAmount = _data[1];
        uint256 maxColl = getMaxCollateral(_data[0], manager.ilks(_data[0]));

        if (maxColl >= collAmount) {
            repay(_data, _joinAddr, _exchangeAddress, _callData);
            return;
        }

        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        uint256 loanAmount = sub(_data[1], maxColl);
        uint maxLiq = getAvailableLiquidity(_joinAddr);

        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(_data, _joinAddr, _exchangeAddress, _callData, true);
        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, getAaveCollAddr(_joinAddr), loanAmount, paramsData);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 0);

        logger.logFlashLoan("AutomaticRepay", loanAmount, _data[0], msg.sender);
    }


    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(uint256 _cdpId, bytes32 _ilk) public override view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    /// @notice Gets the maximum amount of collateral available to draw
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxCollateral(uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint price = getPrice(_ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        (, uint mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);

        return sub(sub(collateral, (div(mul(mat, debt), price))), 10);
    }

    function getAaveCollAddr(address _joinAddr) internal returns (address) {
        if (_joinAddr == 0x2F0b23f53734252Bda2277357e97e1517d6B042A
            || _joinAddr == 0x775787933e92b709f2a3C70aa87999696e74A9F8) {
            return KYBER_ETH_ADDRESS;
        } else {
            return getCollateralAddr(_joinAddr);
        }
    }

    function getAvailableLiquidity(address _joinAddr) internal returns (uint liquidity) {
        address tokenAddr = getAaveCollAddr(_joinAddr);

        if (tokenAddr == KYBER_ETH_ADDRESS) {
            liquidity = AAVE_POOL_CORE.balance;
        } else {
            liquidity = ERC20(tokenAddr).balanceOf(AAVE_POOL_CORE);
        }
    }

}
