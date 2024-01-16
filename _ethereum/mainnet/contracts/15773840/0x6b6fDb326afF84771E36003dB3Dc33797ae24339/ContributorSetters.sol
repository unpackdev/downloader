// contracts/Setters.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./ContributorState.sol";
import "./Context.sol";

contract ContributorSetters is ContributorState, Context {
    function setInitialized(address implementatiom) internal {
        _state.initializedImplementations[implementatiom] = true;
    }

    function setOwner(address owner_) internal {
        _state.owner = owner_;
    }

    function setChainId(uint16 chainId) internal {
        _state.provider.chainId = chainId;
    }

    function setConductorChainId(uint16 chainId) internal {
        _state.provider.conductorChainId = chainId;
    }

    function setConductorContract(bytes32 conductorContract) internal {
        _state.provider.conductorContract = conductorContract;
    }

    function setWormhole(address wh) internal {
        _state.provider.wormhole = payable(wh);
    }

    function setTokenBridge(address tb) internal {
        _state.provider.tokenBridge = payable(tb);
    }

    function setConsistencyLevel(uint8 level) internal {
        _state.consistencyLevel = level;
    }

    function setSale(uint256 saleId, ContributorStructs.Sale memory sale) internal {
        _state.sales[saleId] = sale;
    }

    function setSaleContribution(uint256 saleId, address contributor, uint256 tokenIndex, uint256 contribution) internal {
        _state.contributions[saleId][tokenIndex][contributor] += contribution;
        _state.totalContributions[saleId][tokenIndex] += contribution;
    }

    function setSaleSealed(uint256 saleId) internal {
        _state.sales[saleId].isSealed = true;
    }

    function setSaleAborted(uint256 saleId) internal {
        _state.sales[saleId].isAborted = true;
    }

    function setRefundClaimed(uint256 saleId, uint256 tokenIndex, address contributor) internal {
        _state.refundIsClaimed[saleId][tokenIndex][contributor] = true;
    }

    function setAllocationClaimed(uint256 saleId, uint256 tokenIndex, address contributor) internal {
        _state.allocationIsClaimed[saleId][tokenIndex][contributor] = true;
    }

    function setExcessContributionClaimed(uint256 saleId, uint256 tokenIndex, address contributor) internal {
        _state.excessContributionIsClaimed[saleId][tokenIndex][contributor] = true;
    }

    function setSaleAllocation(uint256 saleId, uint256 tokenIndex, uint256 allocation) internal {
        _state.sales[saleId].allocations[tokenIndex] = allocation;
    }

    function setExcessContribution(uint256 saleId, uint256 tokenIndex, uint256 excessContribution) internal {
        _state.sales[saleId].excessContributions[tokenIndex] = excessContribution;
    }
}