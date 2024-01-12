// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IDepegShieldWrapper.sol";

interface IAdapter {
    function isTriggered(address _pool, bytes calldata _args) external view returns (bool);
}

contract DepegShieldWrappers is Initializable, ReentrancyGuard, IDepegShieldWrapper {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private constant ZERO_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant PRECISION = 1e18;

    address public lendingMarket;
    address public governance;

    struct DepegInfo {
        bool isExist;
        address adapter;
        address adapterPool;
        address[] underlyingTokens;
        mapping(address => uint256) totalCollaterals;
        mapping(address => uint256) balances;
        mapping(address => uint256) corrspondedCoins;
        mapping(address => bool) triggers;
    }

    struct Lending {
        uint256 pid;
        uint256 totalCollateral;
        address underlyingToken;
        bool solved;
    }

    mapping(bytes32 => Lending) public lendings; // lending id => Lending
    mapping(uint256 => DepegInfo) public depegInfos; // pid => DepegInfo

    event SetGovernance(address _governance);
    event TriggerActivated(uint256 _pid, address _underlyingToken, uint256[] _args);
    event Protect(uint256 _pid, bytes32 _lendingId, uint256 _tokens, address _underlyingToken);
    event Unprotect(bytes32 _lendingId);
    event Solved(bytes32 _lendingId, address _underlyingToken, address _recipient, uint256 _withdrawed);
    event AddDepegPool(uint256 _lendingMarketPid, address[] _underlyingTokens, uint256[] _corrspondedCoins, address _adapter, address _adapterPool);
    event Trigger(uint256 _pid, address _underlyingToken, uint256 _tokens);

    modifier onlyLendingMarket() {
        require(lendingMarket == msg.sender, "DepegShieldWrapper: Caller is not the lendingMarket");

        _;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "DepegShieldWrapper: Caller is not the governance");
        _;
    }

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() public initializer {}

    function initialize(address _governance, address _lendingMarket) public initializer {
        governance = _governance;
        lendingMarket = _lendingMarket;
    }

    function checkAndToggleTrigger(uint256 _pid, address _underlyingToken) external override returns (bool) {
        DepegInfo storage depeg = depegInfos[_pid];

        if (!depeg.isExist) return false;
        if (depeg.triggers[_underlyingToken]) return true;
        if (depeg.totalCollaterals[_underlyingToken] == 0) return false;

        uint256[] memory args = new uint256[](3);

        args[0] = depeg.totalCollaterals[_underlyingToken];
        args[1] = depeg.corrspondedCoins[_underlyingToken];
        args[2] = 0; // minOut

        if (!IAdapter(depeg.adapter).isTriggered(depeg.adapterPool, abi.encode(args))) return false;

        emit TriggerActivated(_pid, _underlyingToken, args);

        depeg.triggers[_underlyingToken] = true;

        return true;
    }

    function trigger(
        uint256 _pid,
        address _underlyingToken,
        uint256 _tokens
    ) public override onlyLendingMarket nonReentrant {
        DepegInfo storage depeg = depegInfos[_pid];

        require(depeg.isExist, "DepegShieldWrapper: !isExist");
        require(depeg.triggers[_underlyingToken], "DepegShieldWrapper: Not triggered");
        require(depeg.balances[_underlyingToken] == 0, "DepegShieldWrapper: Triggered");

        depeg.balances[_underlyingToken] = _tokens;

        emit Trigger(_pid, _underlyingToken, _tokens);
    }

    function protect(
        uint256 _pid,
        bytes32 _lendingId,
        uint256 _tokens,
        address _underlyingToken
    ) public override onlyLendingMarket nonReentrant returns (bool) {
        require(_tokens > 0, "DepegShieldWrapper: !_tokens");

        DepegInfo storage depeg = depegInfos[_pid];

        if (!depeg.isExist) return false;

        Lending storage lending = lendings[_lendingId];

        require(!depeg.triggers[_underlyingToken], "DepegShieldWrapper: Triggered");
        require(lending.totalCollateral == 0 && !lending.solved, "DepegShieldWrapper: Already exists");

        lending.underlyingToken = _underlyingToken;
        lending.totalCollateral = _tokens;
        lending.pid = _pid;

        depeg.totalCollaterals[_underlyingToken] = depeg.totalCollaterals[_underlyingToken].add(_tokens);

        emit Protect(_pid, _lendingId, _tokens, _underlyingToken);

        return true;
    }

    function unprotect(bytes32 _lendingId) public override onlyLendingMarket nonReentrant {
        Lending storage lending = lendings[_lendingId];
        DepegInfo storage depeg = depegInfos[lending.pid];

        require(!depeg.triggers[lending.underlyingToken], "DepegShieldWrapper: Triggered");
        require(lending.totalCollateral > 0, "DepegShieldWrapper: Invalid lendingId");
        require(!lending.solved, "DepegShieldWrapper: Solved");

        depeg.totalCollaterals[lending.underlyingToken] = depeg.totalCollaterals[lending.underlyingToken].sub(lending.totalCollateral);
        lending.totalCollateral = 0;

        emit Unprotect(_lendingId);
    }

    function solved(bytes32 _lendingId, address _recipient) public override onlyLendingMarket nonReentrant returns (address, uint256) {
        Lending storage lending = lendings[_lendingId];
        DepegInfo storage depeg = depegInfos[lending.pid];

        require(lending.totalCollateral > 0, "DepegShieldWrapper: Invalid lendingId");
        require(!lending.solved, "DepegShieldWrapper: Solved");
        require(depeg.triggers[lending.underlyingToken], "DepegShieldWrapper: Not trigger");

        uint256 withdrawed = _calculateAmount(
            depeg.totalCollaterals[lending.underlyingToken],
            depeg.balances[lending.underlyingToken],
            lending.totalCollateral
        );

        require(withdrawed > 0, "DepegShieldWrapper: !withdrawed");

        _withdraw(lending.underlyingToken, _recipient, withdrawed);

        lending.solved = true;

        emit Solved(_lendingId, lending.underlyingToken, _recipient, withdrawed);

        return (lending.underlyingToken, withdrawed);
    }

    function _withdraw(
        address _underlyingToken,
        address _recipient,
        uint256 _tokens
    ) internal {
        if (_underlyingToken == ZERO_ADDRESS) {
            payable(_recipient).sendValue(_tokens);
        } else {
            IERC20(_underlyingToken).safeTransfer(_recipient, _tokens);
        }
    }

    function setPool(
        uint256 _lendingMarketPid,
        address[] calldata _underlyingTokens,
        uint256[] calldata _corrspondedCoins,
        address _adapter,
        address _adapterPool
    ) public onlyGovernance {
        DepegInfo storage depeg = depegInfos[_lendingMarketPid];

        require(_underlyingTokens.length == _corrspondedCoins.length, "DepegShieldWrapper: Length mismatch");
        require(!depeg.isExist, "DepegShieldWrapper: !exist");

        depeg.adapter = _adapter;
        depeg.adapterPool = _adapterPool;
        depeg.underlyingTokens = _underlyingTokens;

        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            depeg.corrspondedCoins[_underlyingTokens[i]] = _corrspondedCoins[i];
        }

        depeg.isExist = true;

        emit AddDepegPool(_lendingMarketPid, _underlyingTokens, _corrspondedCoins, _adapter, _adapterPool);
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /* view functions */

    function _calculateAmount(
        uint256 _totalCollaterals,
        uint256 _bal,
        uint256 _tokens
    ) internal pure returns (uint256) {
        uint256 withdrawed = (_tokens.mul(PRECISION) / _totalCollaterals).mul(_bal) / PRECISION;

        return withdrawed;
    }

    function calculateAmount(bytes32 _lendingId) external view override returns (uint256) {
        Lending storage lending = lendings[_lendingId];
        DepegInfo storage depeg = depegInfos[lending.pid];

        if (lending.totalCollateral == 0 || lending.solved) return 0;

        uint256 withdrawed = _calculateAmount(
            depeg.totalCollaterals[lending.underlyingToken],
            depeg.balances[lending.underlyingToken],
            lending.totalCollateral
        );

        return withdrawed;
    }

    function isProtect(bytes32 _lendingId) external view override returns (bool, address) {
        Lending storage lending = lendings[_lendingId];

        if (lending.totalCollateral > 0 && !lending.solved) return (true, lending.underlyingToken);

        return (false, address(0));
    }

    function isTriggered(uint256 _pid, address _underlyingToken) external view override returns (bool) {
        DepegInfo storage depeg = depegInfos[_pid];

        return depeg.triggers[_underlyingToken];
    }

    function getInfo(uint256 _pid, address _underlyingToken)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        DepegInfo storage depeg = depegInfos[_pid];

        return (depeg.isExist, depeg.totalCollaterals[_underlyingToken], depeg.balances[_underlyingToken]);
    }
}
