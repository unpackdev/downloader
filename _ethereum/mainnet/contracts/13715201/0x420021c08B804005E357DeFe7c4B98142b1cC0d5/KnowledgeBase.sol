// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IOrganization.sol";
import "./IMicroservicesManager.sol";
import "./IStateManager.sol";
import "./IProposalsManager.sol";
import "./ITreasuryManager.sol";
import "./GeneralUtilities.sol";

library Grimoire {
    bytes32 constant public COMPONENT_KEY_TREASURY_MANAGER = 0xcfe1633df53a0649d88d788961f26058c5e7a0b5644675f19f67bb2975827ba2;
    bytes32 constant public COMPONENT_KEY_STATE_MANAGER = 0xd1d09e8f5708558865b8acd5f13c69781ae600e42dbc7f52b8ef1b9e33dbcd36;
    bytes32 constant public COMPONENT_KEY_MICROSERVICES_MANAGER = 0x0aef4c8f864010d3e1817691f51ade95a646fffafd7f3df9cb8200def342cfd7;
    bytes32 constant public COMPONENT_KEY_PROPOSALS_MANAGER = 0xa504406933af7ca120d20b97dfc79ea9788beb3c4d3ac1ff9a2c292b2c28e0cc;
}

library Getters {

    function treasuryManager(IOrganization organization) internal view returns(ITreasuryManager) {
        return ITreasuryManager(organization.get(Grimoire.COMPONENT_KEY_TREASURY_MANAGER));
    }

    function stateManager(IOrganization organization) internal view returns(IStateManager) {
        return IStateManager(organization.get(Grimoire.COMPONENT_KEY_STATE_MANAGER));
    }

    function microservicesManager(IOrganization organization) internal view returns(IMicroservicesManager) {
        return IMicroservicesManager(organization.get(Grimoire.COMPONENT_KEY_MICROSERVICES_MANAGER));
    }

    function proposalsManager(IOrganization organization) internal view returns(IProposalsManager) {
        return IProposalsManager(organization.get(Grimoire.COMPONENT_KEY_PROPOSALS_MANAGER));
    }
}

library Setters {

    function replaceTreasuryManager(IOrganization organization, address newComponentAddress) internal returns(ITreasuryManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = ITreasuryManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_TREASURY_MANAGER, newComponentAddress, false, true)));
    }

    function replaceStateManager(IOrganization organization, address newComponentAddress) internal returns(IStateManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IStateManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_STATE_MANAGER, newComponentAddress, false ,true)));
    }

    function replaceMicroservicesManager(IOrganization organization, address newComponentAddress) internal returns(IMicroservicesManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IMicroservicesManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_MICROSERVICES_MANAGER, newComponentAddress, true, true)));
    }

    function replaceProposalsManager(IOrganization organization, address newComponentAddress) internal returns(IProposalsManager oldComponent) {
        require(newComponentAddress != address(0), "void");
        oldComponent = IProposalsManager(organization.set(IOrganization.Component(Grimoire.COMPONENT_KEY_PROPOSALS_MANAGER, newComponentAddress, true, true)));
    }
}

library Treasury {
    using ReflectionUtilities for address;

    function storeETH(IOrganization organization, uint256 value) internal {
        if(value != 0) {
            organization.get(Grimoire.COMPONENT_KEY_TREASURY_MANAGER).submit(value, "");
        }
    }

    function callTemporaryFunction(ITreasuryManager treasuryManager, bytes4 selector, address subject, uint256 value, bytes memory data) internal returns(bytes memory response) {
        address oldServer = treasuryManager.setAdditionalFunction(selector, subject, false);
        response = address(treasuryManager).submit(value, abi.encodePacked(selector, data));
        treasuryManager.setAdditionalFunction(selector, oldServer, false);
    }
}

