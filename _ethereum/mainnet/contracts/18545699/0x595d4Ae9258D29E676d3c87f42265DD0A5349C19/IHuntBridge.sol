// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Types.sol";
import "./IGlobalNftDeployer.sol";

/**huntnft
 * @title the interface hunt main bridge which is used to receive msg from sub bridge and send withdraw method to sub bridge
 */
interface IHuntBridge is IGlobalNftDeployer {
    //********************EVENT*******************************//
    event NftTransfer(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient
    );
    event NftDepositFinalized(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient,
        bytes extraData,
        uint64 nonce
    );

    //withdraw initialized event
    event NftWithdrawInitialized(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient,
        bytes extraData,
        uint64 nonce
    );

    // dao event
    event SubBridgeInfoChanged(uint64[] _originChains, address[] _addrs);
    event Paused(bool);

    //********************FUNCTION*******************************//

    /**
     * @dev owener of nft withdraw nft to recipient located at it's src network
     * @param originChain origin chain id of nft
     * @param addr nft address
     * @param tokenId tokenId
     * @param recipient recipient address of nft origin network
     * @param refund refund account who receive the lz refund
     */
    function withdraw(
        uint64 originChain,
        address addr,
        uint256 tokenId,
        address recipient,
        address payable refund
    ) external payable;

    /**
     * @dev set subbridge info lz chainId => subBridge
     * @param _originChains a slice of various origin chainId
     * @param _addrs a slice of subBridge of specific lz chainId
     * @notice only owner
     */
    function setSubBridgeInfo(uint64[] calldata _originChains, address[] calldata _addrs) external;

    /// @return get sub bridge address by lz id
    function getSubBridgeByLzId(uint16 lzId) external view returns (address);

    /// @return get layerzero id by chainId
    function getLzIdByChainId(uint64 chainId) external view returns (uint16);

    /// @return estimate fee for withdraw nft back to origin chain
    function estimateFees(uint64 destChainId) external view returns (uint256);
}
