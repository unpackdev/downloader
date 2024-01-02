// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibAsset.sol";
import "./LibUtil.sol";
import "./GenericErrors.sol";
import "./IERC20.sol";
import "./IAdapter.sol";
import "./LibSwap.sol";

library LibQuote {
    bytes32 internal constant QUOTER_STORAGE_POSITION = keccak256("quoter.storage.position");

    struct QuoterStorage {
        mapping (address => address) quoterList;
    }

    function _getStorage() internal pure returns (QuoterStorage storage qs) {
        bytes32 position = QUOTER_STORAGE_POSITION;
        assembly {
            qs.slot := position
        }
    } 

    function addQuoter(address _router, address _quoter) internal {
        QuoterStorage storage qs = _getStorage();

        qs.quoterList[_router] = _quoter;
    }

    function removeQuoter(address _router) internal {
        QuoterStorage storage qs = _getStorage();

        qs.quoterList[_router] = address(0);
    }

    function getQuoter(address _router) internal view returns (address) {
        return _getStorage().quoterList[_router];
    }

    function quote(uint256 _fromAmount, LibSwap.SwapData calldata _swap, address _weth) internal returns (uint256 receievedAmount) {
        if (_fromAmount == 0) revert NoSwapFromZeroBalance();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swap.adapter.delegatecall(
            abi.encodeWithSelector(
                IAdapter.quote.selector,
                LibAsset.isNativeAsset(_swap.fromToken) ? _weth : _swap.fromToken,
                address(0),
                _fromAmount,
                _swap.route
            )
        );
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }
        (receievedAmount) = abi.decode(res,(uint256));
        return receievedAmount;
    }
}
