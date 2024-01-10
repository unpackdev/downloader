// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IOrganization.sol";
import "./ISubDAOsManager.sol";
import "./IDelegationsManager.sol";
import "./ITreasurySplitterManager.sol";
import "./IInvestmentsManager.sol";
import "./IDelegationTokensManager.sol";

library Grimoire {
    bytes32 constant public COMPONENT_KEY_TREASURY_SPLITTER_MANAGER = 0x87a92f6bd20613c184485be8eadb46851dd4294a8359f902606085b8be6e7ae6;
    bytes32 constant public COMPONENT_KEY_SUBDAOS_MANAGER = 0x5b87d6e94145c2e242653a71b7d439a3638a93c3f0d32e1ea876f9fb1feb53e2;
    bytes32 constant public COMPONENT_KEY_DELEGATIONS_MANAGER = 0x49b87f4ee20613c184485be8eadb46851dd4294a8359f902606085b8be6e7ae6;
    bytes32 constant public COMPONENT_KEY_INVESTMENTS_MANAGER = 0x4f3ad97a91794a00945c0ead3983f793d34044c6300048d8b4ef95636edd234b;
}

library DelegationGrimoire {
    bytes32 constant public COMPONENT_KEY_TOKENS_MANAGER = 0x62b56c3ab20613c184485be8eadb46851dd4294a8359f902606085b8be9f7dc5;
}

library Getters {
    function treasurySplitterManager(IOrganization organization) internal view returns(ITreasurySplitterManager) {
        return ITreasurySplitterManager(organization.get(Grimoire.COMPONENT_KEY_TREASURY_SPLITTER_MANAGER));
    }

    function subDAOsManager(IOrganization organization) internal view returns(ISubDAOsManager) {
        return ISubDAOsManager(organization.get(Grimoire.COMPONENT_KEY_SUBDAOS_MANAGER));
    }

    function delegationsManager(IOrganization organization) internal view returns(IDelegationsManager) {
        return IDelegationsManager(organization.get(Grimoire.COMPONENT_KEY_DELEGATIONS_MANAGER));
    }

    function investmentsManager(IOrganization organization) internal view returns(IInvestmentsManager) {
        return IInvestmentsManager(organization.get(Grimoire.COMPONENT_KEY_INVESTMENTS_MANAGER));
    }
}

library Setters {
    function replaceTreasurySplitterManager(IOrganization organization, address newComponentAddress) internal returns(ITreasurySplitterManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = ITreasurySplitterManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_TREASURY_SPLITTER_MANAGER, newComponentAddress, false, true)));
    }

    function replaceSubDAOsManager(IOrganization organization, address newComponentAddress) internal returns(ISubDAOsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = ISubDAOsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_SUBDAOS_MANAGER, newComponentAddress, true, true)));
    }

    function replaceDelegationsManager(IOrganization organization, address newComponentAddress) internal returns(IDelegationsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IDelegationsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_DELEGATIONS_MANAGER, newComponentAddress, false, true)));
    }

    function replaceInvestmentsManager(IOrganization organization, address newComponentAddress) internal returns(IInvestmentsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IInvestmentsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_INVESTMENTS_MANAGER, newComponentAddress, false, true)));
    }
}

library DelegationGetters {
    function tokensManager(IOrganization organization) internal view returns(IDelegationTokensManager) {
        return IDelegationTokensManager(organization.get(DelegationGrimoire.COMPONENT_KEY_TOKENS_MANAGER));
    }
}

library DelegationUtilities {
    using DelegationGetters for IOrganization;

    function extractVotingTokens(address delegationsManagerAddress, address delegationAddress) internal view returns (bytes memory) {
        IDelegationsManager delegationsManager = IDelegationsManager(delegationsManagerAddress);
        (bool exists,,) = delegationsManager.exists(delegationAddress);
        require(exists, "wrong address");
        (address collection, uint256 tokenId) = delegationsManager.supportedToken();
        (collection, tokenId) = IOrganization(delegationAddress).tokensManager().wrapped(collection, tokenId, delegationsManagerAddress);
        require(tokenId != 0, "Wrap tokens first");
        address[] memory collections = new address[](1);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory weights = new uint256[](1);
        collections[0] = collection;
        tokenIds[0] = tokenId;
        weights[0] = 1;
        return abi.encode(collections, tokenIds, weights);
    }
}