// commit 2eaf119cda8db53ead57f342a8967cf792bc365a
pragma solidity ^0.8.19;

import "BaseACL.sol";

contract LybraV2FarmAuthorizer is BaseACL {
    bytes32 public constant NAME = "LybraV2FarmAuthorizer";
    uint256 public constant VERSION = 1;

    //for eUSD mining
    address public constant eUSDMiningIncentive = 0x0B2659734121FeB636534213a159AC91691eDbde;

    //for dlp
    address public constant UniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant LBR = 0xed1167b6Dc64E8a366DB86F2E952A482D0981ebd;

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](2);
        _contracts[0] = eUSDMiningIncentive;
        _contracts[1] = UniswapV2Router;
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external view onlyContract(UniswapV2Router) {
        require(token == LBR, "token not allowed");
        _checkRecipient(to);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external onlyContract(UniswapV2Router) {
        require(token == LBR, "token not allowed");
        _checkRecipient(to);
    }

    function getReward() external view onlyContract(eUSDMiningIncentive) {}
}
