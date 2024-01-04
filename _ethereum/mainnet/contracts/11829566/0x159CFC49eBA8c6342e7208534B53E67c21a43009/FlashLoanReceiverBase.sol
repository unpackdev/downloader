pragma solidity ^0.5.0;

// import "./IERC20.sol";
import "./IToken.sol";

import "./IFlashLoanReceiver.sol";
import "./ILendingPoolAddressesProvider.sol";

import "./SafeERC20.sol";
import "./EthAddressLib.sol";


contract FlashLoanReceiverBase is IFlashLoanReceiver {

    using SafeERC20 for IToken;


    // Mainnet Aave LendingPoolAddressesProvider address
     address public constant AAVE_ADDRESSES_PROVIDER = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    // Kovan Aave LendingPoolAddressesProvider addres
    // address public constant AAVE_ADDRESSES_PROVIDER = 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5;


    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
        address payable core = ILendingPoolAddressesProvider(AAVE_ADDRESSES_PROVIDER).getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(address _destination, address _reserve, uint256  _amount) internal {

        if(_reserve == EthAddressLib.ethAddress()) {
            address payable receiverPayable = address(uint160(_destination));

            //solium-disable-next-line
            (bool result, ) = receiverPayable.call.value(_amount)("");

            require(result, "Transfer of ETH failed");
            return;
        }

        IToken(_reserve).safeTransfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == EthAddressLib.ethAddress()) {
            return _target.balance;
        }

        return IToken(_reserve).balanceOf(_target);
    }

}