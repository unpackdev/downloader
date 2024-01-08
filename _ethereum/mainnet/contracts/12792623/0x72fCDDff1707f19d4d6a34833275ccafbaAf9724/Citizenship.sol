// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";


contract Citizenship is Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    event BaseURIChanged(address indexed by, string uri);

    Counters.Counter private _citizenshipIdTracker;

    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address[] memory admins
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        for (uint i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
            
            _setupRole(Roles.MINTER_ROLE, admins[i]);
            _setupRole(Roles.PAUSER_ROLE, admins[i]);
            _setupRole(Roles.URI_SETTER_ROLE, admins[i]);

            _mint(admins[i], _citizenshipIdTracker.current());
            _citizenshipIdTracker.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory uri) public returns (bool) {
        require(hasRole(Roles.URI_SETTER_ROLE, _msgSender()), "Citizenship: must have URI setter role");

        _baseTokenURI = uri;
        emit BaseURIChanged(_msgSender(), uri);

        return true;
    }

    function mint(address to) public virtual {
        require(hasRole(Roles.MINTER_ROLE, _msgSender()), "Citizenship: must have minter role to mint");

        _mint(to, _citizenshipIdTracker.current());
        _citizenshipIdTracker.increment();
    }

    function pause() public virtual {
        require(hasRole(Roles.PAUSER_ROLE, _msgSender()), "Citizenship: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(Roles.PAUSER_ROLE, _msgSender()), "Citizenship: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _writeProposalToLedger(uint256 index) private {
    }

    function _passProposalInLedger(uint256 index) private {
    }

}
