pragma solidity 0.6.4;

import "./IWETH.sol";
import "./UniswapV2Library.sol";
import "./LibSafeApproval.sol";
import "./IPSmartPool.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Exchange.sol";
import "./ISmartPoolRegistry.sol";
import "./Ownable.sol";
import "./ChiGasSaver.sol";

contract UniswapV2Recipe is Ownable, ChiGasSaver {
    using LibSafeApprove for IERC20;

    IWETH public constant WETH = IWETH(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    ISmartPoolRegistry public constant registry = ISmartPoolRegistry(
        0x412a5d5eC35fF185D6BfF32a367a985e1FB7c296
    );
    address payable
        public constant gasSponsor = 0x3bFdA5285416eB06Ebc8bc0aBf7d105813af06d0;
    bool private isPaused = false;

    // Pauzer
    modifier revertIfPaused {
        if (isPaused) {
            revert("[UniswapV2Recipe] is Paused");
        } else {
            _;
        }
    }

    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }

    constructor() public {
        _setOwner(msg.sender);
    }

    // Max eth amount enforced by msg.value
    function toPie(address _pie, uint256 _poolAmount)
        external
        payable
        revertIfPaused
        saveGas(gasSponsor)
    {
        require(registry.inRegistry(_pie), "Not a Pie");
        uint256 totalEth = calcToPie(_pie, _poolAmount);
        require(msg.value >= totalEth, "Amount ETH too low");

        WETH.deposit{value: totalEth}();

        _toPie(_pie, _poolAmount);

        // return excess ETH
        if (address(this).balance != 0) {
            // Send any excess ETH back
            msg.sender.transfer(address(this).balance);
        }

        // Transfer pool tokens to msg.sender
        IERC20 pie = IERC20(_pie);

        IERC20(pie).transfer(msg.sender, pie.balanceOf(address(this)));
    }

    function _toPie(address _pie, uint256 _poolAmount) internal {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        for (uint256 i = 0; i < tokens.length; i++) {
            _swapToToken(tokens[i], amounts[i], _pie);
        }

        IPSmartPool pie = IPSmartPool(_pie);
        pie.joinPool(_poolAmount);
    }

    function _swapToToken(
        address _token,
        uint256 _amount,
        address _pie
    ) internal virtual {
        
        if(_token == address(WETH)) {
            IERC20(address(WETH)).safeApprove(_pie, _amount);
            return;
        }


        if (registry.inRegistry(_token)) {
            _toPie(_token, _amount);
        } else {
            IUniswapV2Exchange pair = IUniswapV2Exchange(
                UniLib.pairFor(address(uniswapFactory), _token, address(WETH))
            );

            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                address(WETH),
                _token
            );
            uint256 amountIn = UniLib.getAmountIn(_amount, reserveA, reserveB);

            // UniswapV2 does not pull the token
            WETH.transfer(address(pair), amountIn);

            if (token0Or1(address(WETH), _token) == 0) {
                pair.swap(_amount, 0, address(this), new bytes(0));
            } else {
                pair.swap(0, _amount, address(this), new bytes(0));
            }
        }

        IERC20(_token).safeApprove(_pie, _amount);
    }

    function calcToPie(address _pie, uint256 _poolAmount)
        public
        virtual
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] == address(WETH)) {
                totalEth += amounts[i];
            }
            else if (registry.inRegistry(tokens[i])) {
                totalEth += calcToPie(tokens[i], amounts[i]);
            } else {
                (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                    address(uniswapFactory),
                    address(WETH),
                    tokens[i]
                );
                totalEth += UniLib.getAmountIn(amounts[i], reserveA, reserveB);
            }
        }

        return totalEth;
    }

    function calcEthAmount(address _token, uint256 _buyAmount)
        internal
        virtual
        returns (uint256)
    {   
        if(_token == address(WETH)) {
            return _buyAmount;
        }

        if (registry.inRegistry(_token)) {
            return calcToPie(_token, _buyAmount);
        } else {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                address(WETH),
                _token
            );
            return UniLib.getAmountIn(_buyAmount, reserveA, reserveB);
        }
    }

    // TODO recursive exit
    function toEth(
        address _pie,
        uint256 _poolAmount,
        uint256 _minEthAmount
    ) external revertIfPaused saveGas(gasSponsor) {
        uint256 totalEth = calcToPie(_pie, _poolAmount);
        require(_minEthAmount <= totalEth, "Output ETH amount too low");
        IPSmartPool pie = IPSmartPool(_pie);

        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);
        pie.transferFrom(msg.sender, address(this), _poolAmount);
        pie.exitPool(_poolAmount);

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                tokens[i],
                address(WETH)
            );
            uint256 wethAmountOut = UniLib.getAmountOut(
                amounts[i],
                reserveA,
                reserveB
            );
            IUniswapV2Exchange pair = IUniswapV2Exchange(
                UniLib.pairFor(
                    address(uniswapFactory),
                    tokens[i],
                    address(WETH)
                )
            );

            // Uniswap V2 does not pull the token
            IERC20(tokens[i]).transfer(address(pair), amounts[i]);

            if (token0Or1(address(WETH), tokens[i]) == 0) {
                pair.swap(0, wethAmountOut, address(this), new bytes(0));
            } else {
                pair.swap(wethAmountOut, 0, address(this), new bytes(0));
            }
        }

        WETH.withdraw(totalEth);
        msg.sender.transfer(address(this).balance);
    }

    function calcToEth(address _pie, uint256 _poolAmountOut)
        external
        view
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmountOut);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                address(uniswapFactory),
                tokens[i],
                address(WETH)
            );
            totalEth += UniLib.getAmountOut(amounts[i], reserveA, reserveB);
        }

        return totalEth;
    }

    function token0Or1(address tokenA, address tokenB)
        internal
        view
        returns (uint256)
    {
        (address token0, address token1) = UniLib.sortTokens(tokenA, tokenB);

        if (token0 == tokenB) {
            return 0;
        }

        return 1;
    }

    function saveEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function saveToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
