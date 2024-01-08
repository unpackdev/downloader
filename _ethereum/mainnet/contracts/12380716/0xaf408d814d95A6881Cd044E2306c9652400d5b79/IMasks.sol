pragma solidity ^0.7.0;
import "./IERC721Enumerable.sol";

interface IMasks is IERC721Enumerable {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}