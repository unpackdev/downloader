/* solhint-disable private-vars-leading-underscore */

pragma solidity 0.8.18;

import "./IERC721.sol";
import "./TBARegistry.sol";
import "./TokenGatedAccount.sol";
import "./MiladyAvatar.sol";
import "./LiquidAccessories.sol";
import "./SoulboundAccessories.sol";
import "./Rewards.sol";


/**
 * @title Deployer Contract
 * @notice This contract orchestrates the deployment of other contracts including MiladyAvatar, Rewards, LiquidAccessories, and SoulboundAccessories.
 * @dev Instantiates the contracts with necessary parameters and sets up the relationships between them.
 * @author Logan Brutsche
 */
contract Deployer {
    MiladyAvatar public avatarContract;
    Rewards public rewardsContract;
    LiquidAccessories public liquidAccessoriesContract;
    SoulboundAccessories public soulboundAccessoriesContract;

    /**
     * @notice Emits the addresses of the deployed contracts upon successful deployment.
     * @param avatarContractAddress Address of the deployed MiladyAvatar contract.
     * @param liquidAccessoriesContractAddress Address of the deployed LiquidAccessories contract.
     * @param soulboundAccessoriesContractAddress Address of the deployed SoulboundAccessories contract.
     * @param rewardsContractAddress Address of the deployed Rewards contract.
     */
    event Deployed(
        address avatarContractAddress,
        address liquidAccessoriesContractAddress,
        address soulboundAccessoriesContractAddress,
        address rewardsContractAddress
    );

    /**
     * @notice Constructs the Deployer contract and deploys the other contracts, establishing the necessary relationships between them.
     * @param tbaRegistry The address of the TBARegistry contract.
     * @param tbaAccountImpl The address of the TokenGatedAccount implementation contract.
     * @param miladysContract The address of the Miladys contract.
     * @param miladyAuthorityAddress The address of the Milady Authority.
     * @param liquidAccessoriesOwner The address to be set as the owner of the LiquidAccessories contract.
     * @param soulboundAccessoriesOwner The address to be set as the owner of the SoulboundAccessories contract.
     * @param revenueRecipient The address to receive revenue from LiquidAccessories.
     * @param avatarBaseURI The base URI for the MiladyAvatar contract.
     * @param liquidAccessoriesURI The URI for the LiquidAccessories contract.
     * @param soulboundAccessoriesURI The URI for the SoulboundAccessories contract.
     */
    constructor(
        TBARegistry tbaRegistry,
        TokenGatedAccount tbaAccountImpl,
        IERC721 miladysContract,
        address miladyAuthorityAddress,
        address liquidAccessoriesOwner,
        address soulboundAccessoriesOwner,
        address payable revenueRecipient,
        string memory avatarBaseURI,
        string memory liquidAccessoriesURI,
        string memory soulboundAccessoriesURI
    )
    {
        avatarContract = new MiladyAvatar(
            miladysContract,
            tbaRegistry,
            tbaAccountImpl,
            avatarBaseURI
        );

        rewardsContract = new Rewards(address(avatarContract), miladysContract);

        liquidAccessoriesContract = new LiquidAccessories(
            tbaRegistry,
            rewardsContract,
            revenueRecipient,
            liquidAccessoriesURI
        );

        soulboundAccessoriesContract = new SoulboundAccessories(
            tbaRegistry,
            tbaAccountImpl,
            miladyAuthorityAddress,
            soulboundAccessoriesURI
        );

        avatarContract.setOtherContracts(liquidAccessoriesContract, soulboundAccessoriesContract, rewardsContract);
        liquidAccessoriesContract.setAvatarContract(avatarContract);
        soulboundAccessoriesContract.setAvatarContract(avatarContract);

        liquidAccessoriesContract.transferOwnership(liquidAccessoriesOwner);
        soulboundAccessoriesContract.transferOwnership(soulboundAccessoriesOwner);

        emit Deployed(
            address(avatarContract),
            address(liquidAccessoriesContract),
            address(soulboundAccessoriesContract),
            address(rewardsContract)
        );
    }
}