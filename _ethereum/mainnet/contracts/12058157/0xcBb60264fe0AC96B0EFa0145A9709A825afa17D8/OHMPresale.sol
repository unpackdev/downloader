// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20Mintable.sol";
import "./IERC20Burnable.sol";
import "./FullMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract OHMPreSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public aOHM;
    address public DAI;
    address public addressToSendDai;

    uint256 public salePrice;
    uint256 public totalWhiteListed;
    uint256 public endOfSale;

    bool public saleStarted;

    mapping(address => bool) boughtOHM;
    mapping(address => bool) whiteListed;

    function whiteListBuyers(address[] memory _buyers)
        external
        onlyOwner()
        returns (bool)
    {
        require(saleStarted == false, "Already initialized");

        totalWhiteListed = totalWhiteListed.add(_buyers.length);

        for (uint256 i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }

        return true;
    }

    function initialize(
        address _addressToSendDai,
        address _dai,
        address _aOHM,
        uint256 _salePrice,
        uint256 _saleLength
    ) external onlyOwner() returns (bool) {
        require(saleStarted == false, "Already initialized");

        aOHM = _aOHM;
        DAI = _dai;

        salePrice = _salePrice;

        endOfSale = _saleLength.add(block.timestamp);

        saleStarted = true;

        addressToSendDai = _addressToSendDai;

        return true;
    }

    function getAllotmentPerBuyer() public view returns (uint256) {
        return IERC20(aOHM).balanceOf(address(this)).div(totalWhiteListed);
    }

    function purchaseaOHM(uint256 _amountDAI) external returns (bool) {
        require(saleStarted == true, "Not started");
        require(whiteListed[msg.sender] == true, "Not whitelisted");
        require(boughtOHM[msg.sender] == false, "Already participated");
        require(block.timestamp < endOfSale, "Sale over");

        boughtOHM[msg.sender] = true;

        uint256 _purchaseAmount = _calculateSaleQuote(_amountDAI);

        require(_purchaseAmount <= getAllotmentPerBuyer(), "More than alloted");
        totalWhiteListed = totalWhiteListed.sub(1);

        IERC20(DAI).safeTransferFrom(msg.sender, addressToSendDai, _amountDAI);
        IERC20(aOHM).safeTransfer(msg.sender, _purchaseAmount);

        return true;
    }

    function sendRemainingaOHM(address _sendaOHMTo)
        external
        onlyOwner()
        returns (bool)
    {
        require(saleStarted == true, "Not started");
        require(block.timestamp >= endOfSale, "Not ended");

        IERC20(aOHM).safeTransfer(
            _sendaOHMTo,
            IERC20(aOHM).balanceOf(address(this))
        );

        return true;
    }

    function _calculateSaleQuote(uint256 paymentAmount_)
        internal
        view
        returns (uint256)
    {
        return uint256(1e9).mul(paymentAmount_).div(salePrice);
    }

    function calculateSaleQuote(uint256 paymentAmount_)
        external
        view
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }
}
