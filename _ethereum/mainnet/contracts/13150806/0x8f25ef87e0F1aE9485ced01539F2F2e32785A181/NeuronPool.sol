pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";

import "./IController.sol";

import "./GaugesDistributor.sol";
import "./Gauge.sol";

contract NeuronPool is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token accepted by the contract. E.g. 3Crv for 3poolCrv pool
    // Usually want/_want in strategies
    IERC20 public token;

    uint256 public min = 9500;
    uint256 public constant max = 10000;

    uint8 public immutable _decimals;

    address public governance;
    address public timelock;
    address public controller;
    address public masterchef;
    GaugesDistributor public gaugesDistributor;

    constructor(
        // Token accepted by the contract. E.g. 3Crv for 3poolCrv pool
        // Usually want/_want in strategies
        address _token,
        address _governance,
        address _timelock,
        address _controller,
        address _masterchef,
        address _gaugesDistributor
    )
        ERC20(
            string(abi.encodePacked("neuroned", ERC20(_token).name())),
            string(abi.encodePacked("neur", ERC20(_token).symbol()))
        )
    {
        _decimals = ERC20(_token).decimals();
        token = IERC20(_token);
        governance = _governance;
        timelock = _timelock;
        controller = _controller;
        masterchef = _masterchef;
        gaugesDistributor = GaugesDistributor(_gaugesDistributor);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // Balance = pool's balance + pool's token controller contract balance
    function balance() public view returns (uint256) {
        return
            token.balanceOf(address(this)).add(
                IController(controller).balanceOf(address(token))
            );
    }

    function setMin(uint256 _min) external {
        require(msg.sender == governance, "!governance");
        require(_min <= max, "numerator cannot be greater than denominator");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) public {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    // Returns tokens available for deposit into the pool
    // Custom logic in here for how much the pools allows to be borrowed
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    // Depositing tokens into pool
    // Usually called manually in tests
    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        IController(controller).earn(address(token), _bal);
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    // User's entry point; called on pressing Deposit in Neuron's UI
    function deposit(uint256 _amount) public {
        // Pool's + controller balances
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        // totalSupply - total supply of pToken, given in exchange for depositing to a pool, eg p3CRV for 3Crv
        if (totalSupply() == 0) {
            // Tokens user will get in exchange for deposit. First user receives tokens equal to deposit.
            shares = _amount;
        } else {
            // For subsequent users: (tokens_stacked * exist_pTokens) / total_tokens_stacked. total_tokesn_stacked - not considering first users
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function depositAndFarm(uint256 _amount) public {
        // Pool's + controller balances
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        // totalSupply - total supply of pToken, given in exchange for depositing to a pool, eg p3CRV for 3Crv
        if (totalSupply() == 0) {
            // Tokens user will get in exchange for deposit. First user receives tokens equal to deposit.
            shares = _amount;
        } else {
            // For subsequent users: (tokens_stacked * exist_pTokens) / total_tokens_stacked. total_tokesn_stacked - not considering first users
            shares = (_amount.mul(totalSupply())).div(_pool);
        }

        Gauge gauge = Gauge(gaugesDistributor.getGauge(address(this)));
        _mint(address(gauge), shares);
        gauge.depositStateUpdateByPool(msg.sender, shares);
    }

    function withdrawAll() external {
        withdrawFor(msg.sender, balanceOf(msg.sender), msg.sender);
    }

    function withdraw(uint256 _shares) external {
        withdrawFor(msg.sender, _shares, msg.sender);
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint256 amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdrawFor(
        address holder,
        uint256 _shares,
        address burnFrom
    ) internal {
        // _shares - tokens user wants to withdraw
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(burnFrom, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        // If pool balance's not enough, we're withdrawing the controller's tokens
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(holder, r);
    }

    function withdrawAllRightFromFarm() external {
        Gauge gauge = Gauge(gaugesDistributor.getGauge(address(this)));
        uint256 shares = gauge.withdrawAllStateUpdateByPool(msg.sender);
        withdrawFor(msg.sender, shares, address(gauge));
    }

    function getRatio() public view returns (uint256) {
        uint256 currentTotalSupply = totalSupply();
        if (currentTotalSupply == 0) {
            return 0;
        }
        return balance().mul(1e18).div(currentTotalSupply);
    }
}
