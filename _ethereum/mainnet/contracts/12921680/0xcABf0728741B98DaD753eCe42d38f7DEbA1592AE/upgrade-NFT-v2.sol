// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./store.sol";
import "./authorized.sol";

// Utils
import "./data.sol";

// Interfaces
import "./MainnetTellerNFT.sol";

contract ent_upgradeNFTV2_NFTDistributor_v1 is
    sto_NFTDistributor,
    mod_authorized_AccessControl_v1
{
    /**
     * @notice Upgrades the reference to the NFT to the V2 deployment address.
     * @param _nft The address of the TellerNFT.
     */
    function upgradeNFTV2(address _nft)
        external
        authorized(ADMIN, msg.sender)
    {
        require(distributorStore().version == 0, "Teller: invalid upgrade version");
        distributorStore().version = 1;
        distributorStore().nft = MainnetTellerNFT(_nft);
    }
}
