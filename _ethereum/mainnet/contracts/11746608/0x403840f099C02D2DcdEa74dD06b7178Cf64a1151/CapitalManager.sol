// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./ICapitalManager.sol";
import "./ICapitalPool.sol";

import "./Ownable.sol";
import "./SafeMath.sol";

contract CapitalManager is ICapitalManager, Ownable {
    using SafeMath for uint;
    ICapitalPool public capitalPool;

    address public feeRecipient;
    uint public override feeRate = 5000; // 5%
    uint public override BASE = 100000;

    bool public stopChanges;
    
    mapping(address => bool) public frontContracts;

    constructor(ICapitalPool cp) public {
        _setCapitalPool(cp);
        feeRecipient = msg.sender;
    }

    function stopChangesForever() external onlyOwner {
        stopChanges = true;
    }

    function setCapitalPool(ICapitalPool cp) external onlyOwner {
        _setCapitalPool(cp);
    }

    function setFrontContract(address fc, bool _approved) external onlyOwner {
        require(!stopChanges, "!stopChanges");
        require(fc != address(0), "2ndary::CapitalManager::setFrontContract::invalid-manager");
        frontContracts[fc] = _approved;
    }

    function setFeeRate(uint newFeeRate) external onlyOwner {
        feeRate = newFeeRate;
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        feeRecipient = newFeeRecipient;
    }

    function payOption(address to, uint premium) external override onlyFrontContract {
        ICapitalPool cp = capitalPool;
        uint totalBalance = cp.totalBalance();
        uint availableBalance = cp.availableBalance();
        require(availableBalance >= premium && (availableBalance.mul(10) >= totalBalance.mul(2)), "2ndary::CapitalPool::payOption::not-enough-available-balance");
        
        uint fee = premium.mul(feeRate).div(BASE);
        cp.sendTo(address(to), premium.sub(fee));
        cp.sendTo(feeRecipient, fee);

        cp.updateInvestedBalance(true, premium);

        emit PayOption(to, premium);
    }

    // to be called after sending payout to this contract
    // reduces investedBalance (it is already realised)
    function receivePayout(address from, uint tokenId, uint premium, uint payout, bool isOptionSale) external payable override onlyFrontContract {
        ICapitalPool cp = capitalPool;
        // payout can come from option sale (another user has bought an option from the pool)
        // or from an option exercise
        payable(address(cp)).transfer(payout);
        cp.updateInvestedBalance(false, premium);
        emit PL(tokenId, premium, payout, isOptionSale);

        if(isOptionSale){
            uint fee = payout.mul(feeRate).div(BASE);
            payable(feeRecipient).transfer(fee);
        }
    }

    function refundGas(address account, uint amount) external override onlyFrontContract {
        capitalPool.sendTo(account, amount);
    }

    function unlockBalance(uint tokenId, uint premium) external override onlyFrontContract {
        capitalPool.updateInvestedBalance(false, premium);

        emit PL(tokenId, premium, 0, false);
    }

    function _setCapitalPool(ICapitalPool cp) internal {
        capitalPool = cp;
    }

    modifier onlyFrontContract {
        require(frontContracts[msg.sender], "2ndary::CapitalManager::not-allowed");
        _;
    }
}