// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IConverter.sol";
import "./IOneSplitAudit.sol";
import "./IStrategy.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./AccessManager.sol";

contract Controller is AccessManager {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public strategist;

    address public onesplit;
    address public rewards;
    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;

    mapping(address => mapping(address => bool)) public approvedStrategies;

    uint256 public split = 500;
    uint256 public constant max = 10000;

    constructor(address _rewards, address _governance, address _admin) public {
        governance = _governance;
        strategist = _governance;
        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
        rewards = _rewards;
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setRewards(address _rewards) public onlyGovernance {
        rewards = _rewards;
    }

    function setStrategist(address _strategist) public onlyGovernance {
        strategist = _strategist;
    }

    function setSplit(uint256 _split) public onlyGovernance {
        split = _split;
    }

    function setOneSplit(address _onesplit) public onlyGovernance {
        onesplit = _onesplit;
    }

    function setVault(address _token, address _vault)
        public
        onlyGovernanceOrStrategist
    {
        require(vaults[_token] == address(0), "vault");
        vaults[_token] = _vault;
    }

    function approveStrategy(address _token, address _strategy)
        public
        onlyGovernance
    {
        approvedStrategies[_token][_strategy] = true;
    }

    function revokeStrategy(address _token, address _strategy)
        public
        onlyGovernance
    {
        approvedStrategies[_token][_strategy] = false;
    }

    function setConverter(
        address _input,
        address _output,
        address _converter
    ) public onlyGovernanceOrStrategist {
        converters[_input][_output] = _converter;
    }

    function setStrategy(address _token, address _strategy)
        public
        onlyGovernanceOrStrategist
    {
        require(approvedStrategies[_token][_strategy] == true, "!approved");

        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).want();
        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = IConverter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).deposit();
    }

    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    function withdrawalFee(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).withdrawalFee();
    }

    function withdrawAll(address _token) public onlyGovernanceOrStrategist {
        IStrategy(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount)
        public
        onlyGovernanceOrStrategist
    {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token)
        public
        onlyGovernanceOrStrategist
    {
        IStrategy(_strategy).withdraw(_token);
    }

    function getExpectedReturn(
        address _strategy,
        address _token,
        uint256 parts
    ) public view returns (uint256 expected) {
        uint256 _balance = IERC20(_token).balanceOf(_strategy);
        address _want = IStrategy(_strategy).want();
        (expected, ) = IOneSplitAudit(onesplit).getExpectedReturn(
            _token,
            _want,
            _balance,
            parts,
            0
        );
    }

    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function yearn(
        address _strategy,
        address _token,
        uint256 parts
    ) public onlyGovernanceOrStrategist {
        // This contract should never have value in it, but just incase since this is a public call
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IStrategy(_strategy).withdraw(_token);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint256 _amount = _after.sub(_before);
            address _want = IStrategy(_strategy).want();
            uint256[] memory _distribution;
            uint256 _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_token).safeApprove(onesplit, 0);
            IERC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = IOneSplitAudit(onesplit)
                .getExpectedReturn(_token, _want, _amount, parts, 0);
            IOneSplitAudit(onesplit).swap(
                _token,
                _want,
                _amount,
                _expected,
                _distribution,
                0
            );
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint256 _reward = _amount.mul(split).div(max);
                earn(_want, _amount.sub(_reward));
                IERC20(_want).safeTransfer(rewards, _reward);
            }
        }
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == vaults[_token], "!vault");
        IStrategy(strategies[_token]).withdraw(_amount);
    }

    modifier onlyGovernanceOrStrategist() {
        require(
            msg.sender == strategist || msg.sender == governance || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "!strategist"
        );
        _;
    }
}
