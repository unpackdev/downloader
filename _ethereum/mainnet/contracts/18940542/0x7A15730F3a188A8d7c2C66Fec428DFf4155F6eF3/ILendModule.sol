// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./ILendFacet.sol";
interface ILendModule {
    event SubmitPutOrder(address indexed submitor, ILendFacet.PutOrder putOrder);
    event LiquidatePutOrder(address indexed liquidator, ILendFacet.PutOrder putOrder);

    event SubmitCallOrder(address indexed submitor, ILendFacet.CallOrder callOrder);
    event LiquidateCallOrder(address indexed liquidator, ILendFacet.CallOrder callOrder);
    function submitPutOrder(
        ILendFacet.PutOrder memory _putOrder,
        bytes calldata _borrowerSignature,
        bytes calldata _lenderSignature
    ) external;
    function liquidatePutOrder(address _borrower,bool _type) external payable;
    function submitCallOrder(ILendFacet.CallOrder memory _callOrder,bytes calldata _borrowerSignature,bytes calldata _lenderSignature) external;
    function liquidateCallOrder(address _lender,bool _type) external payable;
}
