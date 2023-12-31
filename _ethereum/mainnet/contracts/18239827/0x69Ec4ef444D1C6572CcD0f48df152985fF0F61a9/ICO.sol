//SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IICO.sol";
import "./IVesting.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./OracleWrapper.sol";

contract ICO is Ownable, ReentrancyGuard, IICO {
    uint256 public totalTokenSold;
    uint256 public totalUSDRaised;
    uint256 public tokenDecimal;
    uint256 public minTokensBuy = (100 * (10 ** 18));
    uint256 public totalReferralAmount = (2000100 * (10 ** 18));
    uint256 private counter;
    uint8 public defaultPhase = 1;
    uint8 public totalPhases;

    address public receiverAddress = 0xDF155a928dBB5556C52DC0c51b81308d6F41925D;

    //ETH
    address public constant USDTORACLEADRESS =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public constant ETHORACLEADRESS =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /* ================ STRUCT SECTION ================ */
    /* Stores phases */
    struct Phases {
        uint256 tokenSold;
        uint256 tokenLimit;
        uint32 startTime;
        uint32 expirationTimestamp;
        uint32 price /* 10 ** 8 */;
        bool isComplete;
    }

    mapping(uint256 => Phases) public phaseInfo;
    mapping(address => bool) public isVerified;
    mapping(address => string) public isInvested;
    mapping(string => address) public referralCodeMapping;

    IERC20Metadata public tokenInstance; /* Dregn token instance */
    IERC20Metadata public usdtInstance; /* USDT token instance */
    IVesting public vestingInstance; /* vesting contract address */

    OracleWrapper public USDTOracle = OracleWrapper(USDTORACLEADRESS);
    OracleWrapper public ETHOracle = OracleWrapper(ETHORACLEADRESS);

    /* ================ CONSTRUCTOR SECTION ================ */
    constructor(
        address _tokenAddress,
        address _usdtAddress,
        address _vestingContract
    ) {
        tokenInstance = IERC20Metadata(_tokenAddress);
        usdtInstance = IERC20Metadata(_usdtAddress);
        vestingInstance = IVesting(_vestingContract);

        totalPhases = 4;
        tokenDecimal = uint256(10 ** tokenInstance.decimals());

        phaseInfo[1] = Phases({
            tokenLimit: 4_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1690761600,
            expirationTimestamp: 1691020799, //31th July 2023 to 02nd August 2023
            price: 10000000 /* 0.1 */,
            isComplete: false
        });
        phaseInfo[2] = Phases({
            tokenLimit: 4_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1691625600,
            expirationTimestamp: 1691884799, //10th August 2023 to 12th August 2023
            isComplete: false,
            price: 15000000 /* 0.15 */
        });
        phaseInfo[3] = Phases({
            tokenLimit: 4_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1693008000,
            expirationTimestamp: 1693267199, //26th August 2023 to 28th August 2023
            isComplete: false,
            price: 20000000 /* 0.2 */
        });
        phaseInfo[4] = Phases({
            tokenLimit: 10_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1696118400,
            expirationTimestamp: 1698796799, //01st October 2023 to 31th October 2023
            isComplete: false,
            price: 25000000 /* 0.25 */
        });
    }

    /* ================ BUYING TOKENS SECTION ================ */

    /* Receive Function */
    receive() external payable {
        /* Sending deposited currency to the receiver address */
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    /* Function lets user buy SDG tokens || Type 1 = BNB or ETH, Type = 2 for USDT */
    function buyTokens(
        uint8 _type,
        uint256 _usdtAmount,
        address _referralAddress
    ) external payable override nonReentrant {
        address _msgSender = msg.sender;
        require(isVerified[_msgSender], "User KYC is not done.");
        require(
            block.timestamp >= phaseInfo[0].startTime,
            "Buying Phases are not Started yet"
        );
        require(
            block.timestamp < phaseInfo[(totalPhases)].expirationTimestamp,
            "Buying phases are over."
        );

        uint256 _buyAmount;

        /* If type == 1 */
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        /* If type == 2 */
        else {
            _buyAmount = _usdtAmount;
            /* Balance Check */
            require(
                usdtInstance.balanceOf(_msgSender) >= _buyAmount,
                "User doesn't have enough balance."
            );

            /* Allowance Check */
            require(
                usdtInstance.allowance(_msgSender, address(this)) >= _buyAmount,
                "Allowance provided is low."
            );
        }
        require(_buyAmount > 0, "Please enter value more than 0.");

        /* Token calculation */
        (
            uint256 _tokenAmount,
            uint8 _phaseNo,
            uint256 _amountToUSD
        ) = calculateTokens(_buyAmount, 0, defaultPhase, _type);

        require(
            _tokenAmount >= minTokensBuy,
            "Please buy more then minimum value"
        );

        /* Setup for vesting in vesting contract */
        require(_tokenAmount > 0, "Token amount should be more then zero.");
        vestingInstance.registerUserByICO(_tokenAmount, _phaseNo, _msgSender);

        uint256 _referralReward = 0;
        if (bytes(isInvested[_msgSender]).length == 0) {
            if ((_referralAddress != address(0)) && (totalReferralAmount > 0)) {
                require(
                    bytes(isInvested[_referralAddress]).length > 0,
                    "Referral Address is not valid"
                );

                _referralReward = (_tokenAmount * 1000) / 10000;
                if (totalReferralAmount > _referralReward) {
                    _referralReward = _referralReward;
                } else {
                    _referralReward = totalReferralAmount;
                }
                vestingInstance.registerUserByICO(
                    _referralReward,
                    0,
                    _referralAddress
                );
                totalReferralAmount -= _referralReward;
            }
            string memory referralCode = randomString();
            isInvested[_msgSender] = referralCode;
            referralCodeMapping[referralCode] = _msgSender;
        }

        /* Phase info setting */
        setPhaseInfo(_tokenAmount, _referralReward, defaultPhase);

        /* Update Phase number and add token amount */
        defaultPhase = _phaseNo;

        totalTokenSold += _tokenAmount;
        totalUSDRaised += _amountToUSD;

        if (_type == 1) {
            /* Sending deposited currency to the receiver address */
            TransferHelper.safeTransferETH(receiverAddress, _buyAmount);
        } else {
            /* Sending deposited currency to the receiver address */
            TransferHelper.safeTransferFrom(
                address(usdtInstance),
                _msgSender,
                receiverAddress,
                _buyAmount
            );
        }
        /* Emits event */
        emit BuyTokenDetail(
            _buyAmount,
            _tokenAmount,
            _referralReward,
            uint32(block.timestamp),
            _type,
            _phaseNo,
            _referralAddress,
            _msgSender
        );
    }

    function randomString() public returns (string memory referralCode) {
        bytes memory randomWord = new bytes(6);
        // since we have 36 letters
        bytes memory chars = new bytes(36);
        chars = "abcdefghijklmnopqrstuvwxyz0123456789";
        for (uint i = 0; i < 6; i++) {
            uint randomNumber = random();
            // Index access for string is not possible
            randomWord[i] = chars[randomNumber];
        }
        // randomWord = "a3f5h6";
        if (referralCodeMapping[string(randomWord)] == address(0)) {
            return string(randomWord);
        } else {
            randomString();
        }
    }

    function random() internal returns (uint) {
        counter++;
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        counter
                    )
                )
            ) % 36;
    }

    function getCurrentPhase() public view returns (uint8) {
        uint32 _time = uint32(block.timestamp);

        Phases memory pInfoFirst = phaseInfo[1];
        Phases memory pInfoSecond = phaseInfo[2];
        Phases memory pInfoThird = phaseInfo[3];
        Phases memory pInfoLast = phaseInfo[4];

        if (pInfoLast.expirationTimestamp >= _time) {
            if (pInfoThird.expirationTimestamp >= _time) {
                if (pInfoSecond.expirationTimestamp >= _time) {
                    if (pInfoFirst.expirationTimestamp >= _time) {
                        return 1;
                    } else {
                        return 2;
                    }
                } else {
                    return 3;
                }
            } else {
                return 4;
            }
        } else {
            return 0;
        }
    }

    /* Function calculates ETH, USDT according to user's given amount */
    function calculateETHorUSDT(
        uint256 _amount,
        uint256 _previousTokens,
        uint8 _phaseNo,
        uint8 _type
    ) public view returns (uint256) {
        /* Phases cannot exceed totalPhases */
        require(
            _phaseNo <= totalPhases,
            "Not enough tokens in the contract or phase expired."
        );
        Phases memory pInfo = phaseInfo[_phaseNo];
        /* If phase is still going on */
        if (block.timestamp < pInfo.expirationTimestamp) {
            uint256 _amountToUSD = ((_amount * pInfo.price) / tokenDecimal);
            (uint256 _cryptoUSDAmount, uint256 _decimals) = cryptoValues(_type);
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;
            require(
                _tokensLeftToSell >= _amount,
                "Insufficient tokens available in phase."
            );
            return ((_amountToUSD * _decimals) / _cryptoUSDAmount);
        }
        /* In case the phase is expired. New will begin after sending the left tokens to the next phase */
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateETHorUSDT(
                    _amount,
                    _remainingTokens + _previousTokens,
                    _phaseNo + 1,
                    _type
                );
        }
    }

    /* Internal function to calculate tokens */
    function calculateTokens(
        uint256 _amount,
        uint256 _previousTokens,
        uint8 _phaseNo,
        uint8 _type
    ) public view returns (uint256, uint8, uint256) {
        /* Phases cannot exceed totalPhases */
        require(
            _phaseNo <= totalPhases,
            "Not enough tokens in the contract or Phase expired."
        );
        Phases memory pInfo = phaseInfo[_phaseNo];
        /* If phase is still going on */
        if (block.timestamp < pInfo.expirationTimestamp) {
            (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
            uint256 _amountGivenInUsd = ((_amount * _amountToUSD) /
                _typeDecimal);

            /* If phase is still going on */
            uint256 _tokensAmount = tokensUserWillGet(
                _amountGivenInUsd,
                pInfo.price
            );
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;
            require(
                _tokensLeftToSell >= _tokensAmount,
                "Insufficient tokens available in phase."
            );
            return (_tokensAmount, _phaseNo, _amountGivenInUsd);
        }
        /*  In case the phase is expired. New will begin after sending the left tokens to the next phase */
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateTokens(
                    _amount,
                    _remainingTokens + _previousTokens,
                    _phaseNo + 1,
                    _type
                );
        }
    }

    /* Tokens user will get according to the price */
    function tokensUserWillGet(
        uint256 _amount,
        uint32 _price
    ) internal view returns (uint256) {
        return ((_amount * tokenDecimal * (10 ** 8)) /
            ((10 ** 8) * uint256(_price)));
    }

    /* Returns the crypto values used */
    function cryptoValues(
        uint8 _type
    ) internal view returns (uint256, uint256) {
        uint256 _amountToUSD;
        uint256 _typeDecimal;

        if (_type == 1) {
            _amountToUSD = ETHOracle.latestAnswer();
            _typeDecimal = 10 ** 18;
        } else {
            _amountToUSD = USDTOracle.latestAnswer();
            _typeDecimal = uint256(10 ** usdtInstance.decimals());
        }
        return (_amountToUSD, _typeDecimal);
    }

    /* Sets phase info according to the tokens bought */
    function setPhaseInfo(
        uint256 _tokensUserWillGet,
        uint256 _referralReward,
        uint8 _phaseNo
    ) internal {
        require(_phaseNo <= totalPhases, "All tokens have been exhausted.");

        Phases storage pInfo = phaseInfo[_phaseNo];

        if (block.timestamp < pInfo.expirationTimestamp) {
            /* when phase has more tokens than reuired */
            if ((pInfo.tokenLimit - pInfo.tokenSold) > _tokensUserWillGet) {
                pInfo.tokenSold += _tokensUserWillGet;
            }
            /* when  phase has equal tokens as reuired */
            else if (
                (pInfo.tokenLimit - pInfo.tokenSold) == _tokensUserWillGet
            ) {
                pInfo.tokenSold = pInfo.tokenLimit;
                pInfo.isComplete = true;
            }
            /*  when tokens required are more than left tokens in phase */
            else {
                revert("Phase doesn't have enough tokens.");
            }
        }
        /* if tokens left in phase afterb completion of expiration time */
        else {
            uint256 remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;
            pInfo.tokenLimit = pInfo.tokenSold;
            pInfo.isComplete = true;

            phaseInfo[_phaseNo + 1].tokenLimit += remainingTokens;
            setPhaseInfo(_tokensUserWillGet, _referralReward, _phaseNo + 1);
        }
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    /* Updates Receiver Address */
    function updateReceiverAddress(
        address _receiverAddress
    ) external onlyOwner {
        require(_receiverAddress != address(0), "Zero address passed.");
        receiverAddress = _receiverAddress;
    }

    function updateUserKYC(address[] memory _userAddress) external onlyOwner {
        require(
            _userAddress.length <= 100,
            "You can't send more than 100 emails to verify at once."
        );
        for (uint256 i = 0; i < _userAddress.length; i++) {
            require(_userAddress[i] != address(0), "Zero address passed.");
            isVerified[_userAddress[i]] = true;
        }
        emit UserKYC(_userAddress, true);
    }

    function updateMinmumuTokensBuyAmount(
        uint256 _minTokensBuy
    ) external onlyOwner {
        minTokensBuy = _minTokensBuy;
    }
}
