// SPDX-FileCopyrightText: 2021 Tenderize <info@tenderize.me>

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Resolver.sol";

import "./IGraph.sol";
import "./IMatic.sol";
import "./IAudius.sol";

contract MainnetResolver is Resolver {
    // Matic contstants
    uint256 constant EXCHANGE_RATE_PRECISION = 100; // For Validator ID < 8
    uint256 constant EXCHANGE_RATE_PRECISION_HIGH = 10**29; // For Validator ID >= 8

    bytes32 constant GRAPH = 0xf33f789e3939d11e1b15e7342d3161b39f98259904e8ebdc1da58ce84a17f509; // "Graph"
    bytes32 constant AUDIUS = 0xbf92ffa8d618cd090d960a5b3cb58c78332d37eedf59819530a17714aa2dc74c; // "Audius"
    bytes32 constant MATIC = 0xe0323cd44c3bff8ae1a6f6bb89d41ecaa34bcb9eab6e20fe02a77f37f7344b83; // "Matic"

    function rebaseChecker(address _tenderizer)
        external 
        override
        view
    returns (bool canExec, bytes memory execPayload){
        execPayload = abi.encodeWithSelector(IResolver.claimRewardsExecutor.selector, _tenderizer);
        Protocol storage protocol = protocols[_tenderizer];

        // Return true if pending deposits to stake
        canExec = _depositChecker(_tenderizer);
        if(canExec){
            return (canExec, execPayload);
        }

        if(protocol.lastClaim + protocol.rebaseInterval > block.timestamp) {
            return (canExec, execPayload);
        }

        ITenderizer tenderizer = ITenderizer(_tenderizer);
        uint256 currentPrinciple = tenderizer.totalStakedTokens();
        uint256 stake;

        if (keccak256(bytes(protocol.name)) == GRAPH) {
            // Graph
            address node = tenderizer.node();
            IGraph graph = IGraph(protocol.stakingContract);
            IGraph.Delegation memory delegation = graph.getDelegation(node, _tenderizer);
            IGraph.DelegationPool memory delPool = graph.delegationPools(node);

            uint256 delShares = delegation.shares;
            uint256 totalShares = delPool.shares;
            uint256 totalTokens = delPool.tokens;

            stake = (delShares * totalTokens) / totalShares;
        } else if (keccak256(bytes(protocol.name)) == AUDIUS) {
            // Audius
            IAudius audius = IAudius(protocol.stakingContract);
            stake = audius.getTotalDelegatorStake(_tenderizer);
        } else if (keccak256(bytes(protocol.name)) == MATIC) {
            // Matic
            IMatic matic = IMatic(protocol.stakingContract);
            uint256 shares = matic.balanceOf(_tenderizer);
            stake = (shares * _getExchangeRate(matic)) / _getExchangeRatePrecision(matic);
        }

        if (stake > currentPrinciple + protocol.rebaseThreshold){
            canExec = true;
        }
    }

    // Matic internal functions
    function _getExchangeRatePrecision(IMatic _matic) internal view returns (uint256) {
        return _matic.validatorId() < 8 ? EXCHANGE_RATE_PRECISION : EXCHANGE_RATE_PRECISION_HIGH;
    }

    function _getExchangeRate(IMatic _matic) internal view returns (uint256) {
        uint256 rate = _matic.exchangeRate();
        return rate == 0 ? 1 : rate;
    }
}
