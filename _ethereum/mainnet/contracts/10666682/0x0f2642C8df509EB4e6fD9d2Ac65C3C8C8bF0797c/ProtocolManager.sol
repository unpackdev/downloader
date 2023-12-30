pragma solidity ^0.6.0;
// pragma experimental ABIEncoderV2;

// import "./ProtocolInterface.sol";
// import "./ERC20.sol";
// import "./ConstantAddresses.sol";
// import "./ISoloMargin.sol";
// import "./SavingsLogger.sol";
// import "./Types.sol";

// contract FulcrumInterface {
//     function assetBalanceOf(address _owner) public view returns(uint256);
// }

// contract CompoundInterface {
//     function balanceOfUnderlying(address account) public view returns (uint);
// }

// contract DyDxInterface {
//     function getWeiBalance(address _user, uint _index) public view returns(Types.Wei memory);
// }


// contract ProtocolManager is ConstantAddresses {

//     address constant public SAVINGS_COMPOUND_ADDRESS = 0xba7676a6c3E2FFff9f8d16e9C7b1e7848CC0f7DE;
//     address constant public SAVINGS_DYDX_ADDRESS = 0x97a13567879471E1d6a3C37AB1017321980cd0ca;
//     address constant public SAVINGS_FULCRUM_ADDRESS = 0x0F0277EE54403a46f12D68Eeb49e444FE0bd4682;

//     enum SavingsProtocol { Compound, Dydx, Fulcrum }

//     function _deposit(SavingsProtocol _protocol, uint _amount) internal {
//         approveDeposit(_protocol, _amount);

//         ProtocolInterface(getAddress(_protocol)).deposit(address(this), _amount);

//         endAction(_protocol);

//         SavingsLogger(SAVINGS_LOGGER_ADDRESS).logDeposit(msg.sender, uint8(_protocol), _amount);

//     }

//     function _withdraw(SavingsProtocol _protocol, uint _amount) internal {
//         approveWithdraw(_protocol, _amount);

//         ProtocolInterface(getAddress(_protocol)).withdraw(address(this), _amount);

//         endAction(_protocol);

//         withdrawDai();

//         SavingsLogger(SAVINGS_LOGGER_ADDRESS).logWithdraw(msg.sender, uint8(_protocol), _amount);
//     }

//     function _swap(SavingsProtocol _from, SavingsProtocol _to, uint _amount) internal {
//         _withdraw(_from, _amount);
//         _deposit(_to, _amount);

//         SavingsLogger(SAVINGS_LOGGER_ADDRESS).logSwap(msg.sender, uint8(_from), uint8(_to), _amount);
//     }

//     function withdrawDai() internal {

//         ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, ERC20(MAKER_DAI_ADDRESS).balanceOf(address(this)));
//     }

//     function getAddress(SavingsProtocol _protocol) internal pure returns(address) {
//         if (_protocol == SavingsProtocol.Compound) {
//             return SAVINGS_COMPOUND_ADDRESS;
//         }

//         if (_protocol == SavingsProtocol.Dydx) {
//             return SAVINGS_DYDX_ADDRESS;
//         }

//         if (_protocol == SavingsProtocol.Fulcrum) {
//             return SAVINGS_FULCRUM_ADDRESS;
//         }
//     }

//     function endAction(SavingsProtocol _protocol)  internal {
//         if (_protocol == SavingsProtocol.Dydx) {
//             setDydxOperator(false);
//         }
//     }

//     function approveDeposit(SavingsProtocol _protocol, uint _amount) internal {
//         ERC20(MAKER_DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount);

//         if (_protocol == SavingsProtocol.Compound || _protocol == SavingsProtocol.Fulcrum) {
//             ERC20(MAKER_DAI_ADDRESS).approve(getAddress(_protocol), _amount);
//         }

//         if (_protocol == SavingsProtocol.Dydx) {
//             ERC20(MAKER_DAI_ADDRESS).approve(SOLO_MARGIN_ADDRESS, _amount);
//             setDydxOperator(true);
//         }
//     }

//     function approveWithdraw(SavingsProtocol _protocol, uint _amount) internal {
//         if (_protocol == SavingsProtocol.Compound) {
//             ERC20(CDAI_ADDRESS).approve(getAddress(_protocol), _amount);
//         }

//         if (_protocol == SavingsProtocol.Dydx) {
//             setDydxOperator(true);
//         }

//         if (_protocol == SavingsProtocol.Fulcrum) {
//             ERC20(IDAI_ADDRESS).approve(getAddress(_protocol), _amount);
//         }
//     }

//     function setDydxOperator(bool _trusted) internal {
//         ISoloMargin.OperatorArg[] memory operatorArgs = new ISoloMargin.OperatorArg[](1);
//         operatorArgs[0] = ISoloMargin.OperatorArg({
//             operator: getAddress(SavingsProtocol.Dydx),
//             trusted: _trusted
//         });

//         ISoloMargin(SOLO_MARGIN_ADDRESS).setOperators(operatorArgs);
//     }

//     function getDyDxBalance(address _account) internal returns (uint) {
//         return DyDxInterface(SAVINGS_DYDX_ADDRESS).getWeiBalance(_account, 0).value;
//     }

//     function getCompoundBalance(address _account) internal returns (uint) {
//         return CompoundInterface(CDAI_ADDRESS).balanceOfUnderlying(_account);
//     }

//     function getFulcrumBalance(address _account) internal returns (uint) {
//         return FulcrumInterface(IDAI_ADDRESS).assetBalanceOf(_account);
//     }
// }
