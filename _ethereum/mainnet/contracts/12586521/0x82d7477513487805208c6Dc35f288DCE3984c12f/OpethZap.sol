// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IOpeth.sol";

contract OpethZap {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable weth;
    IERC20 public immutable usdc;
    Uni public immutable uni;
    IOpeth public immutable opeth;
    address payable public immutable exchange;

    address[] public path;

    constructor(
        IERC20 _weth,
        IERC20 _usdc,
        Uni _uni,
        IOpeth _opeth,
        address payable _exchange
    ) public {
        weth = _weth;
        usdc = _usdc;
        uni = _uni;
        opeth = _opeth;
        exchange = _exchange;

        // ETH -> USDC -> oToken
        path = new address[](2);
        path[0] = address(_weth);
        path[1] = address(_usdc);

        _usdc.safeApprove(_exchange, uint(-1));
        _weth.safeApprove(address(_opeth), uint(-1));
    }

    function mintWithEth(
        address oToken,
        uint _opeth,
        uint _oTokenPayment,
        uint _maxPayment,
        uint _0xFee,
        bytes calldata _0xSwapData
    ) external payable {
        WETH9(address(weth)).deposit{value: _opeth.mul(1e10)}();
        IERC20(oToken).safeApprove(address(opeth), _opeth);
        _mint(oToken, _opeth, _oTokenPayment, _maxPayment, _0xFee, _0xSwapData);
    }

    function mint(
        address oToken,
        uint _opeth,
        uint _oTokenPayment,
        uint _maxPayment,
        uint _0xFee,
        bytes calldata _0xSwapData
    ) external payable {
        (address underlying,,uint _underlying) = opeth.getOpethDetails(oToken, _opeth);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _underlying);
        if (underlying != address(weth)) {
            IERC20(underlying).safeApprove(address(opeth), _underlying);
        }
        IERC20(oToken).safeApprove(address(opeth), _opeth);
        _mint(oToken, _opeth, _oTokenPayment, _maxPayment, _0xFee, _0xSwapData);
    }

    /**
    * @param oToken opyn put option
    * @param _oTokenPayment USDC required for purchasing oTokens
    * @param _maxPayment in ETH for purchasing USDC; caps slippage
    * @param _0xFee 0x protocol fee. Any extra is refunded
    * @param _0xSwapData 0x swap encoded data
    */
    function _mint(
        address oToken,
        uint _opeth,
        uint _oTokenPayment,
        uint _maxPayment,
        uint _0xFee,
        bytes calldata _0xSwapData
    ) internal {
        // Swap ETH for USDC (for purchasing oToken)
        Uni(uni).swapETHForExactTokens{value: _maxPayment}(
            _oTokenPayment,
            path,
            address(this),
            now
        );

        // Purchase oToken
        (bool success,) = exchange.call{value: _0xFee}(_0xSwapData);
        require(success, "SWAP_CALL_FAILED");

        opeth.mintFor(msg.sender, oToken, _opeth);

        // refund dust eth, if any
        safeTransferETH(msg.sender, address(this).balance);
    }

    function safeTransferETH(address to, uint value) internal {
        if (value > 0) {
            (bool success,) = to.call{value:value}(new bytes(0));
            require(success, 'ETH_TRANSFER_FAILED');
        }
    }

    receive() external payable {
        require(
            msg.sender == address(uni) || msg.sender == exchange,
            "Cannot receive ETH"
        );
    }

    // Cannot receive ETH with calldata that doesnt match any function
    fallback() external payable {
        revert("Cannot receive ETH");
    }
}

interface Uni {
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface WETH9 is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}
