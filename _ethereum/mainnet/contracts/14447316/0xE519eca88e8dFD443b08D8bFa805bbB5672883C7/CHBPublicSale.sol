//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./OracleWrapper.sol";

contract CHBPublicSale is Ownable, ReentrancyGuard {
    uint256 public totalTokenSold;
    uint256 public totalUSDTRaised;
    uint256 public tokenDecimal;
    uint8 public defaultPhase;
    uint8 public totalPhases;
    address public tokenAddress;

    address public receiverAddress = 0xABDe245ef6F5875c3F19d5f699c7A787050cAF5f;

    address public USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDTOracleAddress =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public BNBorETHOracleAddress =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

   

    /* ================ STRUCT SECTION ================ */
    // Stores phases
    struct Phases {
        uint256 tokenSold;
        uint256 tokenLimit;
        uint32 startTime;
        uint32 expirationTimestamp;
        uint32 price; // 10 ** 2
        bool isComplete;
    }
    mapping(uint256 => Phases) public phaseInfo;

    /* ================ EVENT SECTION ================ */
    // Emits when tokens are bought
    event TokensBought(
        address buyerAddress,
        uint256 buyAmount,
        uint256 tokenAmount,
        uint32 buyTime
    );

    /* ================ CONSTRUCTOR SECTION ================ */
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;

        totalPhases = 6;
        tokenDecimal = uint256(10**Token(tokenAddress).decimals());
        uint32 currenTimeStamp = uint32(block.timestamp);

        phaseInfo[0] = Phases({
            tokenLimit: 200_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: currenTimeStamp,
            expirationTimestamp: currenTimeStamp + 60 days, // 2 Months
            price: 1,
            isComplete: false
        });
        phaseInfo[1] = Phases({
            tokenLimit: 100_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: phaseInfo[0].expirationTimestamp,
            expirationTimestamp: phaseInfo[0].expirationTimestamp + 15 days, // 15 Days
            isComplete: false,
            price: 2
        });
        phaseInfo[2] = Phases({
            tokenLimit: 100_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: phaseInfo[1].expirationTimestamp,
            expirationTimestamp: phaseInfo[1].expirationTimestamp + 15 days, // 15 Days
            isComplete: false,
            price: 3
        });
        phaseInfo[3] = Phases({
            tokenLimit: 100_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: phaseInfo[2].expirationTimestamp,
            expirationTimestamp: phaseInfo[2].expirationTimestamp + 15 days, // 15 Days
            isComplete: false,
            price: 4
        });
        phaseInfo[4] = Phases({
            tokenLimit: 100_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: phaseInfo[3].expirationTimestamp,
            expirationTimestamp: phaseInfo[3].expirationTimestamp + 15 days, // 15 Days
            isComplete: false,
            price: 5
        });
        phaseInfo[5] = Phases({
            tokenLimit: 100_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: phaseInfo[4].expirationTimestamp,
            expirationTimestamp: phaseInfo[4].expirationTimestamp + 15 days, // 15 Days
            isComplete: false,
            price: 6
        });
    }

    /* ================ BUYING TOKENS SECTION ================ */

    // Receive Function
    receive() external payable {
        // Sending deposited currency to the receiver address
        payable(receiverAddress).transfer(msg.value);
    }

    // Function lets user buy CHB tokens || Type 1 = BNB or ETH, Type = 2 for USDT
    function buyTokens(uint8 _type, uint256 _usdtAmount)
        external
        payable
        nonReentrant
    {
        require(
            block.timestamp < phaseInfo[(totalPhases - 1)].expirationTimestamp,
            "Buying Phases are over"
        );

        uint256 _buyAmount;

        // If type == 1
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        // If type == 2
        else {
            _buyAmount = _usdtAmount;

            // Balance Check
            require(
                Token(USDTAddress).balanceOf(msg.sender) >= _buyAmount,
                "User doesn't have enough balance"
            );

            // Allowance Check
            require(
                Token(USDTAddress).allowance(msg.sender, address(this)) >=
                    _buyAmount,
                "Allowance provided is low"
            );
        }

        // Token calculation
        (uint256 _tokenAmount, uint8 _phaseNo) = calculateTokens(
            _type,
            _buyAmount
        );

        // Phase info setting
        setPhaseInfo(_tokenAmount, defaultPhase);

        // Transfers CHB to user
        TransferHelper.safeTransfer(tokenAddress, msg.sender, _tokenAmount);

        // Update Phase number and add token amount
        defaultPhase = _phaseNo;
        totalTokenSold += _tokenAmount;

        // Calculated total USDT raised in the platform
        (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
        totalUSDTRaised += uint256((_buyAmount * _amountToUSD) / _typeDecimal);

        if (_type == 1) {
            // Sending deposited currency to the receiver address
            payable(receiverAddress).transfer(_buyAmount);
        } else {
            // Sending deposited currency to the receiver address
            TransferHelper.safeTransferFrom(
                USDTAddress,
                msg.sender,
                receiverAddress,
                _buyAmount
            );
        }
        // Emits event
        emit TokensBought(
            msg.sender,
            _buyAmount,
            _tokenAmount,
            uint32(block.timestamp)
        );
    }

    // Function calculates tokens according to user's given amount
    function calculateTokens(uint8 _type, uint256 _amount)
        public
        view
        returns (uint256, uint8)
    {
        (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
        uint256 _amountGivenInUsd = ((_amount * _amountToUSD) / _typeDecimal);

        return
            calculateTokensInternal(_type, _amountGivenInUsd, defaultPhase, 0);
    }

    // Internal function to calculatye tokens
    function calculateTokensInternal(
        uint8 _type,
        uint256 _amount,
        uint8 _phaseNo,
        uint256 _previousTokens
    ) internal view returns (uint256, uint8) {
        // Phases cannot exceed totalPhases
        require(
            _phaseNo < totalPhases,
            "Not enough tokens in the contract or Phase expired"
        );

        Phases memory pInfo = phaseInfo[_phaseNo];

        // If phase is still going on
        if (pInfo.expirationTimestamp > block.timestamp) {
            uint256 _tokensAmount = tokensUserWillGet(_amount, pInfo.price);

            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;

            // If token left are 0. Next phase will be executed
            if (_tokensLeftToSell == 0) {
                return
                    calculateTokensInternal(
                        _type,
                        _amount,
                        _phaseNo + 1,
                        _previousTokens
                    );
            }
            // If the phase have enough tokens left
            else if (_tokensLeftToSell >= _tokensAmount) {
                return (_tokensAmount, _phaseNo);
            }
            // If the phase doesn't have enough tokens
            else {
                _tokensAmount =
                    pInfo.tokenLimit +
                    _previousTokens -
                    pInfo.tokenSold;

                uint256 _tokenPriceInPhase = tokenValueInPhase(
                    pInfo.price,
                    _tokensAmount
                );

                (
                    uint256 _remainingTokens,
                    uint8 _newPhase
                ) = calculateTokensInternal(
                        _type,
                        _amount - _tokenPriceInPhase,
                        _phaseNo + 1,
                        0
                    );

                return (_remainingTokens + _tokensAmount, _newPhase);
            }
        }
        // In case the phase is expired. New will begin after sending the left tokens to the next phase
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateTokensInternal(
                    _type,
                    _amount,
                    _phaseNo + 1,
                    _remainingTokens + _previousTokens
                );
        }
    }

    // Returns the value of tokens in the phase in dollors
    function tokenValueInPhase(uint32 _price, uint256 _tokenAmount)
        internal
        view
        returns (uint256)
    {
        return ((_tokenAmount * uint256(_price) * (10**8)) /
            (100 * tokenDecimal));
    }

    // Tokens user will get according to the price
    function tokensUserWillGet(uint256 _amount, uint32 _price)
        internal
        view
        returns (uint256)
    {
        return ((_amount * tokenDecimal * 100) / ((10**8) * uint256(_price)));
    }

    // Returns the crypto values used
    function cryptoValues(uint8 _type)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 _amountToUSD;
        uint256 _typeDecimal;

        if (_type == 1) {
            _amountToUSD = OracleWrapper(BNBorETHOracleAddress).latestAnswer();
            _typeDecimal = 10**18;
        } else {
            _amountToUSD = OracleWrapper(USDTOracleAddress).latestAnswer();
            _typeDecimal = uint256(10**Token(USDTAddress).decimals());
        }
        return (_amountToUSD, _typeDecimal);
    }

    // Sets phase info according to the tokens bought
    function setPhaseInfo(uint256 _tokensUserWillGet, uint8 _phaseNo) internal {
        require(_phaseNo < totalPhases, "All tokens have been exhausted");

        Phases storage pInfo = phaseInfo[_phaseNo];

        if (block.timestamp < pInfo.expirationTimestamp) {
            //  when phase has more tokens than reuired
            if ((pInfo.tokenLimit - pInfo.tokenSold) > _tokensUserWillGet) {
                pInfo.tokenSold += _tokensUserWillGet;
            }
            //  when  phase has equal tokens as reuired
            else if (
                (pInfo.tokenLimit - pInfo.tokenSold) == _tokensUserWillGet
            ) {
                pInfo.tokenSold = pInfo.tokenLimit;
                pInfo.isComplete = true;
            }
            // when tokens required are more than left tokens in phase
            else {
                uint256 tokensLeft = _tokensUserWillGet -
                    (pInfo.tokenLimit - pInfo.tokenSold);
                pInfo.tokenSold = pInfo.tokenLimit;
                pInfo.isComplete = true;

                setPhaseInfo(tokensLeft, _phaseNo + 1);
            }
        }
        // if tokens left in phase afterb completion of expiration time
        else {
            uint256 remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;
            pInfo.tokenSold = pInfo.tokenLimit;
            pInfo.isComplete = true;

            phaseInfo[_phaseNo + 1].tokenLimit += remainingTokens;
            setPhaseInfo(_tokensUserWillGet, _phaseNo + 1);
        }
    }

    // Function sends the left over tokens to the receiving address, only after phases are over
    function sendLeftoverTokensToReceiver() external onlyOwner {
        require(
            block.timestamp > phaseInfo[(totalPhases - 1)].expirationTimestamp,
            "Phases are not over yet"
        );

        uint256 _balance = Token(tokenAddress).balanceOf(address(this));
        require(_balance > 0, "No tokens left to send");

        TransferHelper.safeTransfer(tokenAddress, receiverAddress, _balance);
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    // Updates USDT Address
    function updateUSDTAddress(address _USDTAddress) external onlyOwner {
        USDTAddress = _USDTAddress;
    }

    // Updates USDT Oracle Address
    function updateUSDTOracleAddress(address _USDTOracleAddress)
        external
        onlyOwner
    {
        USDTOracleAddress = _USDTOracleAddress;
    }

    // Updates USDT Oracle Address
    function updateBNBorETHOracleAddress(address _BNBorETHOracleAddress)
        external
        onlyOwner
    {
        BNBorETHOracleAddress = _BNBorETHOracleAddress;
    }

    // Updates Receiver Address
    function updateReceiverAddress(address _receiverAddress)
        external
        onlyOwner
    {
        receiverAddress = _receiverAddress;
    }
}
