// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";

interface ERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function factory() external view returns (address);

    function swap(
        uint256 amount0,
        uint256 amount1,
        address sender,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

address constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract Arby is Ownable {
    event ValueReceived(address user, uint256 amount);
    event Withdrawal(address token, uint256 amount);
    event ConstructorDeposit(address token, uint256 amount);
    event PayloadData(Payload payload);

    struct Payload {
        address target;
        bytes data;
        uint256 value;
    }

    mapping(address => bool) public factoryAddresses;
    ERC20 weth;

    constructor() payable {
        factoryAddresses[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f] = true;
        factoryAddresses[0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac] = true;

        weth = ERC20(WETH_ADDR);
        if (msg.value > 0) {
            emit ConstructorDeposit(msg.sender, msg.value);
            weth.deposit{value: msg.value}();
        }
    }

    function drainERC20Account(address tokenAddress) public onlyOwner {
        if (IERC20(tokenAddress).balanceOf(address(this)) > 1) {
            emit Withdrawal(
                tokenAddress,
                IERC20(tokenAddress).balanceOf(address(this)) - 1
            );

            IERC20(tokenAddress).transfer(
                owner(),
                IERC20(tokenAddress).balanceOf(address(this)) - 1
            );
        }
    }

    function withdrawETH(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    function setFactoryFlag(address _factoryAddress, bool _flag)
        external
        onlyOwner
    {
        factoryAddresses[_factoryAddress] = _flag;
    }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    fallback() external {
        bytes4 func_selector = bytes4(msg.data[0:4]);
        bool executeAllPayloads = false;
        bool returnOnFirstFailure = false;

        if (
            func_selector ==
            bytes4(
                abi.encodeWithSignature(
                    "uniswapV2Call(address,uint256,uint256,bytes)"
                )
            )
        ) {
            address lp_factory = IUniswapV2Pair(msg.sender).factory();

            require(factoryAddresses[lp_factory] == true, "Unapproved factory");

            address token0_address = IUniswapV2Pair(msg.sender).token0();
            address token1_address = IUniswapV2Pair(msg.sender).token1();

            address lp_address = IUniswapV2Factory(lp_factory).getPair(
                token0_address,
                token1_address
            );

            require(msg.sender == lp_address, "Unauthorized LP");

            address sender;
            uint256 amount0Out = 0;
            uint256 amount1Out = 0;
            bytes memory payloadBytes;
            Payload[] memory payloads;

            (sender, amount0Out, amount1Out, payloadBytes) = abi.decode(
                msg.data[4:],
                (address, uint256, uint256, bytes)
            );

            require(sender == address(this), "Must me owner!");

            (payloads) = abi.decode(payloadBytes, (Payload[]));

            this._deliverPayloads(
                payloads,
                returnOnFirstFailure,
                executeAllPayloads
            );
        } else {
            revert();
        }
    }

    function _deliverPayloads(
        Payload[] memory _payloads,
        bool _returnOnFirstFailure,
        bool _executeAllPayloads
    ) external payable {
        if (_returnOnFirstFailure) {
            require(!_executeAllPayloads, "Conflicting revert options");
        }

        if (_executeAllPayloads) {
            require(!_returnOnFirstFailure, "Conflicting revert options");
        }

        uint256 totalValue = 0;

        for (uint256 i = 0; i < _payloads.length; i++) {
            totalValue += _payloads[i].value;
        }
        require(
            totalValue <= msg.value + address(this).balance,
            "Insufficient value"
        );

        if ((!_executeAllPayloads) && (!_returnOnFirstFailure)) {
            for (uint256 i = 0; i < _payloads.length; i++) {
                emit PayloadData(_payloads[i]);
                (bool success, bytes memory data) = _payloads[i].target.call(
                    _payloads[i].data
                );
            }
        } else if (_returnOnFirstFailure) {
            for (uint256 i = 0; i < _payloads.length; i++) {
                (bool success, bytes memory data) = _payloads[i].target.call(
                    _payloads[i].data
                );

                if (!success) break;
            }
        } else if (_executeAllPayloads) {
            for (uint256 i = 0; i < _payloads.length; i++) {
                (bool success, bytes memory data) = _payloads[i].target.call(
                    _payloads[i].data
                );
            }
        }
    }

    function _payBribe(uint256 _amount) internal {
        uint256 wethBalance;
        if (address(this).balance >= _amount) {
            (bool sent, bytes memory data) = (block.coinbase).call{
                value: _amount
            }("");
        } else {
            wethBalance = IERC20(WETH_ADDR).balanceOf(address(this));
            require(
                _amount <= address(this).balance + wethBalance,
                "Bribe exceeds balance"
            );

            weth.withdraw(_amount - address(this).balance);
            (bool sent, bytes memory data) = (block.coinbase).call{
                value: _amount
            }("");
        }
    }

    function executePackedPayload(
        address _target,
        bytes memory _payload,
        uint256 _bribeAmount
    ) external onlyOwner {
        _target.call(_payload);
        if (_bribeAmount > 0) {
            _payBribe(_bribeAmount);
        }
    }

    function executePayloads(
        Payload[] memory _payloads,
        uint256 _bribeAmount,
        bool _returnOnFirstFailure,
        bool _executeAllPayloads
    ) external onlyOwner {
        this._deliverPayloads(
            _payloads,
            _returnOnFirstFailure,
            _executeAllPayloads
        );

        if (_bribeAmount > 0) _payBribe(_bribeAmount);
    }
}
