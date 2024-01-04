//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./IXVIX.sol";
import "./IBurnVault.sol";
import "./IGmtIou.sol";

contract GmtSwap is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 constant PRECISION = 1000000;

    bool public isInitialized;
    bool public isSwapActive = true;

    address public xvix;
    address public uni;
    address public xlge;
    address public gmtIou;
    address public weth;
    address public dai;
    address public wethDaiUni;
    address public wethXvixUni;
    address public allocator;
    address public burnVault;

    uint256 public gmtPrice;
    uint256 public xlgePrice;
    uint256 public minXvixPrice;
    uint256 public unlockTime;

    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "GmtSwap: forbidden");
        _;
    }

    function initialize(
        address[] memory _addresses,
        uint256 _gmtPrice,
        uint256 _xlgePrice,
        uint256 _minXvixPrice,
        uint256 _unlockTime
    ) public onlyGov {
        require(!isInitialized, "GmtSwap: already initialized");
        isInitialized = true;

        xvix = _addresses[0];
        uni = _addresses[1];
        xlge = _addresses[2];
        gmtIou = _addresses[3];

        weth = _addresses[4];
        dai = _addresses[5];
        wethDaiUni = _addresses[6];
        wethXvixUni = _addresses[7];

        allocator = _addresses[8];
        burnVault = _addresses[9];

        gmtPrice = _gmtPrice;
        xlgePrice = _xlgePrice;
        minXvixPrice = _minXvixPrice;
        unlockTime = _unlockTime;
    }

    function setGov(address _gov) public onlyGov {
        gov = _gov;
    }

    function extendUnlockTime(uint256 _unlockTime) public onlyGov {
        require(_unlockTime > unlockTime, "GmtSwap: invalid unlockTime");
        unlockTime = _unlockTime;
    }

    function withdraw(address _token, uint256 _tokenAmount, address _receiver) public onlyGov {
        require(block.timestamp > unlockTime, "GmtSwap: unlockTime not yet passed");
        IERC20(_token).transfer(_receiver, _tokenAmount);
    }

    function swap(
        address _token,
        uint256 _tokenAmount,
        uint256 _allocation,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public nonReentrant {
        require(isSwapActive, "GmtSwap: swap is no longer active");
        require(_tokenAmount > 0, "GmtSwap: invalid tokenAmount");
        require(_allocation > 0, "GmtSwap: invalid gmtAllocation");

        _verifyAllocation(msg.sender, _allocation, _v, _r, _s);
        (uint256 transferAmount, uint256 mintAmount) = getSwapAmounts(
            msg.sender, _token, _tokenAmount, _allocation);
        require(transferAmount > 0, "GmtSwap: invalid transferAmount");
        require(mintAmount > 0, "GmtSwap: invalid mintAmount");

        IXVIX(xvix).rebase();
        IERC20(_token).transferFrom(msg.sender, address(this), transferAmount);

        if (_token == xvix) {
            IERC20(_token).approve(burnVault, transferAmount);
            IBurnVault(burnVault).deposit(transferAmount);
        }

        IGmtIou(gmtIou).mint(msg.sender, mintAmount);
    }

    function endSwap() public onlyGov {
        isSwapActive = false;
    }

    function getSwapAmounts(
        address _account,
        address _token,
        uint256 _tokenAmount,
        uint256 _allocation
    ) public view returns (uint256, uint256) {
        require(_token == xvix || _token == uni || _token == xlge, "GmtSwap: unsupported token");
        uint256 tokenPrice = getTokenPrice(_token);

        uint256 transferAmount = _tokenAmount;
        uint256 mintAmount = _tokenAmount.mul(tokenPrice).div(gmtPrice);

        uint256 gmtIouBalance = IERC20(gmtIou).balanceOf(_account);
        uint256 maxMintAmount = _allocation.sub(gmtIouBalance);

        if (mintAmount > maxMintAmount) {
            mintAmount = maxMintAmount;
            // round up the transferAmount
            transferAmount = mintAmount.mul(gmtPrice).mul(10).div(tokenPrice).add(9).div(10);
        }

        return (transferAmount, mintAmount);
    }

    function getTokenPrice(address _token) public view returns (uint256) {
        if (_token == xlge) {
            return xlgePrice;
        }
        if (_token == xvix) {
            return getXvixPrice();
        }
        if (_token == uni) {
            return getUniPrice();
        }
        revert("GmtSwap: unsupported token");
    }

    function getEthPrice() public view returns (uint256) {
        uint256 wethBalance = IERC20(weth).balanceOf(wethDaiUni);
        uint256 daiBalance = IERC20(dai).balanceOf(wethDaiUni);
        return daiBalance.mul(PRECISION).div(wethBalance);
    }

    function getXvixPrice() public view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        uint256 wethBalance = IERC20(weth).balanceOf(wethXvixUni);
        uint256 xvixBalance = IERC20(xvix).balanceOf(wethXvixUni);
        uint256 price = wethBalance.mul(ethPrice).div(xvixBalance);
        if (price < minXvixPrice) {
            return minXvixPrice;
        }
        return price;
    }

    function getUniPrice() public view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        uint256 wethBalance = IERC20(weth).balanceOf(wethXvixUni);
        uint256 supply = IERC20(wethXvixUni).totalSupply();
        return wethBalance.mul(ethPrice).mul(2).div(supply);
    }

    function _verifyAllocation(
        address _account,
        uint256 _allocation,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private view {
        bytes32 message = keccak256(abi.encodePacked(
            "GmtSwap:GmtAllocation",
            _account,
            _allocation
        ));
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            message
        ));

        require(
            allocator == ecrecover(messageHash, _v, _r, _s),
            "GmtSwap: invalid signature"
        );
    }
}
