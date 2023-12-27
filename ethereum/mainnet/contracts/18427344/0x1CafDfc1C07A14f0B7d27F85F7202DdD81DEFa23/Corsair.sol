// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721Drop.sol";

import "./ERC2771ContextUpgradeable.sol";
import "./PermissionsEnumerable.sol";
import "./PlatformFee.sol";
import "./ERC721AVirtualApproveUpgradeable.sol";

/*
   ____ ___  ____  ____    _    ___ ____  
  / ___/ _ \|  _ \/ ___|  / \  |_ _|  _ \ 
 | |  | | | | |_) \___ \ / _ \  | || |_) |
 | |__| |_| |  _ < ___) / ___ \ | ||  _ < 
  \____\___/|_| \_\____/_/   \_\___|_| \_\
                                          
*/

contract Corsair is
    ERC721Drop,
    PlatformFee,
    PermissionsEnumerable
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private transferRole;
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private minterRole;
    /// @dev Only METADATA_ROLE holders can reveal the URI for a batch of delayed reveal NFTs, and update or freeze batch metadata.
    bytes32 private metadataRole;

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _primarySaleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    )
        ERC721Drop(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _metadataRole = keccak256("METADATA_ROLE");

        // Initialize inherited contracts, most base-like -> most derived.

        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_metadataRole, _defaultAdmin);
        _setRoleAdmin(_metadataRole, _metadataRole);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_primarySaleRecipient);

        transferRole = _transferRole;
        minterRole = _minterRole;
        metadataRole = _metadataRole;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _canSetPlatformFeeInfo()
        internal
        view
        virtual
        override
        returns (bool)
    {}
}

/*

  _  _ _____ __  ____     _    ____  __  __    _    ____    _    
 | || |___  / /_|___ \   / \  |  _ \|  \/  |  / \  |  _ \  / \   
 | || |_ / / '_ \ __) | / _ \ | |_) | |\/| | / _ \ | | | |/ _ \  
 |__   _/ /| (_) / __/ / ___ \|  _ <| |  | |/ ___ \| |_| / ___ \ 
    |_|/_/  \___/_____/_/   \_\_| \_\_|  |_/_/   \_\____/_/   \_\
                                                                
*/
