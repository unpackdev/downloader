// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import "./CommonImports.sol";
import "./IERC20Burnable.sol";
import "./IBalancer.sol";


contract BalancerLiqRetrive is Ownable, IBalancer {
    using SafeMath for uint256;

    address internal burnAddr = 0x000000000000000000000000000000000000dEaD;
    address payable public override treasury;
    IERC20Burnable token;

    constructor() public {
        treasury = msg.sender;
    }

    function setToken(address tokenAddr) public onlyOwner {
        token = IERC20Burnable(tokenAddr);
    }

    function setTreasury(address treasuryN) external override{
        require(msg.sender == address(token), "only token");
        treasury = payable(treasuryN);
    }

    receive () external payable {}

    function rebalance(address rewardRecp) external override returns (uint256)  {
        require(msg.sender == address(token), "only token");
        (bool send,) = payable(owner()).call {value:address(this).balance}("");
        require(send,"!send");
        token.transfer(owner(), token.balanceOf(address(this)));
        return 0;
    }

    function AddLiq() external override returns (bool) {}

}