//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./UFixed18.sol";
import "./Token18.sol";
import "./Token6.sol";
import "./Batcher.sol";

contract WrapOnlyBatcher is Batcher {
    using UFixed18Lib for UFixed18;
    using Token18Lib for Token18;
    using Token6Lib for Token6;

    constructor(IEmptySetReserve reserve, Token18 dsu, Token6 usdc)
    Batcher(reserve, dsu, usdc)
    { }

    function _unwrap(UFixed18 amount, address to) override internal {
        revert BatcherNotImplementedError();
    }

    function _rebalance(UFixed18 usdcBalance, UFixed18 dsuBalance) override internal {
        if (usdcBalance.isZero()) return;

        RESERVE.mint(usdcBalance);
    }
}
