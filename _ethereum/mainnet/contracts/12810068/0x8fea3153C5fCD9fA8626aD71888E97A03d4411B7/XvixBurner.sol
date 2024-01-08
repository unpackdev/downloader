//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./IFloor.sol";
import "./IWETH.sol";
import "./IXlgeDistributor.sol";

contract XvixBurner is ReentrancyGuard {
    using SafeMath for uint256;

    address public weth;
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "XvixBurner: forbidden");
        _;
    }

    constructor(address _weth) public {
        weth = _weth;
        admin = msg.sender;
    }

    receive() external payable {}

    function approve(address _token, address _spender, uint256 _amount) external nonReentrant onlyAdmin {
        IERC20(_token).approve(_spender, _amount);
    }

    function send(address _receiver, uint256 _amount) external nonReentrant onlyAdmin {
        (bool success,) = _receiver.call{value: _amount}("");
        require(success, "XvixBurner: transfer to receiver failed");
    }

    function burnXvix(
        address _migrator,
        address _xvix,
        address _floor,
        uint256 _transferAmount,
        uint256 _repetitions
    ) external nonReentrant onlyAdmin {
        IERC20(_xvix).transferFrom(_migrator, address(this), _transferAmount);
        uint256 balance = IERC20(_xvix).balanceOf(address(this));
        uint256 batchAmount = balance.div(_repetitions);

        for (uint256 i = 0; i < _repetitions; i++) {
            IFloor(_floor).refund(address(this), batchAmount);
        }

        uint256 amountETH = address(this).balance;
        IWETH(weth).deposit{value: amountETH}();

        IERC20(weth).transfer(_migrator, amountETH);
    }

    function burnXlge(
        address _migrator,
        address _xlge,
        address _distributor,
        uint256 _amount
    ) external nonReentrant onlyAdmin {
        IERC20(_xlge).transferFrom(_migrator, address(this), _amount);
        IXlgeDistributor(_distributor).removeLiquidityETH(
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;
        IWETH(weth).deposit{value: amountETH}();

        IERC20(weth).transfer(_migrator, amountETH);
    }
}
