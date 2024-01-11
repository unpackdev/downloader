// SPDX-License-Identifier: GPL-3

pragma solidity =0.7.6;

import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IImpossibleWrappedToken.sol";
import "./IERC20.sol";

contract ImpossibleWrappedToken is IImpossibleWrappedToken, ReentrancyGuard {
    using SafeMath for uint256;

    string public override name;
    string public override symbol;
    uint8 public override decimals = 18;
    uint256 public override totalSupply;

    IERC20 public underlying;
    uint256 public underlyingBalance;
    uint256 public ratioNum;
    uint256 public ratioDenom;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(
        address _underlying,
        uint256 _ratioNum,
        uint256 _ratioDenom
    ) {
        underlying = IERC20(_underlying);
        ratioNum = _ratioNum;
        ratioDenom = _ratioDenom;
        string memory desc = string(abi.encodePacked(underlying.symbol()));
        name = string(abi.encodePacked('IF-Wrapped ', desc));
        symbol = string(abi.encodePacked('WIF ', desc));
    }

    // amt = amount of wrapped tokens
    function deposit(address dst, uint256 sendAmt) public override nonReentrant returns (uint256 wad) {
        TransferHelper.safeTransferFrom(address(underlying), msg.sender, address(this), sendAmt);
        uint256 receiveAmt = IERC20(underlying).balanceOf(address(this)).sub(underlyingBalance);
        wad = receiveAmt.mul(ratioNum).div(ratioDenom);
        balanceOf[dst] = balanceOf[dst].add(wad);
        totalSupply = totalSupply.add(wad);
        underlyingBalance = underlyingBalance.add(receiveAmt);
        emit Transfer(address(0), dst, wad);
    }

    // wad = amount of wrapped tokens
    function withdraw(address dst, uint256 wad) public override nonReentrant returns (uint256 transferAmt) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(wad);
        totalSupply = totalSupply.sub(wad);
        transferAmt = wad.mul(ratioDenom).div(ratioNum);
        TransferHelper.safeTransfer(address(underlying), dst, transferAmt);
        underlyingBalance = underlyingBalance.sub(transferAmt);
        emit Transfer(msg.sender, address(0), wad);
    }

    function amtToUnderlyingAmt(uint256 amt) public view override returns (uint256) {
        return amt.mul(ratioDenom).div(ratioNum);
    }

    function approve(address guy, uint256 wad) public override returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public override returns (bool) {
        require(dst != address(0x0), 'IF Wrapper: INVALID_DST');
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public override returns (bool) {
        require(balanceOf[src] >= wad, '');
        require(dst != address(0x0), 'IF Wrapper: INVALID_DST');

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, 'ImpossibleWrapper: INSUFF_ALLOWANCE');
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}
