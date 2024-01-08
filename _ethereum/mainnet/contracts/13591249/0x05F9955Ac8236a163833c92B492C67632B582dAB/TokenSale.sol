// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./SafeCast.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./IAggregatorV3Interface.sol";
import "./IWETH.sol";

contract TokenSale is Ownable {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Deposited(address depositor, TokenData tokenInfo);
    event Withdrawn(address withdrawer, TokenData[] tokenInfo);
    event SupportedTokensAdded(SupportedTokenData[] tokenData);
    event TokensAllocated(TokenData tokenData);
    event TreasuryTransfer(TokenData[] tokens);

    struct TokenData {
        address token;
        uint256 amount;
    }

    struct AccountData {
        address token;
        uint256 currentBalance;
    }

    struct SupportedTokenData {
        address token;
        IAggregatorV3Interface oracle;
    }

    struct SaleSchedule {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    address public immutable WETH;
    address public immutable treasury;

    EnumerableSet.AddressSet private supportedTokens;
    SaleSchedule public saleSchedule;

    uint256 public raiseCapUSD;
    uint256 public totalRaisedUSD;

    TokenData public saleToken;
    bool public transferredToTreasury;

    mapping(address => AccountData) public accountData;
    mapping(address => IAggregatorV3Interface) public oracles;
    mapping(address => uint256) public rates;
    mapping(address => uint256) public totalRaisedToken;

    constructor(
        // solhint-disable-next-line
        address _WETH,
        address _treasury
    ) {
        require(_WETH != address(0), "INVALID_WETH");
        require(_treasury != address(0), "INVALID_TREASURY");

        WETH = _WETH;
        treasury = _treasury;
    }

    receive() external payable {
        require(msg.sender == WETH);
    }

    function deposit(TokenData memory tokenInfo) external payable {
        require(
            block.timestamp >= saleSchedule.startTimestamp &&
                block.timestamp < saleSchedule.endTimestamp,
            "DEPOSITS_NOT_ACCEPTED"
        );

        TokenData memory data = tokenInfo;
        address token = data.token;
        uint256 tokenAmount = data.amount;
        require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
        require(tokenAmount > 0, "INVALID_AMOUNT");

        AccountData storage tokenAccountData = accountData[msg.sender];

        if (tokenAccountData.token == address(0)) {
            tokenAccountData.token = token;
        }
        require(tokenAccountData.token == token, "SINGLE_ASSET_DEPOSITS");

        // Convert ETH to WETH if ETH is passed in, otherwise treat WETH as a regular ERC20
        if (token == WETH && msg.value > 0) {
            require(tokenAmount == msg.value, "INVALID_MSG_VALUE");
            IWETH(WETH).deposit{value: tokenAmount}();
        } else {
            require(msg.value == 0, "NO_ETH");
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
        }

        tokenAccountData.currentBalance = tokenAccountData.currentBalance.add(
            tokenAmount
        );
        totalRaisedToken[token] = totalRaisedToken[token].add(tokenAmount);

        emit Deposited(msg.sender, tokenInfo);
    }

    function withdraw(bool asETH) external {
        require(
            saleSchedule.endTimestamp > 0 &&
                block.timestamp >= saleSchedule.endTimestamp,
            "SALE_ONGOING"
        );
        require(saleToken.amount > 0, "WITHDRAWALS_NOT_ENABLED");

        AccountData memory account = accountData[msg.sender];
        require(account.currentBalance > 0, "NOT_DEPOSITED");

        TokenData[] memory withdrawData;

        uint256 cap = raiseCapUSD;
        uint256 totalRaise = totalRaisedUSD;
        if (cap > 0) {
            withdrawData = new TokenData[](2);
            uint256 validAmount = account.currentBalance.mul(cap).div(
                totalRaise
            );
            uint256 toRefund = account.currentBalance.sub(validAmount);
            uint256 balance = IERC20(account.token).balanceOf(address(this));

            //in case of rounding error
            if (toRefund > balance) toRefund = balance;

            if (asETH && account.token == address(WETH)) {
                IWETH(WETH).withdraw(toRefund);
                payable(msg.sender).transfer(toRefund);
            } else IERC20(account.token).safeTransfer(msg.sender, toRefund);

            withdrawData[0] = TokenData(account.token, toRefund);
        } else withdrawData = new TokenData[](1);

        uint256 depositedValue = rates[account.token]
            .mul(account.currentBalance)
            .div(10**ERC20(account.token).decimals());
        uint256 toSend = depositedValue.mul(saleToken.amount).div(totalRaise);
        IERC20(saleToken.token).safeTransfer(msg.sender, toSend);

        delete accountData[msg.sender];

        withdrawData[withdrawData.length - 1] = TokenData(
            saleToken.token,
            toSend
        );

        emit Withdrawn(msg.sender, withdrawData);
    }

    function addSupportedTokens(SupportedTokenData[] memory tokensToSupport)
        external
        onlyOwner
    {
        require(
            saleSchedule.startTimestamp == 0 ||
                block.timestamp < saleSchedule.startTimestamp,
            "SALE_STARTED"
        );

        uint256 tokensLength = tokensToSupport.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            SupportedTokenData memory data = tokensToSupport[i];
            require(supportedTokens.add(data.token), "TOKEN_EXISTS");

            oracles[data.token] = data.oracle;
        }
        emit SupportedTokensAdded(tokensToSupport);
    }

    function setupSaleSchedule(SaleSchedule memory settings)
        external
        onlyOwner
    {
        require(supportedTokens.length() > 0, "NO_SUPPORTED_TOKENS");
        require(settings.startTimestamp >= block.timestamp, "INVALID_START");
        require(settings.endTimestamp > settings.startTimestamp, "INVALID_END");

        saleSchedule = settings;
    }

    function allocateTokens(TokenData memory saleTokenData, uint256 valueCapUSD)
        external
        onlyOwner
    {
        require(
            saleSchedule.endTimestamp > 0 &&
                block.timestamp >= saleSchedule.endTimestamp,
            "SALE_ONGOING"
        );
        require(saleToken.token == address(0), "ALREADY_SET");
        require(saleTokenData.amount > 0, "INVALID_AMOUNT");
        require(saleTokenData.token != address(0), "INVALID_TOKEN");

        IERC20(saleTokenData.token).safeTransferFrom(
            msg.sender,
            address(this),
            saleTokenData.amount
        );

        saleToken = saleTokenData;

        uint256 value;
        for (uint256 i = 0; i < supportedTokens.length(); i++) {
            address token = supportedTokens.at(i);

            uint256 rateUSD = oracles[token].latestAnswer().toUint256();
            uint256 tokenDecimals = ERC20(token).decimals();
            value += (totalRaisedToken[token].mul(rateUSD)).div(
                10**tokenDecimals
            ); //Chainlink USD prices are always to 8

            rates[token] = rateUSD;
        }

        if (value > valueCapUSD) {
            raiseCapUSD = valueCapUSD;
        }

        totalRaisedUSD = value;

        emit TokensAllocated(saleTokenData);
    }

    function transferToTreasury() external onlyOwner {
        require(!transferredToTreasury, "ALREADY_TRANSFERRED");
        require(saleToken.token != address(0), "TOKEN_NOT_ALLOCATED");

        uint256 cap = raiseCapUSD;
        uint256 raisedUSD = totalRaisedUSD;
        TokenData[] memory tokens = new TokenData[](supportedTokens.length());

        for (uint256 i = 0; i < supportedTokens.length(); i++) {
            address token = supportedTokens.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (cap == 0) {
                IERC20(token).safeTransfer(treasury, balance);
                tokens[i] = TokenData(token, balance);
            } else {
                uint256 toSend = totalRaisedToken[token].mul(cap).div(
                    raisedUSD
                );

                //in case of rounding error
                if (toSend > balance) toSend = balance;

                IERC20(token).safeTransfer(treasury, toSend);
                tokens[i] = TokenData(token, toSend);
            }
        }

        transferredToTreasury = true;

        emit TreasuryTransfer(tokens);
    }

    function getSupportedTokens()
        external
        view
        returns (address[] memory tokens)
    {
        uint256 tokensLength = supportedTokens.length();
        tokens = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            tokens[i] = supportedTokens.at(i);
        }
    }

    function getTokenOracles(address[] memory tokens)
        external
        view
        returns (IAggregatorV3Interface[] memory oracleAddresses)
    {
        uint256 tokensLength = tokens.length;
        oracleAddresses = new IAggregatorV3Interface[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
            oracleAddresses[i] = oracles[tokens[i]];
        }
    }
}
