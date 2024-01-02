// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IFeeReceiver.sol";
import "./IPrismaFeeDistributor.sol";
import "./IERC20.sol";


//claim prisma platform fees
//can be replaced if tokens change
contract PlatformFeeClaimer is IFeeReceiver {

    address public immutable distributor;
    address public immutable veProxy;
    address public immutable operator;
    address public immutable mkusd;

    constructor(address _distributor, address _veProxy, address _operator, address _mkusd) {
        distributor = _distributor;
        veProxy = _veProxy;
        operator = _operator;
        mkusd = _mkusd;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "!op");
        _;
    }

    function processFees() external onlyOperator{
        //claim latest
        address[] memory tokens = new address[](1);
        tokens[0] = mkusd;
        IPrismaFeeDistributor(distributor).claim(veProxy, msg.sender, tokens);
    }

}