// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHTTERC20.sol";
import "./IHTTPrivateSale.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract HTTPrivateSale is IHTTPrivateSale, Ownable {
    using SafeMath for uint256;

    uint8 constant _decimals = 18;
    IHTTERC20 _httTokenContract;
    mapping(uint256 => Version) _versions;
    mapping(uint256 => mapping(address => uint256)) _versionBuyer;
    uint256 _currentVersion;
    bool _enable;

    constructor(address httTokenAddress) {
        _httTokenContract = IHTTERC20(httTokenAddress);
        _enable = false;
        _currentVersion = 0;
        _httTokenContract.approve(address(this), type(uint256).max);
    }

    modifier versionExist() {
        require(
            _versions[_currentVersion].initialized,
            "Private sale version not found"
        );
        _;
    }

    function balance() external view returns (uint256) {
        return _httTokenContract.balanceOf(address(this));
    }

    function hasEnable() external view override returns (bool) {
        return _enable;
    }

    function _setEnable(bool isEnable) internal {
        _enable = isEnable;
        emit StatusChanged(msg.sender, isEnable);
    }

    function enable(bool isEnable) external override onlyOwner {
        _setEnable(isEnable);
    }

    function addVersion(
        uint256 minBuyable,
        uint256 maxBuyable,
        uint256 supply,
        uint256 rate,
        bool enableVersion
    ) external override onlyOwner {
        require(minBuyable > 0, "Should put minBuyable > 0");
        require(maxBuyable > 0, "Should put maxBuyable > 0");
        require(maxBuyable > minBuyable, "Should put maxBuyable > minBuyable");
        require(supply > 0 && supply <= this.balance(), "Invalid supply");
        require(rate > 0, "Should put rate > 0");
        _versions[_currentVersion.add(1)] = Version(
            _currentVersion.add(1),
            true,
            minBuyable,
            maxBuyable,
            supply,
            0,
            rate
        );
        _currentVersion = _currentVersion.add(1);
        _setEnable(enableVersion);
    }

    function currentVersion()
        external
        view
        override
        versionExist
        returns (Version memory)
    {
        return _versions[_currentVersion];
    }

    function setRate(uint256 rate) external override versionExist onlyOwner {
        require(rate > 0, "Should put rate > 0");
        _versions[_currentVersion].rate = rate;
        emit RateChanged(msg.sender, _currentVersion, rate);
    }

    function buy() external payable override {
        require(
            _versions[_currentVersion].initialized,
            "Private sale version not found"
        );
        require(_enable, "Not enable yet");

        uint256 _boughtAmount = _versionBuyer[_currentVersion][msg.sender];
        uint256 httAmount = (msg.value / _versions[_currentVersion].rate) *
            10**_decimals;
        require(
            _boughtAmount.add(httAmount) <=
                _versions[_currentVersion].maxBuyable,
            "Over maxable"
        );
        require(
            httAmount >= _versions[_currentVersion].minBuyable &&
                httAmount <= this.balance() &&
                httAmount <= _versions[_currentVersion].totalSupply.sub(_versions[_currentVersion].soldSupply),
            "Invalid amount"
        );
        _httTokenContract.transfer(msg.sender, httAmount);
        _versions[_currentVersion].soldSupply = _versions[_currentVersion]
            .soldSupply
            .add(httAmount);
        _versionBuyer[_currentVersion][msg.sender] = _versionBuyer[
            _currentVersion
        ][msg.sender].add(httAmount);
        emit HttSold(
            msg.sender,
            _currentVersion,
            msg.value,
            _versions[_currentVersion].rate
        );
    }

    function boughtAmount()
        external
        view
        override
        versionExist
        returns (uint256)
    {
        return _versionBuyer[_currentVersion][msg.sender];
    }

    function withdrawEth() external override onlyOwner {
        address payable sender = payable(msg.sender);
        sender.transfer(address(this).balance);
    }

    function withdrawHTT() external override onlyOwner {
        _httTokenContract.transferFrom(address(this), owner(), this.balance());
    }
}
