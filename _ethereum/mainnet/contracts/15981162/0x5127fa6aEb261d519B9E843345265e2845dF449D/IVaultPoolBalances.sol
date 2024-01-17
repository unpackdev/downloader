pragma experimental ABIEncoderV2;

pragma solidity ^0.7.0;
import "./IERC20.sol";

interface IVaultPoolBalances {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}
