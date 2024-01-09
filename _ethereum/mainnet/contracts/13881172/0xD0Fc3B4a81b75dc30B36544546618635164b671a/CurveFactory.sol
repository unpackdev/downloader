// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Clones.sol";
import "./OwnableUpgradeable.sol";
import "./Timelock.sol";
import "./Curve.sol";

contract CurveFactory is OwnableUpgradeable {
    address public immutable CURVE_IMPL;
    address public immutable TIMELOCK_IMPL;

    address payable public platform; // platform commision account
    uint256 public platformRate; // % of total minting cost as platform commission
    uint256 public totalRateLimit;

    event CurveCreated(
        address indexed owner,
        address indexed curveAddr,
        uint256 initMintPrice,
        uint256 m,
        uint256 n,
        uint256 d
    );
    event SetPlatformParms(
        address payable _platform,
        uint256 _platformRate,
        uint256 _totalRateLimit
    );

    constructor(
        address payable _platform,
        uint256 _platformRate,
        uint256 _totalRateLimit,
        address _timelock
    ) {
        __Ownable_init(_timelock);
        _setPlatformParms(_platform, _platformRate, _totalRateLimit);
        CURVE_IMPL = address(new Curve());
        TIMELOCK_IMPL = address(new Timelock());
    }

    // set up the platform commission account and platform commission rate, only operable by contract owner, _platformRate is in pph
    // set the limit of total commission rate, only operable by contract owner, _totalRateLimit is in pph
    function setPlatformParms(
        address payable _platform,
        uint256 _platformRate,
        uint256 _totalRateLimit
    ) public onlyOwner {
        _setPlatformParms(_platform, _platformRate, _totalRateLimit);
    }

    // set up the platform parameters internal
    function _setPlatformParms(
        address payable _platform,
        uint256 _platformRate,
        uint256 _totalRateLimit
    ) internal {
        require(_platform != address(0), "Curve: platform address is zero.");
        require(
            _totalRateLimit <= 100 && _totalRateLimit >= _platformRate,
            "Curve: wrong rate"
        );

        platform = _platform;
        platformRate = _platformRate;
        totalRateLimit = _totalRateLimit;

        emit SetPlatformParms(_platform, _platformRate, _totalRateLimit);
    }

    /**
     * @dev creation of bonding curve with formular: f(x)=m*(x^N)+v
     * _receivingAddress: receivingAddress's commission account
     * _creatorRate: receivingAddress's commission rate
     * _initMintPrice: f(1) = m + v, the first PASS minting price
     * _erc20: collateral token(erc20) for miniting PASS on bonding curve, send 0x000...000 to appoint it as ETH instead of erc20 token
     * _m: m, slope of curve
     * _n,_d: _n/_d = N, exponent of the curve
     * _baseUri: base URI for PASS metadata
     */
    function createCurve(
        string memory _name,
        string memory _symbol,
        address payable _receivingAddress,
        uint256 _creatorRate,
        uint256 _initMintPrice,
        address _erc20,
        uint256 _m,
        uint256 _n,
        uint256 _d,
        string memory _baseUri,
        address _timelock
    ) public {
        // require(info.length == 3 && parms.length == 4);
        require(
            _creatorRate <= totalRateLimit - platformRate,
            "Curve: receivingAddress's commission rate is too high."
        );

        string[] memory infos = new string[](3);
        infos[0] = _name;
        infos[1] = _symbol;
        infos[2] = _baseUri;

        address[] memory addrs = new address[](4);
        addrs[0] = platform;
        addrs[1] = _receivingAddress;
        addrs[2] = _erc20;
        addrs[3] = _timelock == address(0) ? cloneTimelock() : _timelock;

        uint256[] memory parms = new uint256[](6);
        parms[0] = platformRate;
        parms[1] = _creatorRate;
        parms[2] = _initMintPrice;
        parms[3] = _m;
        parms[4] = _n;
        parms[5] = _d;

        address clone = Clones.clone(CURVE_IMPL);
        Curve(clone).initialize(infos, addrs, parms);
        emit CurveCreated(msg.sender, clone, _initMintPrice, _m, _n, _d);
    }

    function cloneTimelock() private returns (address payable newTimelock) {
        newTimelock = payable(Clones.clone(TIMELOCK_IMPL));

        uint256 minDelay = 2 days;
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = msg.sender;
        executors[0] = address(0);

        Timelock(newTimelock).initialize(minDelay, proposers, executors);
        (minDelay, proposers, executors);

        return newTimelock;
    }
}
