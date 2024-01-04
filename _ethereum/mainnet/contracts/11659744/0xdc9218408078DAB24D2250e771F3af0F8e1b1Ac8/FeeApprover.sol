// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol"; // for WETH
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract FeeApprover is Ownable {
    using SafeMath for uint256;

    function initialize(address _tokenUniswapPair, address _liquidVault) public onlyOwner {
        require(_tokenUniswapPair != address(0) && _liquidVault != address(0), "Zero addresses not allowed");
        require(!initiated, "FeeApprover: already initiated");

        paused = true;
        initiated = true;
        _setFeeDiscountTo(_tokenUniswapPair, 1000);
        _setFeeDiscountFrom(_tokenUniswapPair, 1000);
        _setFeeDiscountTo(_liquidVault, 1000);
        _setFeeDiscountFrom(_liquidVault, 1000);
    }

    uint8 public feePercentX100 = 10;
    bool paused;
    bool initiated;
    mapping(address => uint256) public discountFrom;
    mapping(address => uint256) public discountTo;
    mapping(address => uint256) public feeBlackList;

    // Once R3T is unpaused, it can never be paused
    function unPause() public onlyOwner {
        paused = false;
    }

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        require(
            _feeMultiplier <= 100,
            "R3T: percentage expressed as number between 0 and 100"
        );
        feePercentX100 = _feeMultiplier;
    }

    function setFeeBlackList(address _address, uint256 feeAmount)
        public
        onlyOwner
    {
        require(
            feeAmount <= 100,
            "R3T: percentage expressed as number between 0 and 100"
        );
        feeBlackList[_address] = feeAmount;
    }

    function setFeeDiscountTo(address _address, uint256 discount)
        public
        onlyOwner
    {
        _setFeeDiscountTo(_address, discount);
    }

    function _setFeeDiscountTo(address _address, uint256 discount) internal {
        require(
            discount <= 1000,
            "R3T: discount expressed as percentage between 0 and 1000"
        );
        discountTo[_address] = discount;
    }

    function setFeeDiscountFrom(address _address, uint256 discount)
        public
        onlyOwner
    {
        _setFeeDiscountFrom(_address, discount);
    }

    function _setFeeDiscountFrom(address _address, uint256 discount) internal {
        require(
            discount <= 1000,
            "R3T: discount expressed as percentage between 0 and 1000"
        );
        discountFrom[_address] = discount;
    }

    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        view
        returns (
            uint256 transferToAmount,
            uint256 transferToFeeDistributorAmount
        )
    {
        require(!paused, "R3T: system not yet initialized");
        uint256 fee;
        if (feeBlackList[sender] > 0) {
            fee = feeBlackList[sender].mul(amount).div(100);
        } else {
            fee = amount.mul(feePercentX100).div(100);
            uint256 totalDiscount = discountFrom[sender].mul(fee).div(1000) +
                discountTo[recipient].mul(fee).div(1000);
            fee = totalDiscount > fee ? 0 : fee - totalDiscount;
        }

        return (amount - fee, fee);
    }
}
