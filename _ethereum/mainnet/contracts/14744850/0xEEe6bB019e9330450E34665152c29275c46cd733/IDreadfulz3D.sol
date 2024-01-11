pragma solidity 0.8.11;
import "./IERC721EnumerableUpgradeable.sol";

interface IDreadfulz3D is IERC721EnumerableUpgradeable {
    function _exists(uint256 tokenId) external view returns (bool);
    function hasPaid(uint256 tokenId) external view returns (bool);
    function correctToken(uint256 tokenId) external view returns (IERC721EnumerableUpgradeable);
    function setPaid(uint256 tokenId, bool val) external;
    function cost() external view returns (uint256);
    function _swap(uint256[] memory, address, address) external;
}
