// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./DataTypes.sol";

interface ITribeOne {
    event LoanCreated(uint256 indexed loanId, address indexed owner, address nftAddress, uint256 nftTokenId, bool isERC721);
    event LoanApproved(uint256 indexed _loanId, address indexed _to, address _fundCurreny, uint256 _fundAmount);
    event LoanCanceled(uint256 indexed _loanId, address _sender);
    event NFTRelayed(uint256 indexed _loanId, address indexed _sender, bool _accepted);
    event InstallmentPaid(uint256 indexed _loanId, address _sender, address _currency, uint256 _amount);
    event NFTWithdrew(uint256 indexed _loanId, address _to);
    event LoanDefaulted(uint256 indexed _loandId);
    event LoanLiquidation(uint256 indexed _loanId, address _salesManager);
    event LoanPostLiquidation(uint256 indexed _loanId, uint256 _soldAmount, uint256 _finalDebt);
    event RestWithdrew(uint256 indexed _loanId, uint256 _amount);
    event SettingsUpdate(address _feeTo, uint256 _lateFee, uint256 _penaltyFee, address _salesManager, address _assetManager);
    event LoanRejected(uint256 indexed _loanId, address _agent);
    event LoanRented(uint256 indexed _loanId, address indexed _adapter);
    event LoanWithdrawFromRent(uint256 indexed _loanId, address _adapter);

    function approveLoan(
        uint256 _loanId,
        uint256 _amount,
        address _agent
    ) external;

    function relayNFT(
        uint256 _loanId,
        address _agent,
        bool _accepted
    ) external payable;

    function payInstallment(uint256 _loanId, uint256 _amount) external payable;

    function getLoans(uint256 _loanId) external view returns (DataTypes.Loan memory);

    function getLoanNFTItem(uint256 _loanId) external view returns (DataTypes.NFTItem memory);

    function getLoanAsset(uint256 _loanId) external view returns (uint256, address);

    function getCollateralAsset(uint256 _loanId) external view returns (uint256, address);

    function getLoanRent(uint256 _loanId) external view returns (address);

    function totalDebt(uint256 _loanId) external view returns (uint256);

    function currentDebt(uint256 _loanId) external view returns (uint256);

    function listNFTForRent(uint256 loanId, address borrower) external;

    function withdrawNFTFromRent(uint256 loanId) external;

    function isAvailableRentalAction(uint256 loanId, address user) external view returns (bool);
}
