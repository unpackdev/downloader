//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

contract Fund {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FEE_SPLIT_A = 6700; // 67%
    uint256 public constant FEE_SPLIT_B = 3000; // 30%

    address public receiverA;
    address public receiverB;
    address public receiverC;

    constructor(address _receiverA, address _receiverB, address _receiverC) public {
        receiverA = _receiverA;
        receiverB = _receiverB;
        receiverC = _receiverC;
    }

    function setReceiverA(address _receiverA) public {
        require(msg.sender == receiverA, "Fund: forbidden");
        receiverA = _receiverA;
    }

    function setReceiverB(address _receiverB) public {
        require(msg.sender == receiverB, "Fund: forbidden");
        receiverB = _receiverB;
    }

    function setReceiverC(address _receiverC) public {
        require(msg.sender == receiverC, "Fund: forbidden");
        receiverC = _receiverC;
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == receiverA || msg.sender == receiverB || msg.sender == receiverC, "Fund: forbidden");
        uint256 amountA = _amount.mul(FEE_SPLIT_A).div(BASIS_POINTS_DIVISOR);
        uint256 amountB = _amount.mul(FEE_SPLIT_B).div(BASIS_POINTS_DIVISOR);
        uint256 amountC = _amount.sub(amountA).sub(amountB);
        IERC20(_token).transfer(receiverA, amountA);
        IERC20(_token).transfer(receiverB, amountB);
        IERC20(_token).transfer(receiverC, amountC);
    }
}
