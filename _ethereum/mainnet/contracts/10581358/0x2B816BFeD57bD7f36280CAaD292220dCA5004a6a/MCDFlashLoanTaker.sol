pragma solidity ^0.6.0;

import "./MCDSaverProxy.sol";
import "./ConstantAddresses.sol";
import "./FlashLoanLogger.sol";
import "./ILendingPool.sol";

abstract contract IMCDSubscriptions {
    function unsubscribe(uint256 _cdpId) external virtual ;

    function subscribersPos(uint256 _cdpId) external virtual returns (uint256, bool);
}


contract MCDFlashLoanTaker is ConstantAddresses, SaverProxyHelper {

    address payable public constant MCD_SAVER_FLASH_LOAN = 0xCcFb21Ced87762a1d8425F867a7F8Ec2dFfaBE92;
    address payable public constant MCD_CLOSE_FLASH_LOAN = 0xfCF3e72445D105c38C0fDC1a0687BDEeb8947a93;
    address payable public constant MCD_OPEN_FLASH_LOAN = 0x86E132932566fb7030eeF19B997C8797De13CFBD;

    address public constant SUBSCRIPTION_ADDRESS_NEW = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;

    bytes32 public constant USDC_ILK = 0x555344432d410000000000000000000000000000000000000000000000000000;

    address public constant AAVE_DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address public constant MCD_CLOSE_FLASH_PROXY = 0xF6195D8d254bEF755fA8232D55Bb54B3b3eCf0Ce;
    // address payable public constant MCD_OPEN_FLASH_PROXY = 0x22e37Df56cAFc7f33e9438751dff42DbD5CB8Ed6;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(MANAGER_ADDRESS);
    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    // solhint-disable-next-line const-name-snakecase
    Vat public constant vat = Vat(VAT_ADDRESS);
    // solhint-disable-next-line const-name-snakecase
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    function boostWithLoan(
        uint[6] memory _data, // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable {
        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        uint256 maxDebt = getMaxDebt(_data[0], manager.ilks(_data[0]));
        uint256 debtAmount = _data[1];

        require(debtAmount >= maxDebt, "Amount to small for flash loan use CDP balance instead");

        uint256 loanAmount = sub(debtAmount, maxDebt);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(_data, _joinAddr, _exchangeAddress, _callData, false);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, AAVE_DAI_ADDRESS, loanAmount, paramsData);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 0);

        logger.logFlashLoan("Boost", loanAmount, _data[0], msg.sender);
    }

    function repayWithLoan(
        uint256[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData
    ) public payable {
        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        uint256 maxColl = getMaxCollateral(_data[0], manager.ilks(_data[0]), _joinAddr);

        uint256 loanAmount = sub(_data[1], maxColl);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(_data, _joinAddr, _exchangeAddress, _callData, true);
        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, getAaveCollAddr(_joinAddr), loanAmount, paramsData);

        manager.cdpAllow(_data[0], MCD_SAVER_FLASH_LOAN, 0);

        logger.logFlashLoan("Repay", loanAmount, _data[0], msg.sender);
    }

    function closeWithLoan(
        uint256[6] memory _data,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        uint256 _minCollateral
    ) public payable {
        MCD_CLOSE_FLASH_LOAN.transfer(msg.value); // 0x fee

        bytes32 ilk = manager.ilks(_data[0]);

        uint256 maxDebt = getMaxDebt(_data[0], ilk);

        (uint256 collateral, ) = getCdpInfo(manager, _data[0], ilk);

        uint256 wholeDebt = getAllDebt(
            VAT_ADDRESS,
            manager.urns(_data[0]),
            manager.urns(_data[0]),
            ilk
        );

        require(wholeDebt > maxDebt, "No need for a flash loan");

        manager.cdpAllow(_data[0], MCD_CLOSE_FLASH_LOAN, 1);

        uint[4] memory debtData = [wholeDebt, maxDebt, collateral, _minCollateral];
        bytes memory paramsData = abi.encode(_data, debtData, _joinAddr, _exchangeAddress, _callData);

        lendingPool.flashLoan(MCD_CLOSE_FLASH_LOAN, AAVE_DAI_ADDRESS, wholeDebt, paramsData);

        manager.cdpAllow(_data[0], MCD_CLOSE_FLASH_LOAN, 0);

        // If sub. to automatic protection unsubscribe
        unsubscribe(SUBSCRIPTION_ADDRESS, _data[0]);
        unsubscribe(SUBSCRIPTION_ADDRESS_NEW, _data[0]);

        logger.logFlashLoan("Close", wholeDebt, _data[0], msg.sender);
    }

    function openWithLoan(
        uint256[6] memory _data, // collAmount, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        bytes32 _ilk,
        address _collJoin,
        address _exchangeAddress,
        bytes memory _callData,
        address _proxy,
        bool _isEth
    ) public payable {
        if (_isEth) {
            MCD_OPEN_FLASH_LOAN.transfer(msg.value);
        } else {
            MCD_OPEN_FLASH_LOAN.transfer(msg.value); // 0x fee

            ERC20(getCollateralAddr(_collJoin)).transferFrom(msg.sender, address(this), _data[0]);
            ERC20(getCollateralAddr(_collJoin)).transfer(MCD_OPEN_FLASH_LOAN, _data[0]);
        }

        address[3] memory addrData = [_collJoin, _exchangeAddress, _proxy];

        bytes memory paramsData = abi.encode(_data, _ilk, addrData, _callData, _isEth);

        lendingPool.flashLoan(MCD_OPEN_FLASH_LOAN, AAVE_DAI_ADDRESS, _data[1], paramsData);

        logger.logFlashLoan("Open", manager.last(_proxy), _data[1], msg.sender);
    }


    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(uint256 _cdpId, bytes32 _ilk) public view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    /// @notice Gets the maximum amount of collateral available to draw
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _joinAddr Join Addr of collateral
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxCollateral(uint _cdpId, bytes32 _ilk, address _joinAddr) public view returns (uint) {
        uint price = getPrice(_ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        (, uint mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);

        uint maxCollateral = sub(sub(collateral, (div(mul(mat, debt), price))), 10);

        uint normalizeMaxCollateral = maxCollateral;

        if (Join(_joinAddr).dec() != 18) {
            normalizeMaxCollateral = maxCollateral / (10 ** (18 - Join(_joinAddr).dec()));
        }

        return normalizeMaxCollateral;
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    function getAaveCollAddr(address _joinAddr) internal returns (address) {
        if (_joinAddr == 0x2F0b23f53734252Bda2277357e97e1517d6B042A
            || _joinAddr == 0x775787933e92b709f2a3C70aa87999696e74A9F8) {
            return KYBER_ETH_ADDRESS;
        } else {
            return getCollateralAddr(_joinAddr);
        }
    }

    function unsubscribe(address _subContract, uint _cdpId) internal {
        (, bool isSubscribed) = IMCDSubscriptions(_subContract).subscribersPos(_cdpId);

        if (isSubscribed) {
            IMCDSubscriptions(_subContract).unsubscribe(_cdpId);
        }
    }

}
