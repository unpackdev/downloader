pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev allows to mint bond token from SecurityAssetToken or multiSignature account
 */
interface IBondToken {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId) external;

    function hasToken(uint256 tokenId) external view returns (bool);

    function getTokenInfo(uint256 tokenId) external view
        returns (uint256 value, uint256 interest, uint256 maturity);

    function mint(
        uint256 tokenId,
        address to,
        uint256 value,
        uint256 maturity
    ) external;

    function burn(uint256 tokenId) external;
}
