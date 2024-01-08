//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Blacklist.sol";
import "./Transfers.sol";

contract Compensation is Transfers, BlackList {

    address public stableCoin;
    uint public startTimestamp;

    uint public constant year = 365 days;
    uint public rewardRatePerSec;
    uint public lastApyTimestamp;

    mapping(address => uint) public pTokenPrices;
    address[] public pTokensList;

    struct Balance {
        uint amount;
        uint out;
    }

    mapping(address => Balance) public balances;
    mapping(address => mapping(address => uint)) public pTokenAmounts;

    uint[] public checkpoints;
    uint public totalAmount;

    constructor(
        address stableCoin_,
        uint startTimestamp_,
        uint rewardAPY_,
        uint lastApyTimestamp_
    ) {
        require(stableCoin_ != address(0), "Compensation::Constructor: stableCoin_ is 0");

        require(
            startTimestamp_ != 0
            && lastApyTimestamp_ !=0,
            "Compensation::Constructor: timestamp is 0"
        );

        require(
            startTimestamp_ > getBlockTimestamp()
            && lastApyTimestamp_ > startTimestamp_,
            "Compensation::Constructor: start timestamp must be more than current timestamp and less than lastApyTimestamp"
        );

        stableCoin = stableCoin_;
        startTimestamp = startTimestamp_;
        rewardRatePerSec = rewardAPY_ / year;
        lastApyTimestamp = lastApyTimestamp_;
    }

    function addPToken(address pToken, uint price) public onlyOwner returns (bool) {
        require(pTokenPrices[pToken] == 0, "pToken has already been added");

        pTokenPrices[pToken] = price;
        pTokensList.push(pToken);

        return true;
    }

    function addCheckpoint(uint stableCoinAmount) public onlyOwner returns (bool) {
        uint amountIn = doTransferIn(msg.sender, stableCoin, stableCoinAmount);

        if (amountIn > 0 ) {
            checkpoints.push(amountIn);
        }

        return true;
    }

    function withdraw(address token, uint amount) public onlyOwner returns (bool) {
        doTransferOut(token, msg.sender, amount);

        return true;
    }

    function addUserBalance(address user, address pToken, uint amount) public onlyOwner returns (bool) {
        compensationInternal(user, pToken, amount);

        return true;
    }

    function compensation(address pToken, uint pTokenAmount) public returns (bool) {
        require(getBlockTimestamp() < startTimestamp, "Compensation::compensation: you can convert pTokens before start timestamp only");
        require(pTokenPrices[pToken] != 0, "Compensation::compensation: pToken is not allowed");

        uint amount = doTransferIn(msg.sender, pToken, pTokenAmount);
        compensationInternal(msg.sender, pToken, amount);
        return true;
    }

    function compensationInternal(address user, address pToken, uint amount) internal returns (bool) {
        pTokenAmounts[user][pToken] += amount;
        uint stableTokenAmount = calcCompensationAmount(pToken, amount);
        balances[user].amount += stableTokenAmount;
        totalAmount += stableTokenAmount;

        return true;
    }

    function calcCompensationAmount(address pToken, uint amount) public view returns (uint) {
        uint price = pTokenPrices[pToken];

        uint pTokenDecimals = ERC20(pToken).decimals();
        uint stableDecimals = ERC20(stableCoin).decimals();
        uint factor;

        if (pTokenDecimals >= stableDecimals) {
            factor = 10**(pTokenDecimals - stableDecimals);
            return amount * price / factor / 1e18;
        } else {
            factor = 10**(stableDecimals - pTokenDecimals);
            return amount * price * factor / 1e18;
        }
    }

    function claimToken() public returns (bool) {
        require(getBlockTimestamp() > startTimestamp, "Compensation::claimToken: bad timing for the request");
        require(!isBlackListed[msg.sender], "Compensation::claimToken: user in black list");

        uint amount = calcClaimAmount(msg.sender);

        balances[msg.sender].out += amount;

        doTransferOut(stableCoin, msg.sender, amount);

        return true;
    }

    function calcUserAdditionAmount(address user) public view returns (uint) {
        uint amount = balances[user].amount;
        return calcAdditionAmount(amount);
    }

    function calcAdditionAmount(uint amount) public view returns (uint) {
        uint currentTimestamp = getBlockTimestamp();
        uint duration;

        if (currentTimestamp <= startTimestamp) {
            return 0;
        } else if (currentTimestamp > lastApyTimestamp) {
            duration = lastApyTimestamp - startTimestamp;
        } else if (lastApyTimestamp <= startTimestamp) {
            duration = 0;
        } else {
            duration = currentTimestamp - startTimestamp;
        }

        return amount * rewardRatePerSec * duration / 1e18;
    }

    function calcClaimAmount(address user) public view returns (uint) {
        uint amount = balances[user].amount;
        uint currentTimestamp = getBlockTimestamp();

        if (amount == 0 || amount == balances[user].out || currentTimestamp <= startTimestamp) {
            return 0;
        }

        uint additionalAmount = calcAdditionAmount(amount);
        uint additionalTotalAmount = calcAdditionAmount(totalAmount);

        uint allAmount = amount + additionalAmount;
        uint allTotalAmount = totalAmount + additionalTotalAmount;

        if (allAmount == 0 || allAmount == balances[user].out) {
            return 0;
        }

        uint claimAmount;

        for (uint i = 0; i < checkpoints.length; i++) {
            claimAmount += allAmount * checkpoints[i] / allTotalAmount;
        }

        if (claimAmount > allAmount) {
            return allAmount - balances[user].out;
        } else {
            return claimAmount - balances[user].out;
        }
    }

    function getCheckpointsLength() public view returns (uint) {
        return checkpoints.length;
    }

    function getPTokenList() public view returns (address[] memory) {
        return pTokensList;
    }

    function getPTokenListLength() public view returns (uint) {
        return pTokensList.length;
    }

    function getBlockTimestamp() public view virtual returns (uint) {
        return block.timestamp;
    }
}
