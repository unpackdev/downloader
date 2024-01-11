// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* LIBRARY IMPORTS */

import "./UQ112x112.sol";

import "./IPair.sol";

import "./IPairFactory.sol";

import "./IPairCallee.sol";

import "./PairERC20.sol";

import "./Math.sol";

import "./ReentrancyGuard.sol";

import "./Context.sol";

import "./TransferHelper.sol";

contract Pair is IPair, PairERC20, ReentrancyGuard {
    using UQ112x112 for uint224;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;

    address public override factory;
    address public override token0;
    address public override token1;

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;
    uint256 public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint112 private _reserve0; // uses single storage slot, accessible via getReserves
    uint112 private _reserve1; // uses single storage slot, accessible via getReserves
    uint32 private _blockTimestampLast; // uses single storage slot, accessible via getReserves

    modifier onlyRouter() {
        require(_msgSender() == IPairFactory(factory).router(), "Pair:onlyRouter: FORBIDDEN");
        _;
    }

    constructor() {
        factory = _msgSender();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 salt,
        uint256 expiry,
        bytes calldata signature
    ) public override(IPairERC20, PairERC20) {
        super.permit(owner, spender, value, salt, expiry, signature);
    }

    // ANWERC20
    function totalSupply() public view override(IERC20, ANWERC20) returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override(IERC20, ANWERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) public override(IERC20, ANWERC20) returns (bool) {
        return super.transfer(recipient, amount);
    }

    function allowance(address owner, address spender) public view override(IERC20, ANWERC20) returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public override(IERC20, ANWERC20) returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(IERC20, ANWERC20) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function name() public view override(IERC20Metadata, ANWERC20) returns (string memory) {
        return super.name();
    }

    function symbol() public view override(IERC20Metadata, ANWERC20) returns (string memory) {
        return super.symbol();
    }

    function decimals() public view override(IERC20Metadata, ANWERC20) returns (uint8) {
        return super.decimals();
    }

    // Pair

    function getReserves()
        public
        view
        override
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        )
    {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = _blockTimestampLast;
    }

    // called once by the factory at time of deployment
    function initialize(address token0_, address token1_) external override {
        require(_msgSender() == factory, "Pair::initialize: FORBIDDEN"); // sufficient check
        token0 = token0_;
        token1 = token1_;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 reserve0,
        uint112 reserve1
    ) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "Pair::_update: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - _blockTimestampLast;
        } // overflow is desired

        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            // * UQ112x112 prevents overflows
            unchecked {
                price0CumulativeLast += uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
            } // + overflow is desired
            unchecked {
                price1CumulativeLast += uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
            } // + overflow is desired
        }

        _reserve0 = uint112(balance0);
        _reserve1 = uint112(balance1);
        _blockTimestampLast = blockTimestamp;

        emit Sync(_reserve0, _reserve1);
    }

    // if fee is on, mint liquidity equivalent to 8/25 of the growth in sqrt(k)
    function _mintFee(uint112 reserve0, uint112 reserve1) private returns (bool feeOn) {
        address feeTo = IPairFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 kLast_ = kLast; // gas savings
        if (feeOn) {
            if (kLast_ != 0) {
                uint256 rootK = _sqrt(uint256(reserve0) * uint256(reserve1));
                uint256 rootKLast = _sqrt(kLast_);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply() * (rootK - rootKLast) * 8;
                    uint256 denominator = (rootK * 17) + (rootKLast * 8);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (kLast_ != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    // only callable from designated Router contract
    function mint(address to) external override nonReentrant onlyRouter returns (uint256 liquidity) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        bool feeOn = _mintFee(reserve0, reserve1);
        uint256 supply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (supply == 0) {
            liquidity = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first _MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min((amount0 * supply) / reserve0, (amount1 * supply) / reserve1);
        }

        require(liquidity > 0, "Pair::mint: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, reserve0, reserve1);
        if (feeOn) kLast = uint256(_reserve0) * uint256(_reserve1); // _reserve0 and _reserve1 are up-to-date

        emit Mint(_msgSender(), amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // only callable from designated Router contract
    function burn(address to) external override nonReentrant onlyRouter returns (uint256 amount0, uint256 amount1) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves(); // gas savings
        address token0_ = token0; // gas savings
        address token1_ = token1; // gas savings
        uint256 balance0 = IERC20(token0_).balanceOf(address(this));
        uint256 balance1 = IERC20(token1_).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(reserve0, reserve1);
        uint256 supply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * balance0) / supply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / supply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "Pair::burn: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);

        TransferHelper.safeTransfer(token0_, to, amount0);
        TransferHelper.safeTransfer(token1_, to, amount1);

        balance0 = IERC20(token0_).balanceOf(address(this));
        balance1 = IERC20(token1_).balanceOf(address(this));

        _update(balance0, balance1, reserve0, reserve1);
        if (feeOn) kLast = uint256(_reserve0) * uint256(_reserve1); // _reserve0 and _reserve1 are up-to-date

        emit Burn(_msgSender(), amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // only callable from designated Router contract
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override nonReentrant onlyRouter {
        require(amount0Out > 0 || amount1Out > 0, "Pair::swap: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 reserve0, uint112 reserve1, ) = getReserves(); // gas savings
        require(amount0Out < reserve0 && amount1Out < reserve1, "Pair::swap: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address token0_ = token0;
            address token1_ = token1;
            require(to != token0_ && to != token1_, "Pair::swap: INVALID_TO");
            if (amount0Out > 0) TransferHelper.safeTransfer(token0_, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) TransferHelper.safeTransfer(token1_, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IPairCallee(to).pairCall(_msgSender(), amount0Out, amount1Out, data);
            balance0 = IERC20(token0_).balanceOf(address(this));
            balance1 = IERC20(token1_).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "Pair::swap: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            (uint256 fee, uint256 precision) = getSwapFee();
            uint256 balance0Adjusted = (balance0 * precision) - (amount0In * fee);

            uint256 balance1Adjusted = (balance1 * precision) - (amount1In * fee);
            require(
                (balance0Adjusted * balance1Adjusted) >= (uint256(reserve0) * uint256(reserve1) * precision**2),
                "Pair::swap: K"
            );
        }

        if (amount0In > 0) {
            balance0 = balance0 - _transferFeeToAdmin(token0, amount0In);
        } else {
            balance1 = balance1 - _transferFeeToAdmin(token1, amount1In);
        }

        _update(balance0, balance1, reserve0, reserve1);
        emit Swap(_msgSender(), amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override nonReentrant {
        address token0_ = token0; // gas savings
        address token1_ = token1; // gas savings
        TransferHelper.safeTransfer(token0_, to, IERC20(token0_).balanceOf(address(this)) - uint256(_reserve0));
        TransferHelper.safeTransfer(token1_, to, IERC20(token1_).balanceOf(address(this)) - uint256(_reserve1));
    }

    // force reserves to match balances
    function sync() external override nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);
    }

    function _sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function getSwapFee() internal view returns (uint256, uint256) {
        return IPairFactory(factory).getFeeSwap();
    }

    function _transferFeeToAdmin(address tokenFee, uint256 amount) private returns (uint256) {
        (address feeTo, uint256 fee, uint256 precision) = IPairFactory(factory).getInfoAdminFee();
        if (feeTo == address(0)) {
            return 0;
        }
        uint256 feeAmount = (amount * fee) / precision;
        TransferHelper.safeTransfer(tokenFee, feeTo, feeAmount);
        return feeAmount;
    }
}
