/* solhint-disable private-vars-leading-underscore */

pragma solidity 0.8.18;

import "./IERC721.sol";
import "./TBARegistry.sol";
import "./TokenGatedAccount.sol";
import "./MiladyAvatar.sol";
import "./LiquidAccessories.sol";
import "./SoulboundAccessories.sol";
import "./Rewards.sol";

contract Deployer {
    MiladyAvatar public avatarContract;
    Rewards public rewardsContract;
    LiquidAccessories public liquidAccessoriesContract;
    SoulboundAccessories public soulboundAccessoriesContract;

    event Deployed(
        address avatarContractAddress,
        address liquidAccessoriesContractAddress,
        address soulboundAccessoriesContractAddress,
        address rewardsContractAddress
    );

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