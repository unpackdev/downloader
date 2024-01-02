// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./SSTORE2.sol";
import "./Base64.sol";

contract LeetFont is Ownable {
    address private _font;

    /*
     * @dev returns font URI that can be used in CSS
     */
    function getFontURI() public view returns (string memory) {
        return string(abi.encodePacked("data:application/font-woff;charset=utf-8;base64,", LeetFont.getFontBase64()));
    }

    function getFontBase64() public view returns (string memory) {
        require(_font != address(0), "LeetFont: font not set");
        return Base64.encode(SSTORE2.read(_font));
    }

    function setFont(bytes memory font) external onlyOwner {
        _font = SSTORE2.write(bytes(font));
    }
}
