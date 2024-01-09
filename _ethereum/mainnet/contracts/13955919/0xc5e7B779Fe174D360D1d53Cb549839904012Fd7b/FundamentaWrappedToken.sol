// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.8.9;

// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// steve@fundamenta.network

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./TokenInterface.sol";
import "./SecureContract.sol";

contract FundamentaWrappedToken is SecureContract, ERC20
{
    bytes32 public constant _MINTTO = keccak256("_MINTTO");
    bytes32 public constant _BURNFROM = keccak256("_BURNFROM");
    bytes32 public constant _BRIDGE_TX = keccak256("_BRIDGE_TX");

    event Wrap(address indexed user, uint256 amount, uint256 fee);
    event Unwrap(address indexed user, uint256 amount, uint256 fee);

    event Mint(address indexed user, uint256 amount, address agent);
    event Burn(address indexed user, uint256 amount, address agent);

    event FeeWithdraw(address indexed user, uint256 amount);

    using SafeERC20 for IERC20;

    IERC20 private _backingToken;
    TokenInterface private _FMTA;
    uint8 private _decimals;
    uint256 private _wrapFee;
    uint256 private _unwrapFee;
    uint256 private _accumulatedFee;
    uint256 private _fmtaWrapFee;
    uint256 private _fmtaUnwrapFee;
    uint256 private _totalBurn;

    modifier isBridge()
    {
        require(hasRole(_BRIDGE_TX, msg.sender), "SecureContract: Not Bridge - Permission denied");
        _;
    }

    constructor(address backingTokenContract, string memory name, string memory ticker, uint8 tokenDecimals, address fmtaAddress)
        ERC20(name, ticker)
    {
        require(backingTokenContract != address(0), "Wrapped Token: Backing token not configured");
        require(fmtaAddress != address(0), "Wrapped Token: FMTA token not configured");
        require(tokenDecimals != 0, "Wrapped Token: Token decimals not configured");

        _backingToken = IERC20(backingTokenContract);
        _FMTA = TokenInterface(fmtaAddress);

        _decimals = tokenDecimals;

        SecureContract.init();

        _setRoleAdmin(_MINTTO, _ADMIN);
        _setRoleAdmin(_BURNFROM, _ADMIN);
        _setRoleAdmin(_BRIDGE_TX, _ADMIN);

        _wrapFee = 0;
        _unwrapFee = 0;
        _accumulatedFee = 0;
        _fmtaWrapFee = 0;
        _fmtaUnwrapFee = 0;
        _totalBurn = 0;
    }
    
    function setFmtaWrapFee(uint256 newFee) public isAdmin
    {
        require(_fmtaWrapFee != newFee, "Wrapped Token: No action required");
        _fmtaWrapFee = newFee;
    }

    function setFmtaUnwrapFee(uint256 newFee) public isAdmin
    {
        require(_fmtaUnwrapFee != newFee, "Wrapped Token: No action required");
        _fmtaUnwrapFee = newFee;
    }

    function setWrapFee(uint256 newFee) public isAdmin
    {
        require(_wrapFee != newFee, "Wrapped Token: No action required");
        require(newFee <= 10000, "Wrapped Token: Fee exceeds 100%");
        _wrapFee = newFee;
    }

    function setUnwrapFee(uint256 newFee) public isAdmin
    {
        require(_unwrapFee != newFee, "Wrapped Token: No action required");
        require(newFee <= 10000, "Wrapped Token: Fee exceeds 100%");
        _unwrapFee = newFee;
    }

    function decimals() public override view returns (uint8) { return _decimals; }

    function queryFees() public view returns (uint256, uint256, uint256, uint256) {
        return (_fmtaWrapFee, _fmtaUnwrapFee, _wrapFee, _unwrapFee);
    }

    function queryAccumulatedFees() public view returns (uint256, uint256) {
        return (_accumulatedFee, _totalBurn);
    }

    function queryBackingToken() public view returns (IERC20) { return _backingToken; }

    function calculateWrapFee(uint256 amount) public view returns (uint256) { return (amount / 10000) * _wrapFee; }
    
    function calculateUnwrapFee(uint256 amount) public view returns (uint256) { return (amount / 10000) * _wrapFee; }

    function wrap(uint256 amount) public pause
    {
        if (_fmtaWrapFee > 0)
        {
            require(_FMTA.balanceOf(msg.sender) >= _fmtaWrapFee, "Wrapped Token: Insufficient FMTA balance");
            _FMTA.burnFrom(msg.sender, _fmtaWrapFee);
            _totalBurn += _fmtaWrapFee;
        }

        uint256 fee = calculateWrapFee(amount);
        require(_backingToken.balanceOf(msg.sender) >= amount, "Wrapped Token: Insufficient backing token balance");

        _backingToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount - fee);

        _accumulatedFee += fee;

        emit Wrap(msg.sender, amount, fee);
    }

    function unwrap(uint256 amount) public pause
    {
        if (_fmtaUnwrapFee > 0)
        {
            require(_FMTA.balanceOf(msg.sender) >= _fmtaUnwrapFee, "Wrapped Token: Insufficient FMTA balance");
            _FMTA.burnFrom(msg.sender, _fmtaUnwrapFee);
            _totalBurn += _fmtaUnwrapFee;
        }

        uint256 fee = calculateUnwrapFee(amount);
        require(balanceOf(msg.sender) >= amount, "Wrapped Token: Insufficient wrapped token balance");

        _burn(msg.sender, amount);
        _backingToken.safeTransfer(msg.sender, amount - fee);

        _accumulatedFee += fee;

        emit Unwrap(msg.sender, amount, fee);
    }

    function crossChainWrap(address user, uint256 amount) public isBridge pause returns (uint256)
    {
        if (_fmtaWrapFee > 0)
        {
            require(_FMTA.balanceOf(user) >= _fmtaWrapFee, "Wrapped Token: Insufficient FMTA balance");
            _FMTA.burnFrom(user, _fmtaWrapFee);
            _totalBurn += _fmtaWrapFee;
        }

        uint256 fee = calculateWrapFee(amount);
        require(_backingToken.balanceOf(user) >= amount, "Wrapped Token: Insufficient backing token balance");
        
        _backingToken.safeTransferFrom(user, address(this), amount);
        
        _accumulatedFee += fee;

        emit Wrap(user, amount, fee);

        return amount - fee;
    }

    function crossChainUnwrap(address user, uint256 amount) public isBridge pause
    {
        if (_fmtaUnwrapFee > 0)
        {
            require(_FMTA.balanceOf(user) >= _fmtaUnwrapFee, "Wrapped Token: Insufficient FMTA balance");
            _FMTA.burnFrom(user, _fmtaUnwrapFee);
            _totalBurn += _fmtaUnwrapFee;
        }

        uint256 fee = calculateUnwrapFee(amount);
        require(balanceOf(user) >= amount, "Wrapped Token: Insufficient wrapped token balance");

        _backingToken.safeTransfer(user, amount - fee);

        _accumulatedFee += fee;

        emit Unwrap(user, amount, fee);
    }

    function mintTo(address user, uint amount) public pause
    {
        require(hasRole(_MINTTO, msg.sender), "Wrapped Token: Permission denied. Missing MINTTO role");
        _mint(user, amount);
        emit Mint(user, amount, msg.sender);
    }

    function burnFrom(address user, uint amount) public pause
    {
        require(hasRole(_BURNFROM, msg.sender), "Wrapped Token: Permission denied. MISSING BURNFROM role");
        _burn(user, amount);
        emit Burn(user, amount, msg.sender);
    }

    function withdrawAccumulatedFee(address to) public isAdmin
    {
        require(_accumulatedFee > 0, "Wrapped Token: Accumulated fee = 0");
        _backingToken.safeTransfer(to, _accumulatedFee);
        uint256 temp = _accumulatedFee;
        _accumulatedFee = 0;

        emit FeeWithdraw(to, temp);
    }
}
