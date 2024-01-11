// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./SignedMath.sol";

contract LandAreaManager {
    using SafeMath for int256;
    using SafeMath for uint256;

    uint256 internal constant GRID_SIZE_X = 128;
    uint256 internal constant GRID_SIZE_Y = 128;

    modifier isInsideBoundaries(int256 x, int256 y) {
        require(SignedMath.abs(x) <= getGridWidth(), "X coordinate out of boundaries");
        require(SignedMath.abs(y) <= getGridHeight(), "Y coordinate out of boundaries");
        _;
    }

    function getGridWidth() public pure returns (uint256) {
        return GRID_SIZE_X;
    }

    function getGridHeight() public pure returns (uint256) {
        return GRID_SIZE_Y;
    }

    function getX(uint256 tokenId) public pure returns (int256) {
        require(isValidTokenId(tokenId), "Invalid token ID");
        int256 unshiftedX = int256(tokenId / ((getGridHeight() * 2) + 1));
        return unshiftedX - int256(getGridWidth());
    }

    function getY(uint256 tokenId) public pure returns (int256) {
        require(isValidTokenId(tokenId), "Invalid token ID");
        int256 unshiftedY = int256(tokenId % ((getGridWidth() * 2) + 1));
        return unshiftedY - int256(getGridHeight());
    }

    function getTokenId(int256 x, int256 y) public pure isInsideBoundaries(x, y) returns (uint256) {
        uint256 paddedX = uint256(x + int256(getGridWidth()));
        uint256 paddedY = uint256(y + int256(getGridHeight()));
        return paddedX * ((getGridHeight() * 2) + 1) + paddedY;
    }

    function isValidTokenId(uint256 _tokenId) public pure virtual returns (bool) {
        uint256 supply = (getGridWidth() * 2 + 1) * (getGridHeight() * 2 + 1);
        return _tokenId < supply;
    }
}
