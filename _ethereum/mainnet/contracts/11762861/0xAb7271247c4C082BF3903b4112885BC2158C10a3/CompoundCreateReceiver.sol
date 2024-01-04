pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./DSProxy.sol";
import "./FlashLoanReceiverBase.sol";
import "./DSProxyInterface.sol";
import "./DFSExchangeCore.sol";
import "./ShifterRegistry.sol";
import "./CompoundCreateTaker.sol";

/// @title Contract that receives the FL from Aave for Creating loans
contract CompoundCreateReceiver is FlashLoanReceiverBase, DFSExchangeCore {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    ShifterRegistry public constant shifterRegistry = ShifterRegistry(0x2E82103bD91053C781aaF39da17aE58ceE39d0ab);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address payable public constant WALLET_ADDR = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    // solhint-disable-next-line no-empty-blocks
    constructor() public FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) {}

    struct CompCreateData {
        address payable proxyAddr;
        bytes proxyData;
        address cCollAddr;
        address cDebtAddr;
    }

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
   function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {
        // Format the call data for DSProxy
        (CompCreateData memory compCreate, ExchangeData memory exchangeData)
                                 = packFunctionCall(_amount, _fee, _params);


        address leveragedAsset = _reserve;

        // If the assets are different
        if (compCreate.cCollAddr != compCreate.cDebtAddr) {
            exchangeData.dfsFeeDivider = SERVICE_FEE;
            exchangeData.user = DSProxyInterface(compCreate.proxyAddr).owner();

            _sell(exchangeData);

            leveragedAsset = exchangeData.destAddr;
        }

        // Send amount to DSProxy
        sendToProxy(compCreate.proxyAddr, leveragedAsset);

        address compOpenProxy = shifterRegistry.getAddr("COMP_SHIFTER");

        // Execute the DSProxy call
        DSProxyInterface(compCreate.proxyAddr).execute(compOpenProxy, compCreate.proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            // solhint-disable-next-line avoid-tx-origin
            tx.origin.transfer(address(this).balance);
        }
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _amount Amount of FL
    /// @param _fee Fee of the FL
    /// @param _params Saver proxy params
    function packFunctionCall(uint _amount, uint _fee, bytes memory _params) internal pure  returns (CompCreateData memory compCreate, ExchangeData memory exchangeData) {

        CompoundCreateTaker.CreateInfo memory createData;
        address proxy;

        (createData , exchangeData, proxy)= abi.decode(_params, (CompoundCreateTaker.CreateInfo, ExchangeData, address));

        bytes memory proxyData = abi.encodeWithSignature(
            "open(address,address,uint256)",
                                createData.cCollAddress, createData.cBorrowAddress, (_amount + _fee));


        compCreate = CompCreateData({
            proxyAddr: payable(proxy),
            proxyData: proxyData,
            cCollAddr: createData.cCollAddress,
            cDebtAddr: createData.cBorrowAddress
        });

        return (compCreate, exchangeData);
    }

    /// @notice Send the FL funds received to DSProxy
    /// @param _proxy DSProxy address
    /// @param _reserve Token address
    function sendToProxy(address payable _proxy, address _reserve) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, ERC20(_reserve).balanceOf(address(this)));
        } else {
            _proxy.transfer(address(this).balance);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external override(FlashLoanReceiverBase, DFSExchangeCore) payable {}
}
