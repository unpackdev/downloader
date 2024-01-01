// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import "./VaultFacet.sol";

contract VaultFacetExtension {
    event Distribute(string indexed roleId, string poolId, VaultLib.PaymentInfo[] paymentInfo);
    event Exit(string indexed roleId, string poolId, uint256 amount);
    event Fee(string indexed poolId, uint256 amount);
    
    struct DistributeBatchArgs {
        string roleId;
        string poolId;
        VaultLib.PaymentInfo[] paymentInfo;
    }

    struct ExitBatchArgs {
        string roleId;
        string poolId;
        uint256 amount;
    }

    struct FeeBatchArgs {
        string poolId;
        uint256 amount;
    }

    function atomicDistribution(
        DistributeBatchArgs[] calldata _distribute,
        ExitBatchArgs[] calldata _exit,
        FeeBatchArgs[] calldata _fee
    ) external {
        for(uint i; i < _distribute.length; i++) {
            VaultLib.distribute(_distribute[i].roleId, _distribute[i].poolId, _distribute[i].paymentInfo);
            emit Distribute(_distribute[i].roleId, _distribute[i].poolId, _distribute[i].paymentInfo);
        }
        for(uint j; j < _exit.length; j++) {
            VaultLib.processExit(_exit[j].roleId, _exit[j].poolId, _exit[j].amount);
            emit Exit(_exit[j].roleId, _exit[j].poolId, _exit[j].amount);
        }
        for(uint k; k < _fee.length; k++) {
            VaultLib.collectFee(_fee[k].poolId, _fee[k].amount);
            emit Fee(_fee[k].poolId, _fee[k].amount);
        }
    }
}