// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC20.sol";

contract Membership is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant PRICE = 1000;

    Counters.Counter private _tokenIdCounter;

    ERC20 public paymentToken;

    mapping(uint256 => mapping(address => uint256)) public erc20Balance;
    mapping(uint256 => mapping(address => mapping(address => uint256))) public erc20Allowance;


    constructor(ERC20 _paymentToken) ERC721("Membership", "MBR") {
        paymentToken = _paymentToken;
    }

    function mint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function buyMembership() external {
        address sender = msg.sender;
        require(balanceOf(sender) == 0, "[buyMembership]: sender already has membership");
        paymentToken.transferFrom(sender, address(this), PRICE * 10 ** paymentToken.decimals());
        mint(sender);
    }

    function buyMembershipAdmin(address receiver) external onlyOwner {
        require(balanceOf(receiver) == 0, "[buyMembershipAdmin]: receiver already has membership");
        mint(receiver);
    }

    function withdrawPaymentToken() external onlyOwner {
        paymentToken.transfer(msg.sender, paymentToken.balanceOf(address(this)));
    }

    function deposit(uint256 id, address token, uint256 value) external {
        require(_exists(id), "[deposit]: token not exist");
        address sender = msg.sender;
        IERC20(token).transferFrom(sender, address(this), value);
        erc20Balance[id][token] += value;
    }

    function approveERC20tokens(uint256 id, address token, address operator, uint256 value) external {
        address sender = msg.sender;
        require(ownerOf(id) == sender, "[approveERC20tokens]: not owner");
        erc20Allowance[id][token][operator] += value;
    }

    function transferFromERC20(uint256 id, address token, address to, uint256 value) external {
        address operator = msg.sender;
        require(erc20Allowance[id][token][operator] >= value, "[transferFromERC20]: insufficient allowance");

        IERC20(token).transfer(to, value);

        erc20Balance[id][token] -= value;
        erc20Allowance[id][token][operator] -= value;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(balanceOf(to) == 0, "[transferFrom]: to already has membership");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(balanceOf(to) == 0, "[safeTransferFrom]: to already has membership");
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(balanceOf(to) == 0, "[safeTransferFrom]: to already has membership");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

}