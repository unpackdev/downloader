pragma solidity >=0.6.0 <0.7.0;


/**
 * @title ISecurityAssetToken
 * @dev SecurityAssetToken interface
 */
interface ISecurityAssetToken {
    function mint(
        address to,
        uint256 value,
        uint256 maturity
    ) external;

    function burn(uint256 tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
