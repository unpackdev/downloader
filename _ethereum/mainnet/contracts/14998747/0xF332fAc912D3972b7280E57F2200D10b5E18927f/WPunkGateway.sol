// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IPool.sol";
import "./ReserveConfiguration.sol";
import "./UserConfiguration.sol";
import "./DataTypes.sol";
import "./DataTypesHelper.sol";

// ERC721 imports
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IPunks.sol";
import "./IWrappedPunks.sol";
import "./IWPunkGateway.sol";
import "./INToken.sol";

contract WPunkGateway is IWPunkGateway, IERC721Receiver, Ownable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IPunks internal immutable Punk;
    IWrappedPunks internal immutable WPunk;
    IPool internal immutable Pool;
    address public proxy;

    /**
     * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
     * @param punk Address of the Punk contract
     * @param wpunk Address of the Wrapped Punk contract
     * @param owner Address of the owner of this contract
     * @param pool Address of the proxy pool of this contract
     **/
    constructor(
        address punk,
        address wpunk,
        address owner,
        address pool
    ) {
        Punk = IPunks(punk);
        WPunk = IWrappedPunks(wpunk);
        transferOwnership(owner);

        // create new WPunk Proxy for PunkGateway contract
        WPunk.registerProxy();
        // proxy of PunkGateway contract is the new Proxy created above
        proxy = WPunk.proxyInfo(address(this));

        Pool = IPool(pool);
        WPunk.setApprovalForAll(pool, true);
    }

    /**
     * @dev supplies (deposits) WPunk into the reserve, using native Punk. A corresponding amount of the overlying asset (xTokens)
     * is minted.
     * @param pool address of the targeted underlying pool
     * @param punkIndexes punkIndexes to supply to gateway
     * @param onBehalfOf address of the user who will receive the xTokens representing the supply
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function supplyPunk(
        address pool,
        DataTypes.ERC721SupplyParams[] calldata punkIndexes,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            Punk.buyPunk(punkIndexes[i].tokenId);
            Punk.transferPunk(proxy, punkIndexes[i].tokenId);
            WPunk.mint(punkIndexes[i].tokenId);
        }

        Pool.supplyERC721(
            address(WPunk),
            punkIndexes,
            onBehalfOf,
            referralCode
        );
    }

    /**
     * @dev withdraws the WPUNK _reserves of msg.sender.
     * @param pool address of the targeted underlying pool
     * @param punkIndexes indexes of nWPunks to withdraw and receive native WPunk
     * @param to address of the user who will receive native Punks
     */
    function withdrawPunk(
        address pool,
        uint256[] calldata punkIndexes,
        address to
    ) external {
        INToken nWPunk = INToken(
            Pool.getReserveData(address(WPunk)).xTokenAddress
        );
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            nWPunk.safeTransferFrom(msg.sender, address(this), punkIndexes[i]);
        }
        Pool.withdrawERC721(address(WPunk), punkIndexes, address(this));
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            WPunk.burn(punkIndexes[i]);
            Punk.transferPunk(to, punkIndexes[i]);
        }
    }

    // // gives app permission to withdraw n token
    // // permitV, permitR, permitS. passes signature parameters
    // /**
    //  * @dev withdraws the WPUNK _reserves of msg.sender.
    //  * @param pool address of the targeted underlying pool
    //  * @param punkIndexes punkIndexes of nWPunks to withdraw and receive native WPunk
    //  * @param to address of the user who will receive native Punks
    //  * @param deadline validity deadline of permit and so depositWithPermit signature
    //  * @param permitV V parameter of ERC712 permit sig
    //  * @param permitR R parameter of ERC712 permit sig
    //  * @param permitS S parameter of ERC712 permit sig
    //  */
    // function withdrawPunkWithPermit(
    //     address pool,
    //     uint256[] calldata punkIndexes,
    //     address to,
    //     uint256 deadline,
    //     uint8 permitV,
    //     bytes32 permitR,
    //     bytes32 permitS
    // ) external override {
    //     INToken nWPunk = INToken(
    //         Pool.getReserveData(address(WPunk)).xTokenAddress
    //     );

    //     for (uint256 i = 0; i < punkIndexes.length; i++) {
    //         nWPunk.permit(
    //             msg.sender,
    //             address(this),
    //             punkIndexes[i],
    //             deadline,
    //             permitV,
    //             permitR,
    //             permitS
    //         );
    //         nWPunk.safeTransferFrom(msg.sender, address(this), punkIndexes[i]);
    //     }
    //     Pool.withdrawERC721(address(WPunk), punkIndexes, address(this));
    //     for (uint256 i = 0; i < punkIndexes.length; i++) {
    //         WPunk.burn(punkIndexes[i]);
    //         Punk.transferPunk(to, punkIndexes[i]);
    //     }
    // }

    /**
     * @dev transfer ERC721 from the utility contract, for ERC721 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param from punk owner of the transfer
     * @param to recipient of the transfer
     * @param tokenId tokenId to send
     */
    function emergencyTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IERC721(address(WPunk)).safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev transfer native Punk from the utility contract, for native Punk recovery in case of stuck Punk
     * due selfdestructs or transfer punk to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param punkIndex punk to send
     */
    function emergencyPunkTransfer(address to, uint256 punkIndex)
        external
        onlyOwner
    {
        Punk.transferPunk(to, punkIndex);
    }

    /**
     * @dev Get WPunk address used by WPunkGateway
     */
    function getWPunkAddress() external view returns (address) {
        return address(WPunk);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
