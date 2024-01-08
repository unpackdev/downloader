// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IOneSplitAudit.sol";
import "./IStrategy.sol";
import "./IController.sol";

/// @title Controller yAgnostic.
/// @notice Main point of management of all contracts yAgnostic.
contract Controller is IController, Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /// @notice Variable storing the governance address. By default it is equal to the deployer of the controller.
    /// @dev Specified when creating the controller (in the constructor).
    /// @dev Can also be changed using the setGovernance method.
    /// @return Returns the governance address of this contract.
    address public governance;

    /// @notice Variable storing the strategist address. By default it is equal to the deployer of the controller.
    /// @dev Specified when creating the controller (in the constructor).
    /// @dev Can also be changed using the setStrategist method.
    /// @return Returns the strategist address of this contract.
    address public strategist;

    /// @notice Variable storing the onesplit address.
    /// @notice By default, fixed address.
    /// @dev Specified when creating the controller (in the constructor).
    /// @dev Can also be changed using the setOneSplit method.
    /// @return Returns the onesplit address of this contract.
    address public onesplit;

    /// @notice Variable storing the strategist address.
    /// @notice By default, it is equal to the address specified during deployment.
    /// @dev Specified when creating the controller (in the constructor).
    /// @dev Can also be changed using the setRewards method.
    /// @return Returns the strategist address of this contract.
    address public override rewards;

    /// @notice The address of the token associated with the vault.
    /// @dev Input parameter: vault.
    /// @return Returns the token address of this vault.
    mapping(address => address) public override tokens;

    /// @notice The address of the strategie associated with the vault.
    /// @dev Input parameter: vault.
    /// @return Returns the strategy address of this vault.
    mapping(address => address) public override strategies;

    /// @notice The address of the strategie associated with the vault.
    /// @dev Input parameter: vault and strategy.
    /// @return Returns the status of the strategy, approved or not(boolean true or false).
    mapping(address => mapping(address => bool)) public override approvedStrategies;

    /// @notice Part of the split.
    /// @dev The maximum value is 10000(100%). (This is the split percentage).
    /// @dev Can also be changed using the setSplit method.
    /// @return Returns the split.
    uint256 public split = 500;

    /// @notice Max value the split.
    /// @dev By default: 10000(100%).
    /// @return Returns the status of the strategy, approved or not(boolean true or false).
    uint256 public constant MAX = 10000;


    modifier governanceOnly() {
        require(_msgSender() == governance, "Not the governance");
        _;
    }

    modifier governanceOrStrategy() {
        require(_msgSender() == strategist || _msgSender() == governance, "Not a governance or strategist");
        _;
    }

    /// @notice Executed when the contract is deployed.
    /// @dev Sets the governance address and strategist address equal to the deployer. onesplit fixed address.
    /// @param _rewards The address of the rewards.
    constructor(address _rewards) public {
        governance = _msgSender();
        strategist = _msgSender();
        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
        rewards = _rewards;
    }

    /// @notice Installs a new rewards address.
    /// @dev Can only be called by governance. By default, it is equal to the address specified during deployment.
    /// @param _rewards The address of the new rewards.
    function setRewards(address _rewards) external governanceOnly {
        rewards = _rewards;
    }

    /// @notice Installs a new strategist.
    /// @dev Can only be called by governance. By default it is equal to the deployer of the controller.
    /// @param _strategist The address of the new strategist.
    function setStrategist(address _strategist) external governanceOnly {
        strategist = _strategist;
    }

    /// @notice Set split.
    /// @dev Can only be called by governance. The maximum value is 10000(100%).
    /// @param _split Part of the split.
    function setSplit(uint256 _split) external governanceOnly {
        split = _split;
    }

    /// @notice Sets DEX (1Inch by default) split address.
    /// @dev Can only be called by governance.
    /// @param _onesplit Address of the DEX split.
    function setOneSplit(address _onesplit) external governanceOnly {
        onesplit = _onesplit;
    }

    /// @notice Specifies a new governance address.
    /// @dev Can only be called by governance.
    /// @param _governance Address of the new governance.
    function setGovernance(address _governance) external governanceOnly {
        governance = _governance;
    }

    /// @notice Binds a token to a vault.
    /// @dev Can only be called by governance or strategist.
    /// @param _token Address of the token.
    /// @param _vault Address of the vault.
    function setVault(address _token, address _vault) external governanceOrStrategy {
        tokens[_vault] = _token;
    }

    /// @notice Approves strategy for binding to vault.
    /// @dev Can only be called by governance.
    /// @param _vault Address of the vault.
    /// @param _strategy Address of the strategy.
    function approveStrategy(address _vault, address _strategy) external governanceOnly {
        approvedStrategies[_vault][_strategy] = true;
    }

    /// @notice Revokes strategy approval for vault.
    /// @dev Can only be called by governance.
    /// @param _vault Address of the vault.
    /// @param _strategy Address of the strategy.
    function revokeStrategy(address _vault, address _strategy) external governanceOnly {
        approvedStrategies[_vault][_strategy] = false;
    }

    /// @notice Sets the strategy for the vault.
    /// @dev Can only be called by governance or strategist.
    /// @dev Before calling, you need to call the approveStrategy method.
    /// @param _vault Address of the vault.
    /// @param _strategy Address of the strategy.
    function setStrategy(address _vault, address _strategy) external governanceOrStrategy nonReentrant {
        require(approvedStrategies[_vault][_strategy] == true, "!approved");

        address _current = strategies[_vault];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_vault] = _strategy;
    }

    /// @notice Method transferring tokens to a strategy.
    /// @dev Then the strategy transfers tokens to earn.
    /// @param _vault Address of the vault.
    /// @param _token Address of the token to earn in.
    /// @param _amount Amount of the tokens.
    function earn(address _vault, address _token, uint256 _amount) public override {
        address _strategy = strategies[_vault];
        address _want = IStrategy(_strategy).want();
        
        if (_want != _token) {
            IERC20(_token).safeTransfer(_strategy, _amount);
            _amount = IStrategy(_strategy).convert(_token);
        } else {
            IERC20(_want).safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).deposit();
    }

    /// @notice Сalls the strategy balanceOf.
    /// @param _vault Address of the vault.
    /// @return Balance of the strategy related to vault.
    function balanceOf(address _vault) external view override returns (uint256) {
        return IStrategy(strategies[_vault]).balanceOf();
    }

    /// @notice Returns strategy's want token.
    /// @param _vault Address of the vault.
    /// @return want token for the strategy.
    function want(address _vault) external view override returns(address) {
        return IStrategy(strategies[_vault]).want();
    }

    /// @notice Сalls the strategy withdrawAll.
    /// @dev Can only be called by governance or strategist.
    /// @param _vault Address of the vault.
    function withdrawAll(address _vault) external governanceOrStrategy {
        IStrategy(strategies[_vault]).withdrawAll();
    }

    /// @notice Sends the required amount of token to the sender
    /// @dev Can only be called by governance or strategist.
    /// @param _token Address of the token.
    /// @param _amount Amount of the tokens.
    function inCaseTokensGetStuck(address _token, uint256 _amount) external governanceOrStrategy {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice Calls withdraw of the strategy token.
    /// @dev Can only be called by governance or strategist.
    /// @param _token Address of the token.
    /// @param _strategy Address of the strategy.
    function inCaseStrategyTokenGetStuck(address _strategy, address _token) external governanceOrStrategy {
        IStrategy(_strategy).withdraw(_token);
    }

    /// @notice Returns the amount if want token in exchange for token.
    /// @dev Call the appropriate method of OneSplit (1Inch by default) DEX
    /// @param _strategy Address of the strategy.
    /// @param _token Address of the token.
    /// @param parts Amount of token.
    function getExpectedReturn(
         address _strategy,
         address _token,
         uint256 parts
    ) external view returns (uint256 expected) {
         uint256 _balance = IERC20(_token).balanceOf(_strategy);
         address _want = IStrategy(_strategy).want();
         (expected, ) = IOneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
    }

    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    /// @notice Calls earn and transfer rewords
    /// @dev Can only be called by governance or strategist.
    /// @dev This contract should never have value in it, but just incase since this is a public call.
    /// @param _vault Address of the vault.
    /// @param parts Need for IOneSplitAudit.
    function yearn(
        address _vault,
        address _token,
        uint256 parts
    ) external governanceOrStrategy {
        address _strategy = strategies[_vault];
        address _want = IStrategy(_strategy).want();
        require(_token != _want, "token is equal to want");
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IStrategy(_strategy).withdraw(_token);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint256 _amount = _after.sub(_before);
            uint256[] memory _distribution;
            uint256 _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_token).safeApprove(onesplit, 0);
            IERC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = IOneSplitAudit(onesplit).getExpectedReturn(_token, _want, _amount, parts, 0);
            IOneSplitAudit(onesplit).swap(_token, _want, _amount, _expected, _distribution, 0);
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint256 _reward = _amount.mul(split).div(MAX);
                earn(_vault, _want, _amount.sub(_reward));
                IERC20(_want).safeTransfer(rewards, _reward);
            }
        }
    }

    /// @notice Сalls the strategy withdraw.
    /// @dev Can only be called by vault.
    /// @param _amount Amount of the tokens.
    function withdraw(uint256 _amount) external override {
        require(strategies[_msgSender()] != address(0), "Caller is not a vault");
        IStrategy(strategies[_msgSender()]).withdraw(_amount);
    }
}
