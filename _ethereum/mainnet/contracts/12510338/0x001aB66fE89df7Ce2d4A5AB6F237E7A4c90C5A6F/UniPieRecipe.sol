//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./IRecipe.sol";
import "./IUniRouter.sol";
import "./ILendingRegistry.sol";
import "./ILendingLogic.sol";
import "./IPieRegistry.sol";
import "./IPie.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract UniPieRecipe is IRecipe, Ownable {
    using SafeERC20 for IERC20;

    IERC20 immutable WETH;
    IUniRouter immutable uniRouter;
    IPieRegistry immutable pieRegistry;
    event Error(string text);

    event HopUpdated(address indexed _token, address indexed _hop);

    // Adds a custom hop before reaching the destination token
    mapping(address => CustomHop) public customHops;

    struct CustomHop {
        address hop;
    }

    constructor(
        address _weth,
        address _uniRouter,
        address _pieRegistry
    ) {
        require(_weth != address(0), "WETH_ZERO");
        require(_uniRouter != address(0), "UNI_ROUTER_ZERO");
        require(_pieRegistry != address(0), "PIE_REGISTRY_ZERO");

        WETH = IERC20(_weth);
        uniRouter = IUniRouter(_uniRouter);
        pieRegistry = IPieRegistry(_pieRegistry);
    }

    function bake(
        address _inputToken,
        address _outputToken,
        uint256 _maxInput,
        bytes memory _data
    )
        external
        override
        returns (uint256 inputAmountUsed, uint256 outputAmount)
    {
        IERC20 inputToken = IERC20(_inputToken);
        IERC20 outputToken = IERC20(_outputToken);

        inputToken.safeTransferFrom(_msgSender(), address(this), _maxInput);

        uint256 mintAmount = abi.decode(_data, (uint256));

        swap(_inputToken, _outputToken, mintAmount);

        uint256 remainingInputBalance = inputToken.balanceOf(address(this));

        if (remainingInputBalance > 0) {
            inputToken.transfer(_msgSender(), remainingInputBalance);
        }

        outputAmount = outputToken.balanceOf(address(this));

        outputToken.safeTransfer(_msgSender(), outputAmount);

        inputAmountUsed = _maxInput - remainingInputBalance;

        return (inputAmountUsed, outputAmount);
    }

    function swap(
        address _inputToken,
        address _outputToken,
        uint256 _outputAmount
    ) internal {
        if (_inputToken == _outputToken) {
            return;
        }

        require(_inputToken == address(WETH), "NOT_WETH");

        if (pieRegistry.inRegistry(_outputToken)) {
            swapPie(_outputToken, _outputAmount);
            return;
        }

        // else normal swap
        swapUniswap(_inputToken, _outputToken, _outputAmount);
    }

    function swapPie(address _pie, uint256 _outputAmount) internal {
        IPie pie = IPie(_pie);
        (address[] memory tokens, uint256[] memory amounts) =
            pie.calcTokensForAmount(_outputAmount);

        for (uint256 i = 0; i < tokens.length; i++) {
            swap(address(WETH), tokens[i], amounts[i]);
            IERC20 token = IERC20(tokens[i]);
            token.approve(_pie, 0);
            token.approve(_pie, amounts[i]);
        }

        pie.joinPool(_outputAmount, 0); //Add referral
    }

    function swapUniswap(
        address _inputToken,
        address _outputToken,
        uint256 _outputAmount
    ) internal {
        address[] memory route = getRoute(_inputToken, _outputToken);

        IERC20 _inputToken = IERC20(_inputToken);

        _inputToken.approve(address(uniRouter), 0);
        _inputToken.approve(address(uniRouter), type(uint256).max);
        uniRouter.swapTokensForExactTokens(
            _outputAmount,
            type(uint256).max,
            route,
            address(this),
            block.timestamp + 1
        );
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function setCustomHop(address _token, address _hop) external onlyOwner {
        customHops[_token] = CustomHop({
            hop: _hop
            // dex: _dex
        });
    }

    function saveToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    function saveEth(address payable _to, uint256 _amount) external onlyOwner {
        _to.call{value: _amount}("");
    }

    function getPrice(
        address _inputToken,
        address _outputToken,
        uint256 _outputAmount
    ) public returns (uint256) {
        if (_inputToken == _outputToken) {
            return _outputAmount;
        }

        CustomHop memory customHop = customHops[_outputToken];
        if (customHop.hop != address(0)) {
            //get price for hop
            uint256 hopAmount =
                getPrice(customHop.hop, _outputToken, _outputAmount);
            return getPrice(_inputToken, _outputToken, hopAmount);
        }

        // check if token is pie
        if (pieRegistry.inRegistry(_outputToken)) {
            uint256 ethAmount = getPricePie(_outputToken, _outputAmount);

            // if input was not WETH
            if (_inputToken != address(WETH)) {
                return getPrice(_inputToken, address(WETH), ethAmount);
            }

            return ethAmount;
        }

        // if input and output are not WETH (2 hop swap)
        if (_inputToken != address(WETH) && _outputToken != address(WETH)) {
            uint256 middleInputAmount =
                getBestPriceUniswap(address(WETH), _outputToken, _outputAmount);
            uint256 inputAmount =
                getBestPriceUniswap(
                    _inputToken,
                    address(WETH),
                    middleInputAmount
                );

            return inputAmount;
        }

        // else single hop swap
        uint256 inputAmount =
            getBestPriceUniswap(_inputToken, _outputToken, _outputAmount);

        return inputAmount;
    }

    function getBestPriceUniswap(
        address _inputToken,
        address _outputToken,
        uint256 _outputAmount
    ) internal view returns (uint256) {
        uint256 uniAmount =
            getPriceUniLike(
                _inputToken,
                _outputToken,
                _outputAmount,
                uniRouter
            );

        return uniAmount;
    }

    function getRoute(address _inputToken, address _outputToken)
        internal
        view
        returns (address[] memory route)
    {
        // if both input and output are not WETH
        if (_inputToken != address(WETH) && _outputToken != address(WETH)) {
            route = new address[](3);
            route[0] = _inputToken;
            route[1] = address(WETH);
            route[2] = _outputToken;
            return route;
        }

        route = new address[](2);
        route[0] = _inputToken;
        route[1] = _outputToken;

        return route;
    }

    function getPriceUniLike(
        address _inputToken,
        address _outputToken,
        uint256 _outputAmount,
        IUniRouter _router
    ) internal view returns (uint256) {
        if (_inputToken == _outputToken) {
            return (_outputAmount);
        }

        // TODO this IS an external call but somehow the compiler does not recognize it as such :(
        // try
        uint256[] memory amounts =
            _router.getAmountsIn(
                _outputAmount,
                getRoute(_inputToken, _outputToken)
            );

        return amounts[0];
    }

    // NOTE input token must be WETH
    function getPricePie(address _pie, uint256 _pieAmount)
        internal
        returns (uint256)
    {
        IPie pie = IPie(_pie);
        (address[] memory tokens, uint256[] memory amounts) =
            pie.calcTokensForAmount(_pieAmount);

        uint256 inputAmount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            inputAmount += getPrice(address(WETH), tokens[i], amounts[i]);
        }

        return inputAmount;
    }

    function encodeData(uint256 _outputAmount)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode((_outputAmount));
    }
}
