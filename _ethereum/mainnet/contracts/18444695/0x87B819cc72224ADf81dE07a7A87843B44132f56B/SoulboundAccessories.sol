/* solhint-disable private-vars-leading-underscore */

pragma solidity 0.8.18;

import "./ERC1155.sol";
import "./IERC6551Registry.sol";
import "./IERC6551Account.sol";
import "./TokenGatedAccount.sol";
import "./Ownable.sol";
import "./MiladyAvatar.sol";

/**
 * @title SoulboundAccessories Contract
 * @notice This contract handles the minting, equipping, and management of soulbound accessories for Milady Avatars.
 * @dev Inherits from ERC1155 and Ownable. Includes logic to mint and equip accessories, as well as administration functions.
 * @author Logan Brutsche
 */
contract SoulboundAccessories is ERC1155, Ownable {
    MiladyAvatar public avatarContract;

    // state needed for TBA address calculation
    IERC6551Registry public immutable tbaRegistry;
    IERC6551Account public immutable tbaAccountImpl;

    address public miladyAuthority;

    // indexed by miladyId
    mapping(uint => bool) public avatarActivated;

    address immutable initialDeployer;

    /**
     * @notice Creates a new instance of the SoulboundAccessories contract.
     * @param _tbaRegistry The TokenGatedAccount registry contract.
     * @param _tbaAccountImpl The TokenGatedAccount implementation contract.
     * @param _miladyAuthority The miladyAuthority address, intended to be held by the miladyAuthority server.
     * @param uri_ The base URI for the contract.
     */
    constructor(
        IERC6551Registry _tbaRegistry,
        IERC6551Account _tbaAccountImpl,
        address _miladyAuthority,
        string memory uri_
    )
        ERC1155(uri_)
    {
        initialDeployer = msg.sender;

        tbaRegistry = _tbaRegistry;
        tbaAccountImpl = _tbaAccountImpl;

        miladyAuthority = _miladyAuthority;
    }

    /**
     * @notice Sets the Avatar contract.
     * @param _avatarContract The MiladyAvatar contract.
     */
    function setAvatarContract(MiladyAvatar _avatarContract)
        external
    {
        require(msg.sender == initialDeployer, "Not initial deployer");
        require(address(avatarContract) == address(0), "Avatar already set");

        avatarContract = _avatarContract;
    }

    /**
     * @notice Changes the authority address for Milady.
     * @param _newMiladyAuthority The new authority address.
     */
    function changeMiladyAuthority(address _newMiladyAuthority)
        external
        onlyOwner()
    {
        miladyAuthority = _newMiladyAuthority;
    }

    /**
     * @dev Emitted when soulbound accessories are minted.
     * @param miladyId The ID of the Milady.
     * @param accessories The IDs of the accessories.
     */
    event SoulboundAccessoriesMinted(uint indexed miladyId, uint[] indexed accessories);

    /**
     * @notice Mints and equips soulbound accessories to a Milady Avatar.
     * @dev This function is only callable by the miladyAuthority.
     * We assume here that miladyAuthority will never specify an accessory whose decoded accVariant == 0
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accessories The IDs of the accessories to mint and equip.
     */
    function mintAndEquipSoulboundAccessories(uint _miladyId, uint[] calldata _accessories)
        external
    {
        require(msg.sender == miladyAuthority, "Not miladyAuthority");

        // perhaps not strictly necessary, but might prevent the miladyAuthority server doing something stupid
        require(_accessories.length > 0, "empty accessories array");

        require(!avatarActivated[_miladyId], "Avatar already activated");
        avatarActivated[_miladyId] = true;

        address avatarTbaAddress = tbaRegistry.account(
            address(tbaAccountImpl),
            block.chainid,
            address(avatarContract),
            _miladyId,
            0
        );

        uint[] memory listOf1s = new uint[](_accessories.length);
        for (uint i=0; i<listOf1s.length;) {
            listOf1s[i] = 1;

            unchecked { i++; }
        }

        _mintBatch(avatarTbaAddress, _accessories, listOf1s, "");

        avatarContract.equipSoulboundAccessories(_miladyId, _accessories);

        emit SoulboundAccessoriesMinted(_miladyId, _accessories);
    }

    /**
     * @notice Unmints and unequips soulbound accessories from a Milady Avatar.
     * This function is included as a last-resort option to leverage, in case the miladyAuthority key has been compromised.
     * It allows the owner to reverse any damage done by the key, by unminting and unequipping any erroneous soulboundAccessories.
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accessories The IDs of the accessories to unmint and unequip.
     */
    function unmintAndUnequipSoulboundAccessories(uint _miladyId, uint[] calldata _accessories)
        external
        onlyOwner()
    {
        require(avatarActivated[_miladyId], "Avatar not activated");
        avatarActivated[_miladyId] = false;

        address avatarTbaAddress = tbaRegistry.account(
            address(tbaAccountImpl),
            block.chainid,
            address(avatarContract),
            _miladyId,
            0
        );

        uint[] memory listOf1s = new uint[](_accessories.length);
        for (uint i=0; i<listOf1s.length;) {
            listOf1s[i] = 1;

            unchecked { i++; }
        }

        _burnBatch(avatarTbaAddress, _accessories, listOf1s);

        avatarContract.unequipSoulboundAccessories(_miladyId, _accessories);
    }

    /**
     * @notice Overrides the default function to disable all token transfers, making these soulbound.
     * @param _from The address transferring the tokens.
     */
    function _beforeTokenTransfer(address, address _from, address, uint256[] memory, uint256[] memory, bytes memory)
        internal
        override
    {
        if (_from == address(0x0)) {
            return; // allow transfers from 0x0, i.e. mints
        }
        revert("Cannot transfer soulbound tokens");
    }

    /**
     * @notice Overrides the default function to prevent spurious approvals.
     */
    function _setApprovalForAll(address, address, bool) 
        internal 
        override {
            revert("Cannot approve soulbound tokens");
    }
}