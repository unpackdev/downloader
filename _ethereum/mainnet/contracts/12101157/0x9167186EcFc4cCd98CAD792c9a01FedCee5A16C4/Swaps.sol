pragma solidity ^0.5.7;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ISwaps.sol";
import "./Vault.sol";

contract Swaps is Ownable, ISwaps, ReentrancyGuard {
    using SafeMath for uint;

    uint public MAX_INVESTORS = 10;

    uint256 public feeAmount;
    address payable public feeAddress;

    Vault public vault;
    //     id          whiteAddr
    mapping(bytes32 => address) public baseOnlyInvestor;
    //     id          owner
    mapping(bytes32 => address) public owners;
    //     id          baseAddr
    mapping(bytes32 => address) public baseAddresses;
    //     id          quoteAddr
    mapping(bytes32 => address) public quoteAddresses;
    //     id          expire
    mapping(bytes32 => uint) public expirationTimestamps;
    //     id          swapped?
    mapping(bytes32 => bool) public isSwapped;
    //     id          cancelled?
    mapping(bytes32 => bool) public isCancelled;
    //      id                base/quote  limit
    mapping(bytes32 => mapping(address => uint)) public limits;
    //      id                base/quote  raised
    mapping(bytes32 => mapping(address => uint)) public raised;
    //      id                base/quote  investors
    mapping(bytes32 => mapping(address => address[])) public investors;
    //      id                base/quote         investor    amount
    mapping(bytes32 => mapping(address => mapping(address => uint))) public investments;
    //      id                base/quote  minLimit
    mapping(bytes32 => mapping(address => uint)) public minInvestments;
    //      id         brokers
    mapping(bytes32 => address[]) public brokers;
    //      id                base/quote         broker      percent
    mapping(bytes32 => mapping(address => mapping(address => uint))) public brokerPercents;

    uint public myWishBasePercent;
    uint public myWishQuotePercent;
    address public myWishAddress;

    modifier onlyInvestor(bytes32 _id, address _token) {
        require(
            _isInvestor(_id, _token, msg.sender),
            "Swaps: Allowed only for investors"
        );
        _;
    }

    modifier onlyWhenVaultDefined() {
        require(address(vault) != address(0), "Swaps: Vault is not defined");
        _;
    }

    modifier onlyOrderOwner(bytes32 _id) {
        require(msg.sender == owners[_id], "Swaps: Allowed only for owner");
        _;
    }

    modifier onlyWhenOrderExists(bytes32 _id) {
        require(owners[_id] != address(0), "Swaps: Order doesn't exist");
        _;
    }

    modifier hasFeeAndTransferIt {
        require(
            msg.value == feeAmount,
            "Swaps: Not enough fee"
        );
        feeAddress.transfer(msg.value);
        _;
    }

    event OrderCreated(
        bytes32 id,
        address owner,
        address baseAddress,
        address quoteAddress,
        uint baseLimit,
        uint quoteLimit,
        uint expirationTimestamp,
        address baseOnlyInvestor,
        uint minBaseInvestment,
        uint minQuoteInvestment,
        address broker,
        uint brokerBasePercent,
        uint brokerQuotePercent
    );

    event OrderCancelled(bytes32 id);

    event Deposit(
        bytes32 id,
        address token,
        address user,
        uint amount,
        uint balance
    );

    event Refund(bytes32 id, address token, address user, uint amount);

    event OrderSwapped(bytes32 id, address byUser);

    event SwapSend(bytes32 id, address token, address user, uint amount);

    event BrokerSend(bytes32 id, address token, address broker, uint amount);

    event MyWishAddressChange(
        address oldMyWishAddress,
        address newMyWishAddress
    );

    event MyWishPercentsChange(
        uint oldBasePercent,
        uint oldQuotePercent,
        uint newBasePercent,
        uint newQuotePercent
    );

    constructor(
        uint256 _feeAmount,
        address payable _feeAddress
    ) public {
        feeAmount = _feeAmount;
        feeAddress = _feeAddress;
    }

    function tokenFallback(address, uint, bytes calldata) external {}

    function createOrder(
        address _baseAddress,
        address _quoteAddress,
        uint _baseLimit,
        uint _quoteLimit,
        uint _expirationTimestamp,
        address _baseOnlyInvestor,
        uint _minBaseInvestment,
        uint _minQuoteInvestment,
        address _brokerAddress,
        uint _brokerBasePercent,
        uint _brokerQuotePercent
    )
        external
        payable
        nonReentrant
        onlyWhenVaultDefined
        hasFeeAndTransferIt
        returns(bytes32 _id)
    {
        _id = createKey(msg.sender);
        require(owners[_id] == address(0), "Swaps: Order already exists");
        require(
            _baseAddress != _quoteAddress,
            "Swaps: Exchanged tokens must be different"
        );
        require(_baseLimit > 0, "Swaps: Base limit must be positive");
        require(_quoteLimit > 0, "Swaps: Quote limit must be positive");
        require(
            _expirationTimestamp > now,
            "Swaps: Expiration time must be in future"
        );
        require(
            _brokerBasePercent.add(myWishBasePercent) <= 10000,
            "Swaps: Base percent sum should be less than 100%"
        );
        require(
            _brokerQuotePercent.add(myWishQuotePercent) <= 10000,
            "Swaps: Quote percent sum should be less than 100%"
        );

        owners[_id] = msg.sender;
        baseAddresses[_id] = _baseAddress;
        quoteAddresses[_id] = _quoteAddress;
        expirationTimestamps[_id] = _expirationTimestamp;
        limits[_id][_baseAddress] = _baseLimit;
        limits[_id][_quoteAddress] = _quoteLimit;
        baseOnlyInvestor[_id] = _baseOnlyInvestor;
        minInvestments[_id][_baseAddress] = _minBaseInvestment;
        minInvestments[_id][_quoteAddress] = _minQuoteInvestment;
        if (_brokerAddress != address(0)) {
            brokers[_id].push(_brokerAddress);
            brokerPercents[_id][_baseAddress][_brokerAddress] = _brokerBasePercent;
            brokerPercents[_id][_quoteAddress][_brokerAddress] = _brokerQuotePercent;
        }
        if (myWishAddress != address(0)) {
            brokers[_id].push(myWishAddress);
            brokerPercents[_id][_baseAddress][myWishAddress] = myWishBasePercent;
            brokerPercents[_id][_quoteAddress][myWishAddress] = myWishQuotePercent;
        }

        emit OrderCreated(
            _id,
            msg.sender,
            _baseAddress,
            _quoteAddress,
            _baseLimit,
            _quoteLimit,
            _expirationTimestamp,
            _baseOnlyInvestor,
            _minBaseInvestment,
            _minQuoteInvestment,
            _brokerAddress,
            _brokerBasePercent,
            _brokerQuotePercent
        );
    }

    function deposit(bytes32 _id, address _token, uint _amount)
        external
        payable
        nonReentrant
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        if (_token == address(0)) {
            require(
                msg.value == _amount,
                "Swaps: Payable value should be equals value"
            );
            address(vault).transfer(msg.value);
        } else {
            require(msg.value == 0, "Swaps: Payable not allowed here");
            uint allowance = IERC20(_token).allowance(
                msg.sender,
                address(this)
            );
            require(
                _amount <= allowance,
                "Swaps: Allowance should be not less than amount"
            );
            IERC20(_token).transferFrom(msg.sender, address(vault), _amount);
        }
        _deposit(_id, _token, msg.sender, _amount);
    }

    function cancel(bytes32 _id)
        external
        nonReentrant
        onlyOrderOwner(_id)
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        require(!isCancelled[_id], "Swaps: Already cancelled");
        require(!isSwapped[_id], "Swaps: Already swapped");

        address[2] memory tokens = [baseAddresses[_id], quoteAddresses[_id]];
        for (uint t = 0; t < tokens.length; t++) {
            address token = tokens[t];
            for (uint u = 0; u < investors[_id][token].length; u++) {
                address user = investors[_id][token][u];
                uint userInvestment = investments[_id][token][user];
                vault.withdraw(token, user, userInvestment);
            }
        }

        isCancelled[_id] = true;
        emit OrderCancelled(_id);
    }

    function refund(bytes32 _id, address _token)
        external
        nonReentrant
        onlyInvestor(_id, _token)
        onlyWhenVaultDefined
        onlyWhenOrderExists(_id)
    {
        require(!isCancelled[_id], "Swaps: Order cancelled");
        require(!isSwapped[_id], "Swaps: Already swapped");
        address user = msg.sender;
        uint investment = investments[_id][_token][user];
        if (investment > 0) {
            delete investments[_id][_token][user];
        }

        _removeInvestor(investors[_id][_token], user);

        if (investment > 0) {
            raised[_id][_token] = raised[_id][_token].sub(investment);
            vault.withdraw(_token, user, investment);
        }

        emit Refund(_id, _token, user, investment);
    }

    function setVault(Vault _vault) external onlyOwner {
        vault = _vault;
    }

    function setMyWishPercents(uint _basePercent, uint _quotePercent)
        external
        onlyOwner
    {
        require(_basePercent <= 10000, "Swaps: Base percent should be less than 100%");
        require(
            _quotePercent <= 10000,
            "Swaps: Quote percent should be less than 100%"
        );

        emit MyWishPercentsChange(
            myWishBasePercent,
            myWishQuotePercent,
            _basePercent,
            _quotePercent
        );

        myWishBasePercent = _basePercent;
        myWishQuotePercent = _quotePercent;
    }

    function setMyWishAddress(address _myWishAddress) external onlyOwner {
        emit MyWishAddressChange(myWishAddress, _myWishAddress);
        myWishAddress = _myWishAddress;
    }

    function setFeeParameters(
        uint256 _feeAmount,
        address payable _feeAddress
    )
        external
        onlyOwner
    {
        feeAmount = _feeAmount;
        feeAddress = _feeAddress;
    }

    function createKey(address _owner) public view returns (bytes32 result) {
        uint creationTime = now;
        result = 0x0000000000000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_owner, 0x1000000000000000000000000))
            result := or(result, and(creationTime, 0xffffffffffffffffffffffff))
        }
    }

    function allBrokersBasePercent(bytes32 _id) public view returns (uint) {
        return _allBrokersPercent(baseAddresses[_id], _id);
    }

    function allBrokersQuotePercent(bytes32 _id) public view returns (uint) {
        return _allBrokersPercent(quoteAddresses[_id], _id);
    }

    function baseLimit(bytes32 _id) public view returns (uint) {
        return limits[_id][baseAddresses[_id]];
    }

    function quoteLimit(bytes32 _id) public view returns (uint) {
        return limits[_id][quoteAddresses[_id]];
    }

    function baseRaised(bytes32 _id) public view returns (uint) {
        return raised[_id][baseAddresses[_id]];
    }

    function quoteRaised(bytes32 _id) public view returns (uint) {
        return raised[_id][quoteAddresses[_id]];
    }

    function isBaseFilled(bytes32 _id) public view returns (bool) {
        return raised[_id][baseAddresses[_id]] == limits[_id][baseAddresses[_id]];
    }

    function isQuoteFilled(bytes32 _id) public view returns (bool) {
        return raised[_id][quoteAddresses[_id]] == limits[_id][quoteAddresses[_id]];
    }

    function baseInvestors(bytes32 _id) public view returns (address[] memory) {
        return investors[_id][baseAddresses[_id]];
    }

    function quoteInvestors(bytes32 _id)
        public
        view
        returns (address[] memory)
    {
        return investors[_id][quoteAddresses[_id]];
    }

    function baseUserInvestment(bytes32 _id, address _user)
        public
        view
        returns (uint)
    {
        return investments[_id][baseAddresses[_id]][_user];
    }

    function quoteUserInvestment(bytes32 _id, address _user)
        public
        view
        returns (uint)
    {
        return investments[_id][quoteAddresses[_id]][_user];
    }

    function orderBrokers(bytes32 _id) public view returns (address[] memory) {
        return brokers[_id];
    }

    function _allBrokersPercent(address _side, bytes32 _id) internal view returns (uint) {
        uint percents;

        for (uint i = 0; i < brokers[_id].length; i++) {
            address broker = brokers[_id][i];
            uint percent = brokerPercents[_id][_side][broker];
            percents = percents.add(percent);
        }
        return percents;
    }

    function _swap(bytes32 _id) internal {
        require(!isSwapped[_id], "Swaps: Already swapped");
        require(!isCancelled[_id], "Swaps: Already cancelled");
        require(isBaseFilled(_id), "Swaps: Base tokens not filled");
        require(isQuoteFilled(_id), "Swaps: Quote tokens not filled");
        require(now <= expirationTimestamps[_id], "Contract expired");

        _distribute(_id, baseAddresses[_id], quoteAddresses[_id]);
        _distribute(_id, quoteAddresses[_id], baseAddresses[_id]);

        isSwapped[_id] = true;
        emit OrderSwapped(_id, msg.sender);
    }

    function _distribute(bytes32 _id, address _aSide, address _bSide) internal {
        uint brokersPercent;
        for (uint i = 0; i < brokers[_id].length; i++) {
            address broker = brokers[_id][i];
            uint percent = brokerPercents[_id][_bSide][broker];
            brokersPercent = brokersPercent.add(percent);
        }

        uint toPayBrokers = raised[_id][_bSide].mul(brokersPercent).div(10000);
        uint toPayInvestors = raised[_id][_bSide].sub(toPayBrokers);

        uint remainder = toPayInvestors;
        for (uint i = 0; i < investors[_id][_aSide].length; i++) {
            address user = investors[_id][_aSide][i];
            uint toPay;
            // last
            if (i + 1 == investors[_id][_aSide].length) {
                toPay = remainder;
            } else {
                uint aSideRaised = raised[_id][_aSide];
                uint userInvestment = investments[_id][_aSide][user];
                toPay = userInvestment.mul(toPayInvestors).div(aSideRaised);
                remainder = remainder.sub(toPay);
            }

            vault.withdraw(_bSide, user, toPay);
            emit SwapSend(_id, _bSide, user, toPay);
        }

        remainder = toPayBrokers;
        for (uint i = 0; i < brokers[_id].length; i++) {
            address broker = brokers[_id][i];
            uint toPay;
            if (i + 1 == brokers[_id].length) {
                toPay = remainder;
            } else {
                uint percent = brokerPercents[_id][_bSide][broker];
                toPay = toPayBrokers.mul(percent).div(brokersPercent);
                remainder = remainder.sub(toPay);
            }

            vault.withdraw(_bSide, broker, toPay);
            emit BrokerSend(_id, _bSide, broker, toPay);
        }
    }

    function _removeInvestor(address[] storage _array, address _investor)
        internal
    {
        uint idx = _array.length - 1;
        for (uint i = 0; i < _array.length - 1; i++) {
            if (_array[i] == _investor) {
                idx = i;
                break;
            }
        }

        _array[idx] = _array[_array.length - 1];
        delete _array[_array.length - 1];
        _array.length--;
    }

    function _deposit(bytes32 _id, address _token, address _from, uint _amount)
        internal
    {
        uint amount = _amount;
        require(
            baseAddresses[_id] == _token || quoteAddresses[_id] == _token,
            "Swaps: You can deposit only base or quote currency"
        );
        require(
            raised[_id][_token] < limits[_id][_token],
            "Swaps: Limit already reached"
        );
        require(now <= expirationTimestamps[_id], "Swaps: Contract expired");
        if (baseAddresses[_id] == _token && baseOnlyInvestor[_id] != address(
            0
        )) {
            require(
                msg.sender == baseOnlyInvestor[_id],
                "Swaps: Allowed only for specified address"
            );
        }
        if (limits[_id][_token].sub(
            raised[_id][_token]
        ) > minInvestments[_id][_token]) {
            require(
                _amount >= minInvestments[_id][_token],
                "Swaps: Should not be less than minimum value"
            );
        }

        if (!_isInvestor(_id, _token, _from)) {
            require(
                investors[_id][_token].length < MAX_INVESTORS,
                "Swaps: Too many investors"
            );
            investors[_id][_token].push(_from);
        }

        uint raisedWithOverflow = raised[_id][_token].add(amount);
        if (raisedWithOverflow > limits[_id][_token]) {
            uint overflow = raisedWithOverflow.sub(limits[_id][_token]);
            vault.withdraw(_token, _from, overflow);
            amount = amount.sub(overflow);
        }

        investments[_id][_token][_from] = investments[_id][_token][_from].add(
            amount
        );

        raised[_id][_token] = raised[_id][_token].add(amount);
        emit Deposit(
            _id,
            _token,
            _from,
            amount,
            investments[_id][_token][_from]
        );

        if (isBaseFilled(_id) && isQuoteFilled(_id)) {
            _swap(_id);
        }
    }

    function _isInvestor(bytes32 _id, address _token, address _who)
        internal
        view
        returns (bool)
    {
        return investments[_id][_token][_who] > 0;
    }
}
