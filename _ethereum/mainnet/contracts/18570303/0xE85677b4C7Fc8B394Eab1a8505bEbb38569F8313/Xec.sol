// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ABDKMath64x64.sol";
import "./IBurnRedeemable.sol";
import "./XecERC20.sol";
import "./GDXen.sol";
import "./XENCrypto.sol";

contract Xec is Context, ReentrancyGuard, Ownable {
    using SafeERC20 for XecERC20;
    using Math for uint256;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    // 0.0002 M
    uint256 public constant M = 2 ether / 10000;
    // 0.006 T
    uint256 public constant awardThreshold = 6 ether / 1000;

    uint256 public constant xecLockTime = 1 days;

    uint256 public constant xecMaxLockTime = 10 days;

    uint256 public constant A = 106;

    uint256 public constant aDecimal = 1e2;
    XecERC20 public xec;
    GDXen public gdxen;
    XENCrypto public xen;

    uint256 public totalBurnedGarbage;

    address[] public garbageTokens;

    mapping(address => uint256) public accClaimableXec;

    mapping(address => string) public garbageSymbols;

    mapping(address => uint256) public E_0;

    mapping(address => uint256) public lastBurnedTimeToClaim;

    event BurnGarbageToken(
        address indexed userAddress,
        uint256 garbageNumber,
        uint256 xecAmount
    );

    constructor(address xenAddress) {
        xec = new XecERC20();
        xen = XENCrypto(xenAddress);
    }

    function setGdxen(address _gdxen) external onlyOwner {
        require(_gdxen != address(0), "Xec: zero address");
        gdxen = GDXen(_gdxen);
    }

    function createGarbageLists(
        address _garbageAddress,
        uint256 _E_0
    ) external onlyOwner {
        require(_garbageAddress != address(0), "Xec: zero address");
        require(_E_0 > 0, "Xec: E_0 must be greater than 0");

        require(E_0[_garbageAddress] == 0, "Xec: garbage token already exists");

        garbageTokens.push(_garbageAddress);

        garbageSymbols[_garbageAddress] = IERC20Metadata(_garbageAddress)
            .symbol();

        E_0[_garbageAddress] = _E_0;
    }

    function onTokenBurned(address user, uint256 amount) external {
        require(msg.sender == address(xen), "Xec: caller is not XENCrypto");
    }

    function burnGarbage(
        address _garbageAddress,
        uint256 _amount,
        address _to
    ) public payable nonReentrant {
        require(_garbageAddress != address(0), "Xec: zero address");
        require(_amount > 0, "Xec: _amount must be greater than 0");

        require(
            IERC20(_garbageAddress).balanceOf(_msgSender()) >= _amount,
            "Xec: insufficient balance"
        );

        uint256 xecAmount = getBurnedXec(_garbageAddress, _amount);
        if (_garbageAddress == address(xen)) {
            IBurnableToken(xen).burn(_msgSender(), _amount);
        } else {
            IERC20(_garbageAddress).transferFrom(
                _msgSender(),
                address(0x000000000000000000000000000000000000dEaD),
                _amount
            );
        }

        uint256 userFee = getXecFee(xecAmount);

        require(msg.value >= userFee, "Xec: insufficient fee");

        if (msg.value >= awardThreshold) {
            xecAmount += xecAmount / 5;
        }

        totalBurnedGarbage += _amount;

        lastBurnedTimeToClaim[_to] = block.timestamp + getXecLockTime();

        accClaimableXec[_to] += xecAmount;

        emit BurnGarbageToken(_to, _amount, xecAmount);
    }

    function burnXenFromGdxen(uint256 _amount, address _to) external payable {
        require(msg.sender == address(gdxen), "Xec: caller is not GDXen");

        uint256 xecAmount = getBurnedXec(address(xen), _amount);

        totalBurnedGarbage += _amount;

        lastBurnedTimeToClaim[_to] = block.timestamp + getXecLockTime();

        accClaimableXec[_to] += xecAmount;
    }

    function claimXec() external nonReentrant {
        require(accClaimableXec[_msgSender()] > 0, "Xec: no claimable XEC");

        require(
            block.timestamp >= lastBurnedTimeToClaim[_msgSender()],
            "Xec: XEC is locked"
        );

        uint256 claimableXec = accClaimableXec[_msgSender()];

        accClaimableXec[_msgSender()] = 0;

        xec.mintReward(_msgSender(), claimableXec);
    }

    function awardXec(address _to) external nonReentrant {
        require(msg.sender == address(gdxen), "Xec: caller is not GDXen");

        accClaimableXec[_to] += 10 ether;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        sendViaCall(payable(owner()), balance);
    }

    function sendViaCall(address payable to, uint256 amount) internal {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Xec: failed to send amount");
    }

    function getBurnedXec(
        address _garbageAddress,
        uint256 _amount
    ) public view returns (uint256) {
        require(E_0[_garbageAddress] > 0, "Xec: E_0 must be greater than 0");

        uint256 decimals = IERC20Metadata(_garbageAddress).decimals();

        uint256 xecAmount = (_amount * E_0[_garbageAddress]) / 10 ** decimals;
        return xecAmount;
    }

    function getXecFee(uint256 _xecAmount) public view returns (uint256) {
        uint256 _M = M;
        uint256 _A = A;
        uint256 _aDecimal = aDecimal;

        uint256 currentCycle = Math.min(GDXen(gdxen).getCurrentCycle(), 30);

        uint256 fee = (_M *
            ((1 * _aDecimal ** (2 + currentCycle)) / (_A ** currentCycle))) /
            _aDecimal ** 2;

        uint256 totalFee = (fee * _xecAmount) / 10 ** XecERC20(xec).decimals();
        return totalFee;
    }

    function getXecLockTime() public view returns (uint256) {
        uint256 lockTime = xecLockTime;

        uint256 maxLockTime = xecMaxLockTime;

        uint256 currentCycle = GDXen(gdxen).getCurrentCycle();

        if (currentCycle > 0) {
            lockTime += (currentCycle / 10) * lockTime;
        }

        return Math.min(lockTime, maxLockTime);
    }

    function getAllGarbageTokens() public view returns (address[] memory) {
        return garbageTokens;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IBurnRedeemable).interfaceId;
    }
}
