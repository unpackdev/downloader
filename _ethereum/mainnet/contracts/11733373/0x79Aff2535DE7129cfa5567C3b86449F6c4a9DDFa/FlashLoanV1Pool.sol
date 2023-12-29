pragma solidity =0.5.16;

import "./IFlashLoanV1Pool.sol";
import "./FlashLoanV1ERC20.sol";
import "./IERC20.sol";
import "./IFlashLoanV1Factory.sol";
import "./IFlashLoanReceiver.sol";

contract FlashLoanV1Pool is IFlashLoanV1Pool, FlashLoanV1ERC20 {
    using SafeMath  for uint;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token;

    uint public reserve; // uses single storage slot, accessible via getReserves

    uint public kLast; // reserve, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'FlashLoanV1: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function _safeTransfer(address _token, address to, uint value) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FlashLoanV1: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint amount,
        uint premium
    );
    event Sync(uint reserve);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token) external {
        require(msg.sender == factory, 'FlashLoanV1: FORBIDDEN'); // sufficient check
        token = _token;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance) private {
        require(balance <= uint112(-1), 'FlashLoanV1: OVERFLOW');
        reserve = balance;
        emit Sync(reserve);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth
    function _mintFee(uint k) private returns (bool feeOn) {
        address feeTo = IFlashLoanV1Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                if (k > _kLast) {
                    uint numerator = totalSupply.mul(k.sub(_kLast));
                    uint denominator = k.mul(5).add(_kLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        uint _reserve = reserve; // gas savings
        uint balance = IERC20(token).balanceOf(address(this));
        uint amount = balance.sub(_reserve);

        bool feeOn = _mintFee(_reserve);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = amount.sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = amount.mul(_totalSupply) / reserve;
        }
        require(liquidity > 0, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance);
        if (feeOn) kLast = reserve; // reserve is up-to-date
        emit Mint(msg.sender, amount);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount) {
        uint _reserve = reserve; // gas savings
        address _token = token; // gas savings
        uint balance = IERC20(_token).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount = liquidity.mul(balance) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount > 0, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token, to, amount);
        balance = IERC20(_token).balanceOf(address(this));

        _update(balance);
        if (feeOn) kLast = reserve; // reserve is up-to-date
        emit Burn(msg.sender, amount, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function flashLoan(address target, uint amount, bytes calldata data) external lock {
        address _token = token; // gas savings
        require(amount > 0, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_TO_BORROW');

        uint balanceBefore = IERC20(_token).balanceOf(address(this));
        require(balanceBefore >= amount, 'FlashLoanV1: INSUFFICIENT_LIQUIDITY_TO_BORROW');

        uint feeInBips = IFlashLoanV1Factory(factory).feeInBips();
        uint amountFee = amount.mul(feeInBips) / 10000;
        require(amountFee > 0, 'FlashLoanV1: AMOUNT_TOO_SMALL');

        _safeTransfer(_token, target, amount);

        IFlashLoanReceiver receiver = IFlashLoanReceiver(target);
        receiver.executeOperation(_token, amount, amountFee, msg.sender, data);

        uint balanceAfter = IERC20(_token).balanceOf(address(this));
        require(balanceAfter == balanceBefore.add(amountFee), 'FlashLoanV1: AMOUNT_INCONSISTENT');

        _update(balanceAfter);
        emit FlashLoan(target, msg.sender, _token, amount, amountFee);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token = token; // gas savings
        _safeTransfer(_token, to, IERC20(_token).balanceOf(address(this)).sub(reserve));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token).balanceOf(address(this)));
    }
}
