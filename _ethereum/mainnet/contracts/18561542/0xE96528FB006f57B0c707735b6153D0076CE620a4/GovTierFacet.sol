// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./LibGovTier.sol";
import "./LibGovTierStorage.sol";
import "./LibAppStorage.sol";
import "./LibMeta.sol";
import "./LibDiamond.sol";

contract GovTierFacet is Modifiers {
    function govTierFacetInit(
        bytes32 _bronze,
        bytes32 _silver,
        bytes32 _gold,
        bytes32 _platinum
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();

        require(msg.sender == ds.contractOwner, "Must own the contract.");
        require(!es.isInitializedGovtier, "Already initialized Gov Tier");
        LibGovTier._addTierLevel(
            _bronze,
            LibGovTierStorage.TierData(
                15000e18,
                30,
                false,
                true,
                false,
                true,
                false,
                false
            )
        );
        LibGovTier._addTierLevel(
            _silver,
            LibGovTierStorage.TierData(
                30000e18,
                40,
                false,
                true,
                false,
                true,
                false,
                false
            )
        );
        LibGovTier._addTierLevel(
            _gold,
            LibGovTierStorage.TierData(
                75000e18,
                50,
                false,
                true,
                true,
                true,
                true,
                true
            )
        );
        LibGovTier._addTierLevel(
            _platinum,
            LibGovTierStorage.TierData(
                150000e18,
                70,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
        es.isInitializedGovtier = true;

        emit LibGovTierStorage.GovTierFacetInitialized(
            _bronze,
            _silver,
            _gold,
            _platinum
        );
    }

    /// @dev external function to add new tier level (keys with their access values)
    /// @param _newTierLevel must be a new tier key in bytes32
    /// @param _tierData access variables of the each Tier Level

    function addTierLevel(
        bytes32 _newTierLevel,
        LibGovTierStorage.TierData memory _tierData
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();

        require(
            _tierData.govHoldings >
                es
                    .tierLevels[
                        es.allTierLevelKeys[LibGovTier.maxGovTierLevelIndex()]
                    ]
                    .govHoldings,
            "GovHolding Should be greater then last tier level Gov Holdings"
        );
        //adding tier level called by the admin
        LibGovTier._addTierLevel(_newTierLevel, _tierData);
    }

    /// @dev this function add new tier level if not exist and update tier level if already exist.
    /// @param _tierLevelKeys bytes32 array to add or edit multiple tiers
    /// @param _newTierData   new tier data struct details, check IGovTier interface
    function saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        LibGovTierStorage.TierData[] memory _newTierData
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        require(
            _tierLevelKeys.length == _newTierData.length,
            "New Tier Keys and TierData length must be equal"
        );
        LibGovTier._saveTierLevel(_tierLevelKeys, _newTierData);
    }

    /// @dev external function to update the existing tier level, also check if it is already added or not
    /// @param _updatedTierLevelKey existing tierlevel key
    /// @param _newTierData new data for the updateding Tier level

    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        LibGovTierStorage.TierData memory _newTierData
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        AppStorage storage s = LibAppStorage.appStorage();

        address govToken = s.govToken;

        require(
            _newTierData.govHoldings < IERC20(govToken).totalSupply(),
            "GTL:govholding should less then total supply of gov tokens"
        );
        require(
            LibGovTier.isAlreadyTierLevel(_updatedTierLevelKey),
            "Tier: cannot update Tier, create new tier first"
        );
        LibGovTier._updateTierLevel(_updatedTierLevelKey, _newTierData);
    }

    /// @dev remove tier level key as well as from mapping
    /// @param _existingTierLevel tierlevel hash in bytes32

    function removeTierLevel(
        bytes32 _existingTierLevel
    ) external onlyEditTierLevelRole(LibMeta._msgSender()) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();

        require(
            es.tierLevels[_existingTierLevel].govHoldings > 15000e18,
            "Bronze Tier cannot be removed"
        );
        require(
            LibGovTier.isAlreadyTierLevel(_existingTierLevel),
            "Tier: cannot remove, Tier Level not exist"
        );
        delete es.tierLevels[_existingTierLevel];
        emit LibGovTier.TierLevelRemoved(_existingTierLevel);

        LibGovTier._removeTierLevelKey(
            LibGovTier._getIndex(_existingTierLevel)
        );
    }

    /// @dev get all the Tier Level Keys from the allTierLevelKeys array
    /// @return bytes32[] returns all the tier level keys
    function getGovTierLevelKeys() external view returns (bytes32[] memory) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        return es.allTierLevelKeys;
    }

    /// @dev get Single Tier Level Data

    function getSingleTierData(
        bytes32 _tierLevelKey
    ) external view returns (LibGovTierStorage.TierData memory) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        return es.tierLevels[_tierLevelKey];
    }

    /**
     * @dev function to assign tier level to the address only by the super admin
     */
    function addWalletTierLevel(
        address[] memory _userAddress,
        bytes32[] memory _tierLevel
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        require(
            _userAddress.length == _tierLevel.length,
            "length error in addWallet tier"
        );
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        uint256 length = _userAddress.length;
        for (uint256 i = 0; i < length; i++) {
            address user = _userAddress[i];
            require(
                es.tierLevelbyAddress[user] == bytes32(0),
                "Already Assigned Tier"
            );
            require(
                LibGovTier.isAlreadyTierLevel(_tierLevel[i]),
                "tier level not exist"
            );
            es.tierLevelbyAddress[user] = _tierLevel[i];
            emit LibGovTier.AddedWalletTier(user, _tierLevel[i]);
        }
    }

    function updateWalletTier(
        address[] memory _userAddress,
        bytes32[] memory _tierLevel
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        require(
            _userAddress.length == _tierLevel.length,
            "length error in update wallet tier"
        );
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();

        uint256 length = _userAddress.length;
        for (uint256 i = 0; i < length; i++) {
            address user = _userAddress[i];

            require(
                LibGovTier.isAlreadyTierLevel(_tierLevel[i]) || _tierLevel[i] == bytes32(0),
                "tier level not exist"
            );

            es.tierLevelbyAddress[user] = _tierLevel[i];
            emit LibGovTier.UpdatedWalletTier(user, _tierLevel[i]);
        }
    }

    function getWalletTier(
        address _userAddress
    ) external view returns (bytes32 _tierLevel) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        return es.tierLevelbyAddress[_userAddress];
    }
}
