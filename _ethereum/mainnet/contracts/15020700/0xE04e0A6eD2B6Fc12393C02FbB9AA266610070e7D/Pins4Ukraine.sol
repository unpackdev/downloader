//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./ERC1155.sol";
import "./SafeERC20.sol";
import "./Strings.sol";

contract Pins4Ukraine is ERC1155, IERC2981 {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    address constant UKRAINE_ADDRESS = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
    uint256 constant MINT_OPEN_SINCE = 1656115200; // Sat Jun 25 2022 00:00:00 UTC
    uint256 constant MINT_OPEN_UNTIL = 1671840000; // Sat Dec 24 2022 00:00:00 UTC
    uint256 constant ROYALTY = 5; //%
    uint256 constant DESIGNS = 6;

    constructor() ERC1155("https://pins4ukraine.com/assets") {}

    // Support

    function mint(uint256 _tokenId) external payable {
        require(block.timestamp >= MINT_OPEN_SINCE, "Minting not open yet");
        require(block.timestamp < MINT_OPEN_UNTIL, "Minting already closed");
        require(_tokenId >= 1, "This design isn't avalaible");
        require(_tokenId <= DESIGNS, "This design isn't avalaible");
        require(msg.value >= _tokenPriceAt(block.timestamp), "Not enought value to mint, please use plain transfer");

        _mint(msg.sender, _tokenId, 1, "");
    }

    fallback() external payable {
        // allows to directly send funds to this contract
    }

    receive() external payable {
        // allows to directly send funds to this contract
    }

    function transferSupport() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to transfer");
        payable(UKRAINE_ADDRESS).transfer(balance);
    }

    function transferSupportERC20(IERC20 _token) external {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No balance to transfer");
        _token.safeTransfer(UKRAINE_ADDRESS, balance);
    }

    // Utils

    function tokenPriceAt(uint256 time) external pure returns (uint256) {
        require(time >= MINT_OPEN_SINCE, "Minting not open yet");
        require(time < MINT_OPEN_UNTIL, "Minting already closed");
        return _tokenPriceAt(time);
    }

    function _tokenPriceAt(uint256 time) internal pure returns (uint256) {
        uint256 ONE_WEEK = 604800;

        uint256 t = time - MINT_OPEN_SINCE; // seconds
        uint256 w = (t / ONE_WEEK)+1; // 1-26
        uint256 w3 = w ** 3; // 1-17576
        uint256 p = (w3 * 50) / 17576; // 0-50
        if (p < 1) {
          p = 1; // 1-50
        }
        uint256 price = 1e16 * p;

        return price;
    }

    // Metadata

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.uri(_tokenId), "/", _tokenId.toString(), ".json"));
    }

    // EIP2981 royalties

    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external pure override
        returns (address, uint256)
    {
        return (UKRAINE_ADDRESS, (_salePrice * ROYALTY) / 100);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId)
        );
    }
}
