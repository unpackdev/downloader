//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDropspaceSaleFactory {
    // OWNER ONLY
    function withdraw() external;
    function setSaleFlatFee(uint256 _flatFee) external;
    function setSalePercentageFee(uint256 _percentageFee) external;
    function setRevenueWallet(address payable _revenueWallet) external;
    function setAutoWithdraw(bool _autoWithdraw) external;

    function withdrawFromSale(uint256 _saleID) external;
    function setDevWalletForSale(uint256 _saleID, address payable _devWallet) external;
    function setDevShareForSale(uint256 _saleID, uint256 devSaleShare) external;

    // EXTERNAL
    function createSale(
        uint256 _supplyLimit, 
        uint256 _mintLimit,
        uint256 _mintPrice,
        address payable _withdrawalWallet,
        address _ticketAddress,
        string memory _name,
        string memory _ticker,
        string memory _baseURI
    ) external payable returns (uint256, address);

    // VIEW
    function totalSales() external view returns(uint256);
    function sales(uint256 _saleID) external view returns(address);
    function flatFee() external view returns(uint256);
    function percentageFee() external view returns(uint256);
    function revenueWallet() external view returns(address payable);
    function autoWithdraw() external view returns(bool);

    // EVENTS
    event SaleCreated(uint256 _saleID, address saleAddress);
    event FlatFeeChanged(uint256 _newFlatFee);
    event PercentageFeeChanged(uint256 _newPercentageFee);
    event RevenueWalletChanged(address payable _newRevenueWallet);
    event AutoWithdrawChanged(bool autoWithdraw);

    receive() external payable;
}