library State {
    using BytesUtilities for bytes;

    bytes32 constant public ENTRY_TYPE_ADDRESS = 0x421683f821a0574472445355be6d2b769119e8515f8376a1d7878523dfdecf7b;
    bytes32 constant public ENTRY_TYPE_ADDRESS_ARRAY = 0x23d8ff3dc5aed4a634bcf123581c95e70c60ac0e5246916790aef6d4451ff4c1;
    bytes32 constant public ENTRY_TYPE_BOOL = 0xc1053bdab4a5cf55238b667c39826bbb11a58be126010e7db397c1b67c24271b;
    bytes32 constant public ENTRY_TYPE_BOOL_ARRAY = 0x8761250c4d2c463ce51f91f5d2c2508fa9142f8a42aa9f30b965213bf3e6c2ac;
    bytes32 constant public ENTRY_TYPE_BYTES = 0xb963e9b45d014edd60cff22ec9ad383335bbc3f827be2aee8e291972b0fadcf2;
    bytes32 constant public ENTRY_TYPE_BYTES_ARRAY = 0x084b42f8a8730b98eb0305d92103d9107363192bb66162064a34dc5716ebe1a0;
    bytes32 constant public ENTRY_TYPE_STRING = 0x97fc46276c172633607a331542609db1e3da793fca183d594ed5a61803a10792;
    bytes32 constant public ENTRY_TYPE_STRING_ARRAY = 0xa227fd7a847724343a7dda3598ee0fb2d551b151b73e4a741067596daa6f5658;
    bytes32 constant public ENTRY_TYPE_UINT256 = 0xec13d6d12b88433319b64e1065a96ea19cd330ef6603f5f6fb685dde3959a320;
    bytes32 constant public ENTRY_TYPE_UINT256_ARRAY = 0xc1b76e99a35aa41ed28bbbd9e6c7228760c87b410ebac94fa6431da9b592411f;

    function getAddress(IStateManager stateManager, string memory name) internal view returns(address) {
        return stateManager.get(name).value.asAddress();
    }

    function setAddress(IStateManager stateManager, string memory name, address val) internal returns(address oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_ADDRESS, abi.encodePacked(val))).asAddress();
    }

    function getAddressArray(IStateManager stateManager, string memory name) internal view returns(address[] memory) {
        return stateManager.get(name).value.asAddressArray();
    }

    function setAddressArray(IStateManager stateManager, string memory name, address[] memory val) internal returns(address[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_ADDRESS_ARRAY, abi.encode(val))).asAddressArray();
    }

    function getBool(IStateManager stateManager, string memory name) internal view returns(bool) {
        return stateManager.get(name).value.asBool();
    }

    function setBool(IStateManager stateManager, string memory name, bool val) internal returns(bool oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BOOL, abi.encode(val ? 1 : 0))).asBool();
    }

    function getBoolArray(IStateManager stateManager, string memory name) internal view returns(bool[] memory) {
        return stateManager.get(name).value.asBoolArray();
    }

    function setBoolArray(IStateManager stateManager, string memory name, bool[] memory val) internal returns(bool[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BOOL_ARRAY, abi.encode(val))).asBoolArray();
    }

    function getBytes(IStateManager stateManager, string memory name) internal view returns(bytes memory) {
        return stateManager.get(name).value;
    }

    function setBytes(IStateManager stateManager, string memory name, bytes memory val) internal returns(bytes memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BYTES, val));
    }

    function getBytesArray(IStateManager stateManager, string memory name) internal view returns(bytes[] memory) {
        return stateManager.get(name).value.asBytesArray();
    }

    function setBytesArray(IStateManager stateManager, string memory name, bytes[] memory val) internal returns(bytes[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_BYTES_ARRAY, abi.encode(val))).asBytesArray();
    }

    function getString(IStateManager stateManager, string memory name) internal view returns(string memory) {
        return string(stateManager.get(name).value);
    }

    function setString(IStateManager stateManager, string memory name, string memory val) internal returns(string memory oldValue) {
        return string(stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_STRING, bytes(val))));
    }

    function getStringArray(IStateManager stateManager, string memory name) internal view returns(string[] memory) {
        return stateManager.get(name).value.asStringArray();
    }

    function setStringArray(IStateManager stateManager, string memory name, string[] memory val) internal returns(string[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_STRING_ARRAY, abi.encode(val))).asStringArray();
    }

    function getUint256(IStateManager stateManager, string memory name) internal view returns(uint256) {
        return stateManager.get(name).value.asUint256();
    }

    function setUint256(IStateManager stateManager, string memory name, uint256 val) internal returns(uint256 oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_UINT256, abi.encode(val))).asUint256();
    }

    function getUint256Array(IStateManager stateManager, string memory name) internal view returns(uint256[] memory) {
        return stateManager.get(name).value.asUint256Array();
    }

    function setUint256Array(IStateManager stateManager, string memory name, uint256[] memory val) internal returns(uint256[] memory oldValue) {
        return stateManager.set(IStateManager.StateEntry(name, ENTRY_TYPE_UINT256_ARRAY, abi.encode(val))).asUint256Array();
    }
}