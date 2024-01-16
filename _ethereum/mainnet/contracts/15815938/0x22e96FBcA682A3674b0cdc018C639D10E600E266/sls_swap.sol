//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

interface ITokenToSwap is IERC20 {}
interface ITokenSwapTo is IERC20 {}


contract SLSSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public tokenToSwapAddress;
    address public tokenSwapToAddress;

    uint256 internal _tokenBalance;
    uint256 internal _swappedBalance;

    mapping(address => uint256) internal _swappedHistory;

    event Swap(address indexed _user, uint256 _amount);

    constructor () {
        tokenToSwapAddress = 0xC05d14442A510De4D3d71a3d316585aA0CE32b50;
    }

    function deposit (
        address _swapToTokenAddress,
        uint256 _amount
    ) external nonReentrant returns (bool)  {

        require(_swapToTokenAddress == tokenSwapToAddress, "SLSSwap: This currency is not supported");
        require(_amount > 0, "SLSSwap: Amount is invalid");

        uint256 _userBalance = ITokenSwapTo(_swapToTokenAddress).balanceOf(msg.sender);
        require(_userBalance >= _amount, "SLSSwap: Insufficient balance");

        uint256 _userAllowance = ITokenSwapTo(_swapToTokenAddress).allowance(msg.sender, address(this));
        require(_userAllowance >= _amount, "SLSSwap: Need to allow the swap contract");

        ITokenSwapTo(_swapToTokenAddress).transferFrom(msg.sender, address(this), _amount);
        _tokenBalance = _tokenBalance.add(_amount);

        return true;
    }

    function tokenBalance () 
    external onlyOwner view returns (uint256) {
        return _tokenBalance;
    }

    function viewSwapHistoryOfAddress (
        address _addressToCheck
    ) external onlyOwner view returns (uint256) {
        require(_addressToCheck != address(0), "SLSSwap: Address is not valid");
        return (_swappedHistory[_addressToCheck]);
    }

    function swap (
        address _toSwapTokenAddress,
        uint256 _amount
    ) external nonReentrant returns (bool) {
        require(_toSwapTokenAddress == tokenToSwapAddress, "SLSSwap: This currency is not supported");
        require(_amount > 0, "SLSSwap: Amount is invalid");

        uint256 _userBalance = ITokenToSwap(_toSwapTokenAddress).balanceOf(msg.sender);
        require(_userBalance >= _amount, "SLSSwap: Insufficient balance");

        uint256 _userAllowance = ITokenToSwap(_toSwapTokenAddress).allowance(msg.sender, address(this));
        require(_userAllowance >= _amount, "SLSSwap: Need to allow the swap contract");

        require(_tokenBalance >= _amount, "SLSSwap: Insufficient balance of swap pool");

        ITokenToSwap(_toSwapTokenAddress).transferFrom(msg.sender, address(this), _amount);
        _swappedHistory[msg.sender] = _swappedHistory[msg.sender].add(_amount);
        _swappedBalance = _swappedBalance.add(_amount);

        ITokenSwapTo(tokenSwapToAddress).transfer(msg.sender, _amount);
        _tokenBalance = _tokenBalance.sub(_amount);

        emit Swap(msg.sender, _amount);
        return true;
    }

    function setToSwapToken (
        address _toSwapTokenAddress
    ) external onlyOwner returns (bool) {
        require(_toSwapTokenAddress != address(0), "SLSSwap: Address is invalid" );
        tokenToSwapAddress = _toSwapTokenAddress;
        return true;
    }

    function setSwapToToken (
        address _swapToTokenAddress
    ) external onlyOwner returns (bool) {
        require(_swapToTokenAddress != address(0), "SLSSwap: Address is invalid" );
        tokenSwapToAddress = _swapToTokenAddress;
        return true;
    }

    function withdrawSwappedToken (
        uint256 _amount
    ) external nonReentrant onlyOwner returns (bool) {
        require(_swappedBalance >= _amount, "SLSSwap: Not enough of tokens" );

        ITokenToSwap(tokenToSwapAddress).transfer(msg.sender, _amount);
        _swappedBalance = _swappedBalance.sub(_amount);

        return true;
    }

    function withdrawTokenBalance (
        uint256 _amount
    ) external nonReentrant onlyOwner returns (bool) {
        require(_tokenBalance >= _amount, "SLSSwap: Not enough of tokens");

        ITokenSwapTo(tokenSwapToAddress).transfer(msg.sender, _amount);
        _tokenBalance = _tokenBalance.sub(_amount);

        return true;
    }

    
}