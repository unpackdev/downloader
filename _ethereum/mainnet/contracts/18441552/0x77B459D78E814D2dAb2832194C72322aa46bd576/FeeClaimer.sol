// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IFeeReceiver.sol";
import "./IERC20.sol";

interface IProxyVault{
    function withdrawTo(address _asset, uint256 _amount, address _to) external;

    function withdrawLocked(uint256 _amount) external;
}

//claim fees from the proxyvault which is holding expired and/or locked tokens
contract FeeClaimer is IFeeReceiver {

    address public immutable prisma;
    address public immutable vault;
    address public immutable operator;

    constructor(address _vault, address _prisma, address _operator) {
        vault = _vault;
        prisma = _prisma;
        operator = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!op");
        _;
    }

    function processFees() external onlyOperator{
        //withdraw locked
        IProxyVault(vault).withdrawLocked(type(uint256).max);

        //get balance
        uint256 tokenbalance = IERC20(prisma).balanceOf(vault);

        if(tokenbalance > 0){
            //pull to operator
            IProxyVault(vault).withdrawTo(prisma, tokenbalance, operator);
        }
    }

}