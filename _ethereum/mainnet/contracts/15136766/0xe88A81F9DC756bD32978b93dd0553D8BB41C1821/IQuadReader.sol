//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IQuadReader {

    function getAttributesExcluding(
            address _account,
            uint256 _tokenId,
            bytes32 _attribute,
            address _tokenAddr,
            address[] calldata _excludedIssuers
        ) external returns(bytes32[] memory, uint256[] memory, address[] memory);


    function getAttributesFreeExcluding(
            address _account,
            uint256 _tokenId,
            bytes32 _attribute,
            address[] calldata _excludedIssuers
        ) external view returns(bytes32[] memory, uint256[] memory, address[] memory);


    function getAttributesETHExcluding(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _excludedIssuers
    ) external payable returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesETH(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    ) external payable returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesFree(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    ) external view returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributes(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address _tokenAddr
    ) external returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address _tokenAddr,
        address[] calldata _onlyIssuers
    ) external returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesFreeIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _onlyIssuers
    ) external view returns(bytes32[] memory, uint256[] memory, address[] memory);

    function getAttributesETHIncludingOnly(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        address[] calldata _onlyIssuers
    ) external payable returns(bytes32[] memory, uint256[] memory, address[] memory);

    function calculatePaymentToken(
        bytes32 _attribute,
        address _tokenPayment,
        address _account
    ) external view returns(uint256);

    function calculatePaymentETH(
        bytes32 _attribute,
        address _account
    ) external view returns(uint256);

}