// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./APMorgan.sol";

contract APMorganView is UUPSUpgradeable, AccessControlUpgradeable {
    APMorgan apMorgan;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    function initialize(address _apMorgan, address admin) public initializer {
        apMorgan = APMorgan(_apMorgan);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    /// @notice check if layer + chain combination has already been minted used in ui
    /// @param layer2 - unique layer 2
    /// @param layer3 - unique layer 3
    /// @param layer4 - unique layer 4
    /// @param layer5 - unique layer 5
    /// @param layer6 - unique layer 6
    function layerComboAlreadyMinted(
        uint8 layer2,
        uint8 layer3,
        uint8 layer4,
        uint8 layer5,
        uint8 layer6
    ) public view returns (bool) {
        return
            apMorgan.layerComboUsed(
                apMorgan.getTokenUniquenessKey(
                    block.chainid,
                    layer2,
                    layer3,
                    layer4,
                    layer5,
                    layer6
                )
            );
    }

    /**
     * @notice view function for ease of mapping user to tokens and identifying which is their preferred token
     * @param user - the user we want to get the tokens for
     * @dev Acknowledgement of unbounded loop only expected to be used to read values off chain
     */
    function tokensAndPreferredToken(address user)
        external
        view
        returns (
            bool hasToken,
            uint256 preferred,
            uint256[] memory tokens
        )
    {
        uint256 balance = apMorgan.balanceOf(user);

        hasToken = balance > 0;
        preferred = apMorgan.preferredToken(user);
        tokens = new uint256[](balance);

        for (uint16 i = 0; i < balance; i++)
            tokens[i] = apMorgan.tokenOfOwnerByIndex(user, i);
    }

    /// @notice used for upgrading
    /// @param newImplementation - Address of new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /// @notice used for upgrading
    /// @param interfaceId - interface identifier for contract
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}
