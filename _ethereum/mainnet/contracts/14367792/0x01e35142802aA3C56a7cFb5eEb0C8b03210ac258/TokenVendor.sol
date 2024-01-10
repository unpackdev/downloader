// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./AdminControl.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   ______                            _                     _     
//   |  ___|                          | |                   | |    
//   | |_ ___  _ __ _____   _____ _ __| |     __ _ _ __   __| |___ 
//   |  _/ _ \| '__/ _ \ \ / / _ \ '__| |    / _` | '_ \ / _` / __|
//   | || (_) | | |  __/\ V /  __/ |  | |___| (_| | | | | (_| \__ \
//   \_| \___/|_|  \___| \_/ \___|_|  \_____/\__,_|_| |_|\__,_|___/ . xyz
//
//   EXPLORER TOKEN VENDING MACHINE
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract TokenVendor is ReentrancyGuard, AdminControl {

    event TokenAdded(address indexed tokenAddress);
    event TokenPriceChanged(address indexed, uint256 price);
    event TokenAllowanceChanged(address indexed, uint256 quantity);
    event TokenRemoved(address indexed tokenAddress);
    event Sale(address indexed to, uint256 price, uint256 quantity);

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _acceptedTokens;
    mapping(address => uint256) private _prices;
    mapping(address => uint256) private _allowances;
    address private _itemContract;
    uint256 private _itemId;
    address payable private _recovery;

    constructor (address itemContract, uint256 id, uint256 priceInEther) {
        _itemContract = itemContract;
        _itemId = id;
        _acceptedTokens.add(address(0));
        _prices[address(0)] = priceInEther;
        _allowances[address(0)] = 0;
        _recovery = payable(owner());
    }

    function setRecoveryAddress(address payable recovery) external adminRequired {
        _recovery = recovery;
    }

    function setProduct(address itemContract, uint256 id) external adminRequired {
        _itemContract = itemContract;
        _itemId = id;
    }

    function acceptToken(address tokenAddress, uint256 price, uint256 allowance) external adminRequired {
        require(!_acceptedTokens.contains(tokenAddress),"Token is already accepted");
        _acceptedTokens.add(tokenAddress);
        _prices[tokenAddress] = price;
        _allowances[tokenAddress] = allowance;
        emit TokenAdded(tokenAddress);
        emit TokenPriceChanged(tokenAddress, price);
    }

    function removeToken(address tokenAddress) external adminRequired {
        require(_acceptedTokens.contains(tokenAddress),"Unknown token");
        _acceptedTokens.remove(tokenAddress);
        emit TokenRemoved(tokenAddress);
    }

    function setPriceInToken(address tokenAddress, uint256 price) external adminRequired {
        _prices[tokenAddress] = price;
        emit TokenPriceChanged(tokenAddress, price);
    }

    function setAllowanceForToken(address tokenAddress, uint256 allowance) external adminRequired {
        _allowances[tokenAddress] = allowance;
        emit TokenAllowanceChanged(tokenAddress, allowance);
    }

    function purchaseWithEther(uint256 quantity) external payable nonReentrant {
        require(quantity > 0, "Invalid amount");
        require(_allowances[address(0)] > 0, "Sold out");
        require(_allowances[address(0)] >= quantity, "Invalid amount");
        IERC1155 itemContract = IERC1155(_itemContract);
        require(itemContract.balanceOf(address(this), _itemId) >= quantity, "Invalid amount");
        uint amountToPay = SafeMath.mul(quantity, _prices[address(0)]);
        require(quantity > 0 && msg.value == amountToPay, "Invalid Eth sent");
        IERC1155(_itemContract).safeTransferFrom(address(this), msg.sender, _itemId, quantity, "");
        _allowances[address(0)] = SafeMath.sub(_allowances[address(0)], quantity);
        emit Sale(msg.sender, amountToPay, quantity);
    }

    function purchaseWithToken(address tokenAddress, uint256 quantity) external payable nonReentrant {
        require(_acceptedTokens.contains(tokenAddress),"Unknown token");
        require(msg.value == 0, "Eth was sent");
        require(quantity > 0, "Invalid amount");
        require(_allowances[tokenAddress] > 0, "Sold out");
        require(_allowances[tokenAddress] >= quantity, "Invalid amount");
        IERC1155 itemContract = IERC1155(_itemContract);
        require(itemContract.balanceOf(address(this), _itemId) >= quantity, "Invalid amount");
        IERC20 paymentToken = IERC20(tokenAddress);
        uint256 amountToPay = SafeMath.mul(quantity, _prices[tokenAddress]);
        require(paymentToken.allowance(msg.sender, address(this)) >= amountToPay,"Insuficient Allowance");
        require(paymentToken.transferFrom(msg.sender,address(this), amountToPay),"Transfer Failed");
        IERC1155(_itemContract).safeTransferFrom(address(this), msg.sender, _itemId, quantity, "");
        _allowances[tokenAddress] = SafeMath.sub(_allowances[tokenAddress], quantity);
        emit Sale(msg.sender, amountToPay, quantity);
    }

    function productInfo() external view returns (address, uint256, uint256) {
        IERC1155 itemContract = IERC1155(_itemContract);
        uint256 _balance = itemContract.balanceOf(address(this), _itemId);
        return (_itemContract, _itemId, _balance);
    }

    function isTokenAccepted(address tokenAddress) external view returns (bool) {
        return _acceptedTokens.contains(tokenAddress);
    }

    function productsRemaining(address tokenAddress) external view returns (uint256) {
        require(_acceptedTokens.contains(tokenAddress),"Unknown token");
        return (_allowances[tokenAddress]);
    }

    function getPriceInToken(address tokenAddress) external view returns (uint256) {
        require(_acceptedTokens.contains(tokenAddress),"Unknown token");
        return (_prices[tokenAddress]);
    }
    
    function getEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) external adminRequired {
        _recovery.transfer(amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external virtual adminRequired {
        IERC20(tokenAddress).transfer(_recovery, tokenAmount);
    }

    function recoverERC721(address tokenAddress, uint256 tokenId) external virtual adminRequired {
        IERC721(tokenAddress).transferFrom(address(this), _recovery, tokenId);
    }

    function recoverERC1155(address tokenAddress, uint256 tokenId, uint256 amount) external virtual adminRequired {
        IERC1155(tokenAddress).safeTransferFrom(address(this), _recovery, tokenId, amount, "");
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}