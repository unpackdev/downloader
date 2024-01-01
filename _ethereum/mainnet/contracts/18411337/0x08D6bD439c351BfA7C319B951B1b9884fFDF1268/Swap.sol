// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ICurveRouter.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";


contract Swap is ReentrancyGuardUpgradeable {
    address public router = address(0xF0d4c12A5768D806021F80a262B4d39d26C58b8D);
    address public admin;
    address public mainContract;
    address public mainToken = address(0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5);

    modifier onlyAdmin {
        require(msg.sender == admin, "only Admin can do that!");
        _;
    }
    constructor() {
        admin = msg.sender;
    }
    function setRouter(address _router) public onlyAdmin {
        router = _router;
    }

    function setMainContract(address _contract) public onlyAdmin {
        require(msg.sender == admin, "only Admin can set");
        mainContract = _contract;
    }

    function setMainToken(address _token) public onlyAdmin {
        mainContract = _token;
    }

    function grandSwap(
        address[11] memory _route,
        uint256[5][5] calldata i,
        address[5] memory pools
    ) public {
        IERC20 Token = IERC20(_route[0]);
        uint256 balance = Token.balanceOf(address(this));
        Token.approve(router, balance);
        ICurveRouter(router).exchange(_route, i, balance, 0, pools);
        IERC20 Token2 = IERC20(mainToken);
        uint256 balance2 = Token2.balanceOf(address(this));
        Token2.transfer(mainContract, balance2);
    }

    function withdraw_admin(
        address _token,
        uint256 _amount
    ) external nonReentrant onlyAdmin {
        IERC20(_token).transfer(admin, _amount);
    }

}