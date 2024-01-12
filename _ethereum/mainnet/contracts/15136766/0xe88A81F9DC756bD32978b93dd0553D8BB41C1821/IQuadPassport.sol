//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC1155Upgradeable.sol";
import "./QuadPassportStore.sol";

interface IQuadPassport is IERC1155Upgradeable {

    function mintPassport(
        QuadPassportStore.MintConfig calldata config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable;

    function setAttribute(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt,
        bytes calldata _sig
    ) external payable;

    function setAttributeIssuer(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute,
        bytes32 _value,
        uint256 _issuedAt
    ) external ;

    function burnPassport(uint256 _tokenId) external;

    function burnPassportIssuer(address _account, uint256 _tokenId) external;

    function setGovernance(address _governanceContract) external;

    function withdrawETH(address payable _to) external returns (uint256);

    function withdrawToken(address payable _to, address _token)
        external
        returns (uint256);


    function attributes(address, bytes32, address) external view returns (QuadPassportStore.Attribute memory);

    function attributesByDID(bytes32, bytes32, address) external view returns (QuadPassportStore.Attribute memory);

    function increaseAccountBalanceETH(address, uint256) external;

    function increaseAccountBalance(address, address, uint256) external;

    function acceptGovernance() external;

}
