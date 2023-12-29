pragma solidity 0.5.11;

interface IERC20 {

    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IKyberReserve {
    function trade(
        IERC20 srcToken,
        uint256 srcAmount,
        IERC20 destToken,
        address payable destAddress,
        uint256 conversionRate,
        bool validate
    ) external payable returns (bool);

    function getConversionRate(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 blockNumber
    ) external view returns (uint256);
}

contract PermissionGroups2 {
    address public admin;
    address public pendingAdmin;
    mapping(address => bool) internal operators;
    address[] internal operatorsGroup;

    constructor(address _admin) public {
        require(_admin != address(0), "Admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Only operator");
        _;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }


    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed(address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator], "Operator exists"); // prevent duplicates.

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator(address operator) public onlyAdmin {
        require(operators[operator], "Not operator");
        operators[operator] = false;

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

contract Withdrawable2 is PermissionGroups2 {
    constructor(address _admin) public PermissionGroups2(_admin) {}

    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);

    /**
     * @dev Withdraw all IERC20 compatible tokens
     * @param token IERC20 The address of the token contract
     */
    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address sendTo
    ) external onlyAdmin {
        token.transfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint256 amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint256 amount, address payable sendTo)
        external
        onlyAdmin
    {
        (bool success, ) = sendTo.call.value(amount)("");
        require(success);
        emit EtherWithdraw(amount, sendTo);
    }
}


contract RateHelper is Withdrawable2 {

    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    IKyberReserve public uniswapReserve;
    IKyberReserve public oasisReserve;
    // support token -> ETH trade
    mapping(address => IKyberReserve[]) public srcTokenReserves;
    // support ETH -> token trade
    mapping(address => IKyberReserve[]) public destTokenReserves;

    constructor(address uniswap, address oasis) public Withdrawable2(msg.sender) {
        addOperator(msg.sender);
        uniswapReserve = IKyberReserve(uniswap);
        oasisReserve = IKyberReserve(oasis);
    }

    function setSrcTokenReserves(address token, IKyberReserve[] memory reserves) public onlyOperator {
        srcTokenReserves[token] = reserves;
    }

    function setDestTokenReserves(address token, IKyberReserve[] memory reserves) public onlyOperator {
        destTokenReserves[token] = reserves;
    }

    function setBridgeReserves(address _uniswap, address _oasis) public onlyOperator {
        uniswapReserve = IKyberReserve(_uniswap);
        oasisReserve = IKyberReserve(_oasis);
    }

    /// @dev return expected rates (ETH -> token) given list of amounts
    ///      exclude uniswap or oasis reserves if needed
    ///      if isBuy, amount is in ETH, otherwise amount is in token
    function getExpectedRates(IERC20 token, uint[] memory amounts, bool isExcludeUni, bool isExcludeOasis, uint blockNumber, bool isBuy)
        public view returns(uint[] memory rates)
    {
        rates = new uint[](amounts.length);
        IERC20 src = isBuy ? ETH_TOKEN_ADDRESS : token;
        IERC20 dest = isBuy ? token : ETH_TOKEN_ADDRESS;
        IKyberReserve[] memory reserves = isBuy ? destTokenReserves[address(token)] : srcTokenReserves[address(token)];
        for(uint i = 0; i < amounts.length; i++) {
            rates[i] = 0;
            for(uint j = 0; j < reserves.length; j++) {
                if (isExcludeUni && reserves[j] == uniswapReserve) { continue; }
                if (isExcludeOasis && reserves[j] == oasisReserve) { continue; }
                uint expectedRate = reserves[j].getConversionRate(src, dest, amounts[i], blockNumber);
                // get max rate
                if (rates[i] < expectedRate) { rates[i] = expectedRate; }
            }
        }
    }

    /// @dev isUniswap = true: get rate from uniswap bridge, otherwise get rate from oasis reserve
    function getBridgeReserveRates(IERC20 token, uint[] memory amounts, uint blockNumber, bool isBuy, bool isUniswap)
        public view returns(uint[] memory rates)
    {
        rates = new uint[](amounts.length);
        IERC20 src = isBuy ? ETH_TOKEN_ADDRESS : token;
        IERC20 dest = isBuy ? token : ETH_TOKEN_ADDRESS;
        IKyberReserve reserve = isUniswap ? uniswapReserve : oasisReserve;
        for(uint i = 0; i < rates.length; i++) {
            rates[i] = reserve.getConversionRate(src, dest, amounts[i], blockNumber);
        }
    }

    // return Kyber's rate excludes uniswap + oasis
    // return uniswap rates
    // return oasis rates
    function getCombinedRates(IERC20 token, uint[] memory amounts, uint blockNumber, bool isBuy)
        public view returns(uint[] memory rates, uint[] memory uniswapRates, uint[] memory oasisRates)
    {
        rates = new uint[](amounts.length);
        uniswapRates = new uint[](amounts.length);
        oasisRates = new uint[](amounts.length);
        IERC20 src = isBuy ? ETH_TOKEN_ADDRESS : token;
        IERC20 dest = isBuy ? token : ETH_TOKEN_ADDRESS;
        IKyberReserve[] memory reserves = isBuy ? destTokenReserves[address(token)] : srcTokenReserves[address(token)];
        for(uint i = 0; i < amounts.length; i++) {
            rates[i] = 0;
            uniswapRates[i] = 0;
            oasisRates[i] = 0;
            for(uint j = 0; j < reserves.length; j++) {
                uint expectedRate = reserves[j].getConversionRate(src, dest, amounts[i], blockNumber);
                if (reserves[j] == uniswapReserve) {
                    uniswapRates[i] = expectedRate;
                } else if (reserves[j] == oasisReserve) {
                    oasisRates[i] = expectedRate;
                } else {
                    if (rates[i] < expectedRate) { rates[i] = expectedRate; }
                }
            }
        }
    }
}