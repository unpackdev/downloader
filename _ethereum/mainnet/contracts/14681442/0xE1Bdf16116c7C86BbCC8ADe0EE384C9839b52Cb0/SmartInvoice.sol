// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, max-states-count

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Initializable.sol";
import "./ISmartInvoice.sol";
import "./IArbitrable.sol";
import "./IArbitrator.sol";
import "./IWRAPPED.sol";
import "./console.sol";

// splittable digital deal lockers w/ embedded arbitration tailored for guild work
contract SmartInvoice is
    ISmartInvoice,
    IArbitrable,
    Initializable,
    Context,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    uint256 public constant NUM_RULING_OPTIONS = 5; // excludes options 0, 1 and 2
    // Note that Aragon Court treats the possible outcomes as arbitrary numbers, leaving the Arbitrable (us) to define how to understand them.
    // Some outcomes [0, 1, and 2] are reserved by Aragon Court: "missing", "leaked", and "refused", respectively.
    // Note that Aragon Court emits the LOWEST outcome in the event of a tie.

    // solhint-disable-next-line var-name-mixedcase
    uint8[2][6] public RULINGS = [
        [1, 1], // 0 = refused to arbitrate
        [1, 0], // 1 = 100% to client
        [3, 1], // 2 = 75% to client
        [1, 1], // 3 = 50% to client
        [1, 3], // 4 = 25% to client
        [0, 1] // 5 = 0% to client
    ];

    uint256 public constant MAX_TERMINATION_TIME = 63113904; // 2-year limit on locker
    address public wrappedNativeToken;

    enum ADR {
        INDIVIDUAL,
        ARBITRATOR
    }
    uint8 public resolverTypeInt;
    enum RATES {
        ARB_RATE,
        DAO_RATE,
        NATIVE_CONVERSION_RATE,
        RESOLVER_TYPE
    }
    address public client;
    address public provider;
    address public dao;
    address public daoToken;

    ADR public resolverType;
    address public resolver;
    address public token;
    uint256 public terminationTime;
    uint256 public resolutionRate;
    uint256 public daoRate;
    bytes32 public details;

    uint256[] public amounts; // milestones split into amounts
    uint256 public total = 0;
    bool public locked;
    uint256 public milestone = 0; // current milestone - starts from 0 to amounts.length
    uint256 public released = 0;
    uint256 public disputeId;
    uint256 public nativeConversionRate;
    event Register(
        address indexed client,
        address indexed provider,
        uint256[] amounts
    );
    event Deposit(address indexed sender, uint256 amount);
    event Release(uint256 milestone, uint256 amount);
    event Withdraw(uint256 balance);
    event Lock(address indexed sender, bytes32 details);
    event Resolve(
        address indexed resolver,
        uint256 clientAward,
        uint256 providerAward,
        uint256 resolutionFee,
        bytes32 details
    );
    event Rule(
        address indexed resolver,
        uint256 clientAward,
        uint256 providerAward,
        uint256 ruling
    );

    // solhint-disable-next-line no-empty-blocks
    function initLock() external initializer {}

    function init(
        address _client,
        address _provider,
        address _dao,
        address _daoToken,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime, // exact termination date in seconds since epoch
        uint256[4] calldata _rates,
        bytes32 _details,
        address _wrappedNativeToken
    ) external override initializer {
        require(_client != address(0), "invalid client");
        require(_provider != address(0), "invalid provider");
        require(_dao != address(0), "invalid dao");
        require(_daoToken != address(0), "invalid dao token");

        require(
            _rates[uint8(RATES.RESOLVER_TYPE)] <= uint8(ADR.ARBITRATOR),
            "invalid resolverType"
        );
        require(_resolver != address(0), "invalid resolver");
        require(_token != address(0), "invalid token");
        require(_terminationTime > block.timestamp, "duration ended");
        require(
            _terminationTime <= block.timestamp + MAX_TERMINATION_TIME,
            "duration too long"
        );
        require(_rates.length == 4, "Rates length wrong");
        require(_rates[uint256(RATES.ARB_RATE)] > 0, "invalid resolutionRate");
        require(
            _wrappedNativeToken != address(0),
            "invalid wrappedNativeToken"
        );
        require(
            _rates[uint256(RATES.NATIVE_CONVERSION_RATE)] > 0,
            "Invalid native conversion rate"
        );

        resolverTypeInt = uint8(_rates[uint8(RATES.RESOLVER_TYPE)]);
        client = _client;
        provider = _provider;
        dao = _dao;
        daoToken = _daoToken;
        resolverType = ADR(resolverTypeInt);
        resolver = _resolver;
        token = _token;
        amounts = _amounts;
        for (uint256 i = 0; i < amounts.length; i++) {
            total = total + amounts[i];
        }
        terminationTime = _terminationTime;
        resolutionRate = _rates[uint256(RATES.ARB_RATE)];
        daoRate = _rates[uint256(RATES.DAO_RATE)];
        nativeConversionRate = _rates[uint256(RATES.NATIVE_CONVERSION_RATE)];
        details = _details;
        wrappedNativeToken = _wrappedNativeToken;

        emit Register(_client, _provider, amounts);
    }

    function sendAndRecv(uint256 providerFee, uint256 daoFee) internal {
        sendAndRecv(token, providerFee, daoFee);
    }

    function sendAndRecv(
        address _token,
        uint256 providerFee,
        uint256 daoFee
    ) internal {
        if (providerFee > 0) {
            IERC20(_token).safeTransfer(provider, providerFee);
        }

        if (daoFee > 0) {
            IERC20(_token).safeTransfer(dao, daoFee);
            uint256 balance = IERC20(daoToken).balanceOf(address(this));
            uint256 converted = daoFee * nativeConversionRate;
            require(balance >= converted, "Insufficent balance");
            IERC20(daoToken).safeTransfer(provider, converted);
        }
    }

    function _release() internal {
        // client transfers locker milestone funds to provider

        require(!locked, "locked");
        require(_msgSender() == client, "!client");

        uint256 currentMilestone = milestone;
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (currentMilestone < amounts.length) {
            uint256 amount = amounts[currentMilestone];
            if (currentMilestone == amounts.length - 1 && amount < balance) {
                amount = balance;
            }
            require(balance >= amount, "insufficient balance");

            milestone = milestone + 1;
            uint256 daoFee = (daoRate == 0) ? 0 : amount / daoRate; // calculates dao fee )
            uint256 providerFee = amount - daoFee;

            //console.log("daoFee",daoFee);
            //console.log("providerFee",providerFee);
            sendAndRecv(token, providerFee, daoFee);

            // IERC20(token).safeTransfer(provider, amount);
            released = released + amount;
            emit Release(currentMilestone, amount);
        } else {
            require(balance > 0, "balance is 0");
            uint256 daoFee = (daoRate == 0) ? 0 : balance / daoRate; // calculates dao fee )
            uint256 providerFee = balance - daoFee;

            //console.log("daoFee",daoFee);
            //console.log("providerFee",providerFee);
            sendAndRecv(token, providerFee, daoFee);

            // IERC20(token).safeTransfer(provider, balance);
            released = released + balance;
            emit Release(currentMilestone, balance);
        }
    }

    function release() external override nonReentrant {
        return _release();
    }

    function release(uint256 _milestone) external override nonReentrant {
        // client transfers locker funds upto certain milestone to provider
        require(!locked, "locked");
        require(_msgSender() == client, "!client");
        require(_milestone >= milestone, "milestone passed");
        require(_milestone < amounts.length, "invalid milestone");
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 amount = 0;
        for (uint256 j = milestone; j <= _milestone; j++) {
            if (j == amounts.length - 1 && amount + amounts[j] < balance) {
                emit Release(j, balance - amount);
                amount = balance;
            } else {
                emit Release(j, amounts[j]);
                amount = amount + amounts[j];
            }
        }
        require(balance >= amount, "insufficient balance");

        uint256 daoFee = (daoRate == 0) ? 0 : amount / daoRate; // calculates dao fee )
        uint256 providerFee = amount - daoFee;

        //console.log("release(uint256 _milestone): daoFee",daoFee);
        //console.log("release(uint256 _milestone): providerFee",providerFee);
        sendAndRecv(token, providerFee, daoFee);

        // IERC20(token).safeTransfer(provider, amount);
        released = released + amount;
        milestone = _milestone + 1;
    }

    // release non-invoice tokens
    function releaseTokens(address _token) external override nonReentrant {
        if (_token == token) {
            //console.log("Orignal");
            _release();
        } else {
            require(_msgSender() == client, "!client");
            uint256 balance = IERC20(_token).balanceOf(address(this));
            uint256 daoFee = (daoRate == 0) ? 0 : balance / daoRate; // calculates dao fee )
            uint256 providerFee = balance - daoFee;

            //console.log("releaseTokens: daoFee",daoFee);
            //console.log("releaseTokens: providerFee",providerFee);

            sendAndRecv(_token, providerFee, daoFee);

            // IERC20(_token).safeTransfer(provider, balance);
        }
    }

    function _withdraw() internal {
        require(!locked, "locked");
        require(block.timestamp > terminationTime, "!terminated");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "balance is 0");

        IERC20(token).safeTransfer(client, balance);
        milestone = amounts.length;

        emit Withdraw(balance);
    }

    // withdraw locker remainder to client if termination time passes & no lock
    function withdraw() external override nonReentrant {
        return _withdraw();
    }

    // withdraw non-invoice tokens
    function withdrawTokens(address _token) external override nonReentrant {
        if (_token == token) {
            _withdraw();
        } else {
            require(block.timestamp > terminationTime, "!terminated");
            uint256 balance = IERC20(_token).balanceOf(address(this));
            require(balance > 0, "balance is 0");

            IERC20(_token).safeTransfer(client, balance);
        }
    }

    // client or main (0) provider can lock remainder for resolution during locker period / update request details
    function lock(bytes32 _details) external payable override nonReentrant {
        require(!locked, "locked");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "balance is 0");
        require(block.timestamp < terminationTime, "terminated");
        require(_msgSender() == client || _msgSender() == provider, "!party");

        if (resolverType == ADR.ARBITRATOR) {
            disputeId = IArbitrator(resolver).createDispute{value: msg.value}(
                NUM_RULING_OPTIONS,
                abi.encodePacked(details)
            );
        }
        locked = true;

        emit Lock(_msgSender(), _details);
    }

    function resolve(
        uint256 _clientAward,
        uint256 _providerAward,
        bytes32 _details
    ) external override nonReentrant {
        // called by individual
        require(resolverType == ADR.INDIVIDUAL, "!individual resolver");
        require(locked, "!locked");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "balance is 0");
        require(_msgSender() == resolver, "!resolver");

        uint256 resolutionFee = balance / resolutionRate; // calculates dispute resolution fee (div(20) = 5% of remainder)

        uint256 daoFee = (daoRate == 0) ? 0 : _providerAward / daoRate; // calculates dao fee )
        uint256 providerFee = _providerAward - daoFee;

        require(
            _clientAward + providerFee + daoFee == balance - resolutionFee,
            "resolution != remainder"
        );

        //console.log("resolve: providerFee",providerFee);
        //console.log("resolve: _clientAward",_clientAward);
        //console.log("resolve: resolutionFee",resolutionFee);
        //console.log("resolve: daoFee",daoFee);

        if (_clientAward > 0) {
            IERC20(token).safeTransfer(client, _clientAward);
        }
        if (resolutionFee > 0) {
            IERC20(token).safeTransfer(resolver, resolutionFee);
        }

        sendAndRecv(token, providerFee, daoFee);

        _withdrawERCToken();

        milestone = amounts.length;
        locked = false;

        emit Resolve(
            _msgSender(),
            _clientAward,
            _providerAward,
            resolutionFee,
            _details
        );
    }

    function rule(uint256 _disputeId, uint256 _ruling)
        external
        override
        nonReentrant
    {
        // called by arbitrator
        require(resolverType == ADR.ARBITRATOR, "!arbitrator resolver");
        require(locked, "!locked");
        require(_msgSender() == resolver, "!resolver");
        require(_disputeId == disputeId, "incorrect disputeId");
        require(_ruling <= NUM_RULING_OPTIONS, "invalid ruling");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "balance is 0");

        uint8[2] memory ruling = RULINGS[_ruling];
        uint8 clientShare = ruling[0];
        uint8 providerShare = ruling[1];
        uint8 denom = clientShare + providerShare;
        uint256 providerAward = (balance * providerShare) / denom;
        uint256 clientAward = balance - providerAward;
        uint256 daoFee = (daoRate == 0) ? 0 : providerAward / daoRate; // calculates dao fee )
        uint256 providerFee = providerAward - daoFee;

        //console.log("daoFee",daoFee);
        //console.log("providerFee",providerFee);
        sendAndRecv(token, providerFee, daoFee);

        // if (providerAward > 0) {
        //     IERC20(token).safeTransfer(provider, providerAward);
        // }
        if (clientAward > 0) {
            IERC20(token).safeTransfer(client, clientAward);
        }
        _withdrawERCToken();

        milestone = amounts.length;
        locked = false;

        emit Rule(resolver, clientAward, providerAward, _ruling);
        emit Ruling(resolver, _disputeId, _ruling);
    }

    function setNativeExhangeRate(uint256 newNativeConversionRate)
        external
        nonReentrant
    {
        require(_msgSender() == dao, "!party");
        require(newNativeConversionRate > 0);
        nativeConversionRate = newNativeConversionRate;
    }

    function _withdrawERCToken() internal {
        uint256 balance = IERC20(daoToken).balanceOf(address(this));
        if (balance > 0) {
            IERC20(daoToken).safeTransfer(dao, balance);
        }
    }

    function withdrawERCToken() external nonReentrant {
        require(_msgSender() == client || _msgSender() == dao, "!party");
        _withdrawERCToken();
    }

    // receive eth transfers
    receive() external payable {
        require(!locked, "locked");
        require(token == wrappedNativeToken, "!wrappedNativeToken");
        IWRAPPED(wrappedNativeToken).deposit{value: msg.value}();
        emit Deposit(_msgSender(), msg.value);
    }
}
