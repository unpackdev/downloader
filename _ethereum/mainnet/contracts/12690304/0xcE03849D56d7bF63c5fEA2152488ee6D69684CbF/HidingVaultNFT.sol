// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./HidingVault.sol";

/**
 * @title KeeperDAO's HidingVault Ownership Tracker Token
 * @author KeeperDAO
 * @dev This contract tokenises the ownership of the hiding vaults.
 */
contract HidingVaultNFT is Initializable, OwnableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, UUPSUpgradeable {
    using AddressUpgradeable for address;

    mapping (bytes4=>address) public implementations;

    /**
     * @dev Initializes the contract by setting up the `name` and `symbol`
     *      of this NFT contract and setup the owner of this contract.
     */
    function initialize() initializer public {
        __HidingVaultNFT_init();
    }

    function __HidingVaultNFT_init() initializer internal {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained("HidingVault", "HV");
        __ERC721Enumerable_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __Ownable_init_unchained();
    }

    /**
     * @notice Sets up a hiding vault. 
     * 
     * @param _salt allows a user to customise the hiding vault address
     */
    function mintHidingVault(bytes32 _salt) external payable returns (address hidingVault) {
        if (_salt != 0x0000000000000000000000000000000000000000000000000000000000000000) {
            _salt = keccak256(abi.encodePacked(_salt, msg.sender));
            hidingVault = address(new HidingVault{salt: _salt}());
        } else {
            hidingVault = address(new HidingVault());
        }
        _safeMint(msg.sender, uint256(uint160(hidingVault)));
    }

    /**
     * @notice Delegates the given function selectors to the implementation.
     *
     * @dev providing the same function selctor more than once would update the 
     * implementation address.
     * 
     * @param _implementation address of the implementation.
     * @param _fnSelectors list of function selectors that should be delegated to the
     * given implementation.
     */
    function delegateSelectors(address _implementation, bytes4[] memory _fnSelectors) external onlyOwner {
        for (uint i; i < _fnSelectors.length; i++) {
            implementations[_fnSelectors[i]] = _implementation;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    } 
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}