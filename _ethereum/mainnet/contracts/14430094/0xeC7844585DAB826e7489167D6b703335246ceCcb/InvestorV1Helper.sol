// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";

import "./IInvestorV1Factory.sol";
import "./IInvestorV1Pool.sol";


contract InvestorV1Helper {
    struct PoolInfo {
        address pooladdr;
        string  name;
        string status;
        uint256 capacity;
        uint256 funded;
        uint256 exited;
        uint256 staked;
        uint256 oraclePrice;
        uint24 apy;
        uint24 fee;
        uint256 mystake;
        uint256 myfund;
        uint256 myrevenue;
        bool claimed;
    }

    address public factory;
    address public owner;

    address public constant HSF = 0xbA6B0dbb2bA8dAA8F5D6817946393Aef8D3A4487;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(address _factory) {
        factory = _factory;
        owner = msg.sender;
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner, "InvestorV1Helper: not owner");
        owner = _owner;
    }

    function setFactory(address _factory) public {
        require(msg.sender == owner, "InvestorV1Helper: not owner");
        factory = _factory;
    }

    function getAllPools(address _account) public view returns (PoolInfo[] memory) {
        uint256 poolLen = IInvestorV1Factory(factory).pools();
        PoolInfo[] memory pl = new PoolInfo[](poolLen);
        for(uint i=0; i<poolLen; i++) {
            address targetPool = IInvestorV1Factory(factory).poolList(i);
            pl[i] = PoolInfo({
                pooladdr: targetPool,
                name: IInvestorV1Pool(targetPool).name(),
                status: IInvestorV1Pool(targetPool).getPoolState(),
                capacity: IInvestorV1Pool(targetPool).capacity(),
                funded: IInvestorV1Pool(targetPool).funded(),
                exited: IInvestorV1Pool(targetPool).exited(),
                staked: IInvestorV1Pool(targetPool).restaked(),
                oraclePrice: IInvestorV1Pool(targetPool).oraclePrice(),
                apy: IInvestorV1Pool(targetPool).interestRate(),
                fee: IInvestorV1Pool(targetPool).fee(),
                mystake: IInvestorV1Pool(targetPool).restakeAmt(_account),
                myfund: IInvestorV1Pool(targetPool).pooledAmt(_account),
                myrevenue: IInvestorV1Pool(targetPool).expectedRevenue(_account),
                claimed:  IInvestorV1Pool(targetPool).claimed(_account)
            });
        }
        return pl;
    }
}