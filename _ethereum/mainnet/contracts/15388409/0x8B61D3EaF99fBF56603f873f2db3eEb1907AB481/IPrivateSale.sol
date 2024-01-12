//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IPrivateSale {
    /// @dev calculator the SaleAmount(input TON how many get the anotherToken)
    /// @param _amount input the TON amount
    function calculSaleToken(uint256 _amount) external view returns (uint256);

    /// @dev calculator the getAmount(want to get _amount how many input the TON?)
    /// @param _amount input the anotherTokenAmount
    function calculGetToken(uint256 _amount) external view returns (uint256);
    
    
    /// @dev address setting
    /// @param _saleToken saleTokenAddress (contract have token)
    /// @param _getToken getTokenAddress (TON)
    /// @param _ownerToken get TON transfer to wallet
    function addressSetting(
        address _saleToken,
        address _getToken,
        address _ownerToken
    ) external;

    function changeWTONAddress(address _wton) external;

    function changeTokenAddress(address _saleToken, address _getToken) external;

    function changeGetAddress(address _address) external;

    function setAllsetting(
        uint256[2] calldata _saleTime,
        uint256[2] calldata _tokenPrice,
        uint16 _claimCounts,
        uint256[] calldata _claimTimes,
        uint32[] calldata _claimPercents
    ) external;

    function settingSaleTime(uint256 _startTime,uint256 _endTime) external;

    function setTokenPrice(uint256 _saleTokenPrice, uint256 _getTokenPrice) external;

    function setClaimArray(
        uint16 _claimCounts,
        uint256[] calldata _claimTimes,
        uint32[] calldata _claimPercents
    ) external;

    function addWhiteList(address _account,uint256 _amount) external;

    function addWhiteListArray(address[] calldata _account, uint256[] calldata _amount) external;

    function delWhiteList(address _account, uint256 _amount) external;

    function directBuy(
        address _claimAddress,
        uint256 _amount
    ) external;

    function claim() external;

    function decodeApproveData(
        bytes memory data
    ) external pure returns (uint256 approveData);

    function decodeAddressData(
        bytes memory data
    ) external pure returns (address claimAddress_);

    function encodeAddressData(
        address _claimAddress
    ) external pure returns (bytes memory data);

    function _toWAD(uint256 v) external pure returns (uint256);

}
