// SPDX-License-Identifier: MIT
/// @title: Billy Bob for St Jude
/// @author: Drophero LLC
pragma solidity ^0.8.9;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";

contract BillyBobForStJude is
    ERC1155Supply,
    Ownable
{
    event PaymentReleased(address to, uint256 amount);

    uint256 private _mintPrice = 0.03 ether;
    bool private _saleActive;
    uint256 private _totalReleased;

    uint256 public constant SIGNED_EDITION_ID = 0;
    uint256 public constant OPEN_EDITION_ID = 1;
    address public constant STJUDE_WALLET = 0x92EE2370b56DC32794A6CD72585dC01d4288D314;

    constructor(string memory uri_) ERC1155(uri_) {
        _mint(STJUDE_WALLET, SIGNED_EDITION_ID, 1, "");
        _saleActive = false;
    }

    function name() external pure returns (string memory) {
        return "Billy Bob for St Jude";
    }

    function symbol() external pure returns (string memory) {
        return "BBSJ";
    }

    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function setSaleActive(bool value) external onlyOwner {
        _saleActive = value;
    }

    function saleIsActive() external view returns(bool) {
        return _saleActive;
    }

    function price() external view returns (uint256) {
        return _mintPrice;
    }

    function setPrice(uint256 value) external onlyOwner {
        _mintPrice = value;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice * numberOfTokens;
    }

    function totalSupply() external view returns(uint256) {
        return totalSupply(OPEN_EDITION_ID) + 1;
    }

    function mint(uint256 numberOfTokens)
        external
        payable
    {
        require(
            _saleActive,
            "SALE_INACTIVE"
        );
        require(
            mintPrice(numberOfTokens) <= msg.value,
            "ETHER_VALUE_INVALID"
        );
        _mint(_msgSender(), OPEN_EDITION_ID, numberOfTokens, "");
    }

    function totalReleased() external view returns(uint256) {
        return _totalReleased;
    }

    function release() external {
        uint256 payment = address(this).balance;
        require(payment != 0, "BALANCE_IS_ZERO");

        _totalReleased += payment;

        emit PaymentReleased(STJUDE_WALLET, payment);
        Address.sendValue(payable(STJUDE_WALLET), payment);
    }

    receive() external payable virtual {}
}
