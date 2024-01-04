//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

contract Fund {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address[] public receivers;
    uint256[] public feeBasisPoints;

    address public gov;
    address public xvix;

    constructor(address _xvix) public {
        xvix = _xvix;
        gov = msg.sender;
    }

    function setReceivers(address[] memory _receivers, uint256[] memory _feeBasisPoints) public {
        require(msg.sender == gov, "Fund: forbidden");
        _validateInput(_receivers, _feeBasisPoints);
        receivers = _receivers;
        feeBasisPoints = _feeBasisPoints;
    }

    function withdraw(address _token) public {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 feePoints = feeBasisPoints[i];
            uint256 amount = balance.mul(feePoints).div(BASIS_POINTS_DIVISOR);
            IERC20(_token).transfer(receivers[i], amount);
        }
    }

    function withdrawXVIX() public {
        address token = xvix;
        uint256 balance = IERC20(token).balanceOf(address(this));
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 feePoints = feeBasisPoints[i];
            uint256 amount = balance.mul(feePoints).div(BASIS_POINTS_DIVISOR);
            IERC20(token).transfer(receivers[i], amount);
        }
    }

    function _validateInput(address[] memory _receivers, uint256[] memory _feeBasisPoints) private pure {
        require(_receivers.length == _feeBasisPoints.length, "Fund: invalid input");
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _feeBasisPoints.length; i++) {
            totalBasisPoints = totalBasisPoints.add(_feeBasisPoints[i]);
        }
        require(totalBasisPoints == BASIS_POINTS_DIVISOR, "Fund: invalid input");
    }
}
