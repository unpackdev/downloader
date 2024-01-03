// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBMon.sol";
import "./IUniswapV2Helper.sol";

contract BMonPresale is Ownable {
    using SafeMath for uint256;

    event InvestmentSucceeded(address sender, uint256 weiAmount, uint256 bmonAmount);

    address public immutable bmonAddress; // address of $BMON token
    address payable public immutable teamAddress; // address where invested ETH will be transfered to
    uint256 public presaleWeiSupplyLeft; // how many WEI are still available in presale

    bool public isPresaleActive = false; // investing is only allowed if presale is active
    bool public wasPresaleEnded = false; // indicates that presale is ended

    IBMon private immutable bmon;

    constructor(
        address _bmonAddress,
        address _teamAddress,
        uint256 _presaleEthSupply
    ) public {
        // Init Bmon
        bmonAddress = _bmonAddress;
        bmon = IBMon(_bmonAddress);

        // Init Team Address
        teamAddress = payable(_teamAddress);

        // Init cap
        presaleWeiSupplyLeft = _presaleEthSupply * 1 ether;
    }

    modifier presaleActive() {
        require(isPresaleActive, "Presale is currently not active.");
        _;
    }

    modifier presaleNotEnded() {
        require(!wasPresaleEnded, "Presale was ended.");
        _;
    }

    modifier presaleSupplyAvailable() {
        require(presaleWeiSupplyLeft > 0, "Presale cap has been reached.");
        _;
    }

    modifier presaleSupplyNotExceeded() {
        require(msg.value <= presaleWeiSupplyLeft, "The amount of ETH sent exceeds the ETH supply left in presale.");
        _;
    }

    function setIsPresaleActive(bool _isPresaleActive) external onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    receive() external payable
        presaleActive
        presaleNotEnded
        presaleSupplyAvailable
        presaleSupplyNotExceeded
    {
        uint256 _amount = msg.value;

        require (_amount > 0, 'need _amount > 0');

        // Transfer $BMON to buyer
        uint256 bmonAmount = _amount.mul(20); // 1 ETH = 20 $BMON

        bmon.transfer(_msgSender(), bmonAmount);

        // Log
        bmon.logPresaleParticipants(_msgSender(), bmonAmount);

        presaleWeiSupplyLeft = presaleWeiSupplyLeft.sub(_amount);

        emit InvestmentSucceeded(_msgSender(), msg.value, bmonAmount);
    }

    function endPresale() external onlyOwner presaleNotEnded {
        teamAddress.transfer(address(this).balance); // transfer ETH to team address

        wasPresaleEnded = true; // presale is ended so endPresale can't be called again
        isPresaleActive = false; // presale should not be active anymore
    }
}