//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Blacklist.sol";
import "./Transfers.sol";
import "./Interfaces.sol";

contract Refund is Transfers, BlackList {
    uint public startTimestamp;

    mapping(address => Base) public pTokens;
    address[] public pTokensList;

    struct Base {
        address baseToken;
        uint course;
    }

    mapping(address => mapping(address => uint)) public pTokenAmounts;
    mapping(address => address) public baseTokens;
    address[] public baseTokenList;

    struct Balance {
        uint amount;
        uint out;
    }

    mapping(address => mapping(address => Balance)) public balances;
    mapping(address => uint[]) public checkpoints;
    mapping(address => uint) public totalAmount;

    address public controller;
    address public pETH;
    address public calcPoolPrice;

    constructor(
        uint startTimestamp_,
        address controller_,
        address pETH_,
        address calcPoolPrice_
    ) {
        require(startTimestamp_ != 0, "Refund::Constructor: timestamp is 0");

        require(startTimestamp_ > getBlockTimestamp(), "Refund::Constructor: start timestamp must be more than current timestamp");

        require(
            controller_ != address(0)
            && pETH_ != address(0)
            && calcPoolPrice_ != address(0),
            "Service::Constructor: address is 0"
        );

        controller = controller_;
        pETH = pETH_;
        startTimestamp = startTimestamp_;
        calcPoolPrice = calcPoolPrice_;
    }

    function addRefundPair(address pToken, address baseToken_, uint course_) public onlyOwner returns (bool) {
        require(baseTokens[pToken] == address(0), "pToken has already been added");

        pTokens[pToken] = Base({baseToken: baseToken_, course: course_});
        baseTokens[pToken] = baseToken_;
        pTokensList.push(pToken);
        baseTokenList.push(baseToken_);

        return true;
    }

    function addTokensAndCheckpoint(address baseToken, uint baseTokenAmount) public onlyOwner returns (bool) {
        uint amountIn = doTransferIn(msg.sender, baseToken, baseTokenAmount);

        if (amountIn > 0 ) {
            checkpoints[baseToken].push(amountIn);
        }

        return true;
    }

    function withdraw(address token, uint amount) public onlyOwner returns (bool) {
        doTransferOut(token, msg.sender, amount);

        return true;
    }

    function addUserBalance(address user, address pToken, uint amount) public onlyOwner returns (bool) {
        refundInternal(user, pToken, amount);

        return true;
    }

    function refund(address pToken, uint pTokenAmount) public returns (bool) {
        require(getBlockTimestamp() < startTimestamp, "Refund::refund: you can convert pTokens before start timestamp only");
        require(pTokensIsAllowed(pToken), "Refund::refund: pToken is not allowed");

        uint pTokenAmountIn = doTransferIn(msg.sender, pToken, pTokenAmount);
        refundInternal(msg.sender, pToken, pTokenAmountIn);

        return true;
    }

    function refundInternal(address user, address pToken, uint amount) internal returns (bool) {
        pTokenAmounts[user][pToken] += amount;
        address baseToken = baseTokens[pToken];
        uint baseTokenAmount = calcRefundAmount(pToken, amount);
        balances[user][baseToken].amount += baseTokenAmount;
        totalAmount[baseToken] += baseTokenAmount;

        return true;
    }

    function calcRefundAmount(address pToken, uint amount) public view returns (uint) {
        uint course = pTokens[pToken].course;

        uint pTokenDecimals = ERC20(pToken).decimals();
        uint baseTokenDecimals = ERC20(pTokens[pToken].baseToken).decimals();
        uint factor;

        if (pTokenDecimals >= baseTokenDecimals) {
            factor = 10**(pTokenDecimals - baseTokenDecimals);
            return amount * course / factor / 1e18;
        } else {
            factor = 10**(baseTokenDecimals - pTokenDecimals);
            return amount * course * factor / 1e18;
        }
    }

    function claimToken(address pToken) public returns (bool) {
        require(getBlockTimestamp() > startTimestamp, "Refund::claimToken: bad timing for the request");
        require(!isBlackListed[msg.sender], "Refund::claimToken: user in black list");

        uint amount = calcClaimAmount(msg.sender, pToken);

        address baseToken = baseTokens[pToken];
        balances[msg.sender][baseToken].out += amount;

        doTransferOut(baseToken, msg.sender, amount);

        return true;
    }

    function calcClaimAmount(address user, address pToken) public view returns (uint) {
        address baseToken = baseTokens[pToken];
        uint amount = balances[user][baseToken].amount;

        if (amount == 0 || amount == balances[user][baseToken].out || getBlockTimestamp() <= startTimestamp ) {
            return 0;
        }

        uint claimAmount;

        for (uint i = 0; i < checkpoints[baseToken].length; i++) {
            claimAmount += amount * checkpoints[baseToken][i] / totalAmount[baseToken];
        }

        if (claimAmount > amount) {
            return amount - balances[user][baseToken].out;
        } else {
            return claimAmount - balances[user][baseToken].out;
        }
    }

    function getCheckpointsLength(address baseToken_) public view returns (uint) {
        return checkpoints[baseToken_].length;
    }

    function getPTokenList() public view returns (address[] memory) {
        return pTokensList;
    }

    function getPTokenListLength() public view returns (uint) {
        return pTokensList.length;
    }

    function getBaseTokenList() public view returns (address[] memory) {
        return baseTokenList;
    }

    function getBaseTokenListLength() public view returns (uint) {
        return baseTokenList.length;
    }

    function getAllTotalAmount() public view returns (uint) {
        uint allAmount;
        uint price;
        address baseToken;

        for(uint i = 0; i < baseTokenList.length; i++ ) {
            baseToken = baseTokenList[i];
            price = pTokensList[i] == pETH ? CalcPoolPrice(calcPoolPrice).getPoolPriceInUSD(pETH) : CalcPoolPrice(calcPoolPrice).getPoolPriceInUSD(baseToken);
            allAmount += price * totalAmount[baseToken] / 1e18 / (10 ** ERC20(baseToken).decimals());
        }

        return allAmount;
    }

    function getUserUsdAmount(address user) public view returns (uint) {
        uint userTotalAmount;
        uint price;
        address baseToken;

        for(uint i = 0; i < baseTokenList.length; i++ ) {
            baseToken = baseTokenList[i];

            price = pTokensList[i] == pETH ? CalcPoolPrice(calcPoolPrice).getPoolPriceInUSD(pETH) : CalcPoolPrice(calcPoolPrice).getPoolPriceInUSD(baseToken);
            userTotalAmount += price * balances[user][baseToken].amount / 1e18 / (10 ** ERC20(baseToken).decimals());
        }

        return userTotalAmount;
    }

    function pTokensIsAllowed(address pToken_) public view returns (bool) {
        for (uint i = 0; i < pTokensList.length; i++ ) {
            if (pTokensList[i] == pToken_) {
                return true;
            }
        }

        return false;
    }

    function getAvailableLiquidity() public view returns (uint) {
        uint availableLiquidity;
        uint price;
        address baseToken;

        for(uint i = 0; i < baseTokenList.length; i++ ) {
            baseToken = baseTokenList[i];
            price = ControllerInterface(controller).getOracle().getPriceInUSD(baseToken);
            availableLiquidity += price * ERC20(baseToken).balanceOf(address(this)) / 1e18  / (10 ** ERC20(baseToken).decimals());
        }

        return availableLiquidity;
    }

    function getBlockTimestamp() public view virtual returns (uint) {
        return block.timestamp;
    }
}
