pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IDebt.sol";
import "./IRates.sol";
import "./IPoolCallback.sol";
import "./ISystemSettings.sol";
import "./BasicMaths.sol";

contract Debt is ERC20, IDebt {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using SafeERC20 for IERC20;

    address public _poolToken;
    address public _settings;
    address private _owner;

    constructor(
        address owner,
        address poolToken,
        address setting,
        string memory symbol
    ) ERC20(symbol, symbol) {
        _setupDecimals(ERC20(poolToken).decimals());

        _owner = owner;
        _poolToken = poolToken;
        _settings = setting;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function issueBonds(address recipient, uint256 amount) external override onlyOwner {
        _mint(recipient, amount);
    }

    function burnBonds(uint256 amount) external override onlyOwner {
        _burn(address(this), amount);
    }

    // call from router
    function repayLoan(address payer, address recipient, uint256 amount) external override {

        IRates pool = IRates(_owner);
        IPoolCallback(msg.sender).poolV2BondsCallbackFromDebt(
            amount,
            _poolToken,
            pool.oraclePool(),
            payer,
            pool.reverse()
        );

        _burn(address(this), amount);
        uint256 poolTokenAmount = ISystemSettings(_settings).mulInterestFromDebt(amount);
        require(poolTokenAmount <= IERC20(_poolToken).balanceOf(address(this)), "Insufficient token to repay loan");
        IERC20(_poolToken).safeTransfer(recipient, poolTokenAmount);
        emit RepayLoan(recipient, amount, poolTokenAmount);
    }

    function totalDebt() external override view returns (uint256) {
        return ISystemSettings(_settings).mulInterestFromDebt(totalSupply()).
        sub2Zero(IERC20(_poolToken).balanceOf(address(this)));
    }

    function bondsLeft() external override view returns (uint256) {
        return totalSupply().sub2Zero(
            ISystemSettings(_settings).divInterestFromDebt(
                IERC20(_poolToken).balanceOf(address(this))
            )
        );
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }
}
