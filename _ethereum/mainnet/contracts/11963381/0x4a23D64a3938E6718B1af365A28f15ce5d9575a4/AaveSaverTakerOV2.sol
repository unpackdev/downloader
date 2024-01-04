pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AaveHelperV2.sol";
import "./GasBurner.sol";
import "./AdminAuth.sol";
import "./ProxyPermission.sol";
import "./DydxFlashLoanBase.sol";
import "./DefisaverLogger.sol";
import "./ProxyRegistryInterface.sol";
import "./TokenInterface.sol";
import "./ERC20.sol";
import "./DFSExchangeData.sol";

  // function flashLoan(
  //   address receiverAddress,
  //   address[] calldata assets,
  //   uint256[] calldata amounts,
  //   uint256[] calldata modes,
  //   address onBehalfOf,
  //   bytes calldata params,
  //   uint16 referralCode
  // ) external;

/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveSaverTakerOV2 is ProxyPermission, GasBurner, DFSExchangeData, AaveHelperV2 {

    address payable public constant AAVE_RECEIVER = 0x1FA9bF00D622EF5e7513f889375db86212B43B45;

    function repay(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        // send msg.value for exchange to the receiver
        AAVE_RECEIVER.transfer(msg.value);

        address[] memory assets = new address[](1);
        assets[0] = _data.srcAddr;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _data.srcAmount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = _rateMode;

        // create data
        bytes memory encodedData = packExchangeData(_data);
        bytes memory data = abi.encode(encodedData, _market, _gasCost, _rateMode, true, proxyOwner(), address(this));

        // give permission to receiver and execute tx
        givePermission(AAVE_RECEIVER);
        ILendingPoolV2(lendingPool).flashLoan(AAVE_RECEIVER, assets, amounts, modes, address(this), data, AAVE_REFERRAL_CODE);
        removePermission(AAVE_RECEIVER);
    }

    function boost(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();

        // send msg.value for exchange to the receiver
        AAVE_RECEIVER.transfer(msg.value);

        address[] memory assets = new address[](1);
        assets[0] = _data.srcAddr;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _data.srcAmount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = _rateMode;

        // create data
        bytes memory encodedData = packExchangeData(_data);
        bytes memory data = abi.encode(encodedData, _market, _gasCost, _rateMode, false, proxyOwner(), address(this));

        // give permission to receiver and execute tx
        givePermission(AAVE_RECEIVER);
        ILendingPoolV2(lendingPool).flashLoan(AAVE_RECEIVER, assets, amounts, modes, address(this), data, AAVE_REFERRAL_CODE);
        removePermission(AAVE_RECEIVER);
    }
}
