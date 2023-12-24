// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";

import "./LockAccessControl.sol";

// Credits to Revest Team
// Github:https://github.com/Revest-Finance/RevestContracts/blob/master/hardhat/contracts/FNFTHandler.sol
contract RedemptionNFT is
    AccessControlEnumerable,
    LockAccessControl,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    string private constant NAME = 'HRNFT';
    string private constant SYMBOL = 'HRNFT';

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    bytes32 public constant MODERATOR_ROLE = keccak256('MODERATOR_ROLE');

    Counters.Counter private _fnftIdTracker;

    /* ======= CONSTRUCTOR ======= */

    constructor(address provider)
        ERC721(NAME, SYMBOL)
        LockAccessControl(provider)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    ///////////////////////////////////////////////////////
    //              TOKENVAULT CALLED FUNCTIONS          //
    ///////////////////////////////////////////////////////

    function mint(address to)
        public
        virtual
        onlyModerator
        returns (uint256 fnftId)
    {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        fnftId = _fnftIdTracker.current();
        _fnftIdTracker.increment();
        _mint(to, fnftId);
    }

    function burnFromOwner(uint256 fnftId, address _owner) public virtual {
        require(
            _isApprovedOrOwner(_owner, fnftId),
            'ERC721Burnable: caller is not owner nor approved'
        );
        _burn(fnftId);
    }

    ///////////////////////////////////////////////////////
    //                PAUSER CALLED FUNCTIONS            //
    ///////////////////////////////////////////////////////

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            'ERC721PresetMinterPauserAutoId: must have pauser role to pause'
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            'ERC721PresetMinterPauserAutoId: must have pauser role to unpause'
        );
        _unpause();
    }

    ///////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS               //
    ///////////////////////////////////////////////////////

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
