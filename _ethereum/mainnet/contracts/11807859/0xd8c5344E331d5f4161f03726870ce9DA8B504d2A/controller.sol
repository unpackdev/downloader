pragma solidity 0.5.15;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IOneSplitAudit.sol";
import "./IStrategy.sol";
import "./IConverter.sol";
import "./IVault.sol";

contract Controller {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address public governance;
    address public onesplit;
    address public rewards;
    address public belRewards;
    address public fireman;
    
    // token to Vault mapping
    mapping(address => address) public vaults;
    // token to IStrategy mapping
    mapping(address => address) public strategies;
    
    mapping(address => mapping(address => address)) public converters;
    
    uint256 public split = 2000; // fee for dust
    uint256 public constant max = 10000;

    bool public paused = false;
    mapping(address => bool) public pauseRoles;
    
    constructor(address _rewards, address _belRewards, address _governance, address _fireman) public {
        governance = _governance;
        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
        rewards = _rewards;
        belRewards = _belRewards;
        fireman = _fireman;
    }

    function setPauseRole(address admin) external {
        require(msg.sender == governance, "!governance");
        pauseRoles[admin] = true;
    }

    function unSetPauseRole(address admin) external {
        require(msg.sender == governance, "!governance");
        pauseRoles[admin] = false;
    }

    function pause() external {
        require(pauseRoles[msg.sender], "no right to pause!");
        paused = true;
    }

    function unpause() external {
        require(pauseRoles[msg.sender], "no right to pause!");
        paused = false;
    }
  
    function setRewards(address _rewards) external {
        require(msg.sender == governance, "!governance");
        rewards = _rewards;
    }

    function setBelRewards(address _belRewards) external {
        require(msg.sender == governance, "!governance");
        belRewards = _belRewards;
    }

    function setSplit(uint256 _split) external {
        require(msg.sender == governance, "!governance");
        split = _split;
    }
    
    function setOneSplit(address _onesplit) external {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVault(address _token, address _vault) public {
        require( msg.sender == governance, "!governance");
        require(vaults[_token] == address(0), "vault");
        require(IVault(_vault).token() == _token, "inconsist token in vault!");
        vaults[_token] = _vault;
    }
    
    function setConverter(address _input, address _output, address _converter) external {
        require(msg.sender == governance, "!governance");
        converters[_input][_output] = _converter;
    }
    
    function setStrategy(address _token, address _strategy) external {
        require(msg.sender == governance, "!governance");
        require(IStrategy(_strategy).want() == _token, "incosist token in strategy!");
        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }
    
    function earn(address _token, uint256 _amount) public {
        require((msg.sender == tx.origin) ||
            (msg.sender == governance) ||
            (msg.sender == vaults[_token]), "!contract");

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

    function underlyingBalanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).underlyingBalanceOf();
    }
    
    function withdrawAll(address _token) public {
        require(msg.sender == governance || msg.sender == fireman, "!governance");
        // WithdrawAll sends 'want' to 'vault'
        IStrategy(strategies[_token]).withdrawAll();
    }
    
    function inCaseTokensGetStuck(address _token, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        IERC20(_token).safeTransfer(governance, _amount);
    }
    
    function inCaseStrategyGetStuck(address _strategy, address _token) external {
        require(msg.sender == governance, "!governance");
        IStrategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }
    
    function getExpectedReturn(address _strategy, address _token, uint256 parts) external view returns (uint256 expected) {
        uint256 _balance = IERC20(_token).balanceOf(_strategy);
        address _want = IStrategy(_strategy).want();
        (expected, ) = IOneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
    }
    
    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function bearn(address _strategy, address _token, uint256 parts) external {
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
            (_expected, _distribution) = IOneSplitAudit(onesplit).getExpectedReturn(_token, _want, _amount, parts, 0);
            IOneSplitAudit(onesplit).swap(_token, _want, _amount, _expected, _distribution, 0);
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
}