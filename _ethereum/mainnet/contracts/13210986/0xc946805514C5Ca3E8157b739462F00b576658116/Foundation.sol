// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./PaymentSplitter.sol";
import "./ERC165Checker.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

contract Foundation is PaymentSplitter, ERC721Holder, ERC1155Holder {
    // ==== Events ====
    event ERC20PaymentReleased(address to, uint256 amount, address currency);
    event ERC721PaymentReleased(address to, address token, uint256 id);
    event ERC1155PaymentReleased(address to, address token, uint256 id, uint256 value);

    // ==== Storage ====
    mapping(address => uint256) private _totalReleasedERC20;
    mapping(address => mapping(address => uint256)) private _releasedERC20;

    // ==== Constructor ====
    constructor(address[] memory payees, uint256[] memory shares) PaymentSplitter(payees, shares) {
    }

    // ==== Modifiers ====
    modifier validERC20(address currency) {
        if (ERC165Checker.supportsERC165(currency)) {
            require(ERC165Checker.supportsInterface(currency, type(IERC20).interfaceId), "Foundation: not a valid ERC20");
        } else {
            require(IERC20(currency).totalSupply() >= 0, "Foundation: not a valid ERC20");
        }
        _;
    }

    modifier hasShares(address account) {
        require(super.shares(account) > 0, "Foundation: account has no shares");
        _;
    }

    modifier validERC721(address token) {
        require(ERC165Checker.supportsInterface(token, type(IERC721).interfaceId), "Foundation: not a valid ERC721");
        _;
    }

    modifier validERC1155(address token) {
        require(ERC165Checker.supportsInterface(token, type(IERC1155).interfaceId), "Foundation: not a valid ERC1155");
        _;
    }

    // ==== ERC20 Functions ====
    function totalReleasedERC20(address currency) public view validERC20(currency) returns (uint256) {
        return _totalReleasedERC20[currency];
    }

    function releasedERC20(address account, address currency) public view validERC20(currency) returns (uint256) {
        return _releasedERC20[account][currency];
    }

    function releaseERC20(address payable account, address currency) public validERC20(currency) hasShares(account) {

        IERC20 tokenContract = IERC20(currency);

        uint256 totalReceived = tokenContract.balanceOf(address(this)) + _totalReleasedERC20[currency];
        uint256 payment = (totalReceived * super.shares(account)) / super.totalShares()
            - _releasedERC20[account][currency];

        require(payment > 0, "Foundation: account is not due payment");

        bool approval = tokenContract.approve(address(this), payment);
        require(approval, "Foundation: ERC20 does not approve the payment");
        bool success = tokenContract.transferFrom(address(this), account, payment);
        require(success, "Foundation: ERC20 transfer is not successful");

        _releasedERC20[account][currency] += payment;
        _totalReleasedERC20[currency] += payment;

        emit ERC20PaymentReleased(account, payment, currency);
    }

    // ==== ERC721 Functions ====
    function releaseERC721(address payable account, address token, uint256 tokenId) 
        public validERC721(token) hasShares(account) 
    {
        IERC721 tokenContract = IERC721(token);

        tokenContract.safeTransferFrom(address(this), account, tokenId);

        emit ERC721PaymentReleased(account, token, tokenId);
    }

    // ==== ERC1155 Functions ====
    function releaseERC1155(address payable account, address token, uint256 tokenId, uint256 value) 
        public validERC1155(token) hasShares(account)
    {
        IERC1155 tokenContract = IERC1155(token);
    
        tokenContract.safeTransferFrom(address(this), account, tokenId, value, "");

        emit ERC1155PaymentReleased(account, token, tokenId, value);
    }
}
