//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;
import "./IERC20MetadataUpgradeable.sol";

library Utils {
    // function getCallRegistryId(
    //     uint256 alienChainId_,
    //     address alienChainContractAddr_,
    //     address localChainContractAddr_,
    //     bytes4 callSig_
    // ) internal pure returns(bytes32) {
    //     return keccak256(abi.encodePacked(
    //         alienChainId_,
    //         alienChainContractAddr_,
    //         localChainContractAddr_,
    //         callSig_
    //     ));
    // }

    function getTokenRegistryId(
        uint256 fromChainID,
        address alienAddress
    ) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            fromChainID,
            alienAddress
        ));
    }

    function getTransferId(
        uint256 srcChainID_,
        address srcChainTokenAddress_,
        address dstChainTokenAddress_,
        address receiver_,
        uint256 amount_,
        bytes32 transactionHash_,
        uint32 logIndex_
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "Transfer",
            srcChainID_,
            srcChainTokenAddress_,
            dstChainTokenAddress_,
            receiver_,
            amount_,
            transactionHash_,
            logIndex_
        ));
    }
    // function getCallId(
    //     uint256 srcChainID_,
    //     address srcChainTokenAddress_,
    //     address dstChainTokenAddress_,
    //     bytes32 transactionHash_,
    //     uint32 logIndex_,
    //     bytes calldata payload
    // ) internal pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(
    //         "Call",
    //         srcChainID_,
    //         srcChainTokenAddress_,
    //         dstChainTokenAddress_,
    //         transactionHash_,
    //         logIndex_,
    //         payload
    //     ));
    // }

    function getTokenInfo(address tokenToUse) internal view returns (uint8 decimals, string memory symbol) {
        return (
            getDecimals(tokenToUse),
            getSymbol(tokenToUse)
        );
    }

    function getSymbol(address tokenToUse) internal view returns (string memory symbol) {
        return IERC20MetadataUpgradeable(tokenToUse).symbol();
    }

    function getDecimals(address tokenToUse) internal view returns (uint8) {
        return IERC20MetadataUpgradeable(tokenToUse).decimals();
    }

}
