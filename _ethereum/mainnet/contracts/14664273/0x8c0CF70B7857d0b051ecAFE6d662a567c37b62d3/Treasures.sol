// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dao: DumpsterDAO

/*
                TTTTTTTT DumpsterDAO TTTTTTT
              TTT    TTT  TREASURES TTTTTTTTTTT
            TTT  TT  TT TTTT TTTT   TTTTTT TTTTT
          TTT  TTT  TT  TTTT TTTT   TTTTTT  TTTTTT
        TTT   TTT   TT TTTTT TTTT    TTTTTT   TTTTTT
       TTT   TTTTT  TT  TTTTT TTTT    TTTTTTT    TTTTT
     TTT    TTTTT   TT  TTTTT TTTT     TTTTTT     TTTTTT
     TTTT     TT  TT  TTTTTT TTTT     TTTTTTTTTTTTTTTTTT
      TTTTTTT    TTT  TTTTTT TTTT   TTTTTTTTTTTTTTTTTTT
        TTT   TTTTTT          TTTTTTTTTTTTTTTTTTTTTTTT
          TT  T   TTTTTTTTTTTTTTTTTTTTTTTTTTTTT  TTT
           TTT TTT TT         TTTTTTTTTTTTTT   TTTT
            TT  TT TT  TTTTT TTT      TTTT   TTTT
              TT TT TT  TTTT TTT     TTTT  TTTT
                TT TT TT TTTT  TT    TTTT  TTT
                  TT T TT TTT  TT   TTTT TTT
                   TT T TT TT  TT  TTTT TT
                    TT  T  T  TT  TTTTTT
                      T  T    TT TTTTTT
                       TTT T   TTTTTTT
                         TTTT  TTTTT
                          TTT TTTT
                           TTTTTT
                            TTT
                             T

*/

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./ERC2981PerTokenRoyalties.sol";

contract Treasures is
    ERC1155,
    ERC1155Supply,
    ERC2981PerTokenRoyalties,
    AccessControl,
    Ownable
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private tokenCounter;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _tokenMaxIssuance;

    constructor(string memory _uri) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(exists(tokenId), "nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function maxIssuance(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenMaxIssuance[tokenId];
    }

    // ADMIN FUNCTIONS //

    function initializeToken(
        address _creator,
        uint256 _maxIssuance,
        string memory _tokenURI
    ) public virtual onlyRole(MINTER_ROLE) returns (uint256) {
        tokenCounter.increment();
        uint256 currentId = tokenCounter.current();

        _setMaxIssuance(currentId, _maxIssuance);
        _setTokenURI(currentId, _tokenURI);
        _setTokenRoyalty(currentId, _creator, 1000);

        return currentId;
    }

    function setMaxIssuance(uint256 tokenId, uint256 _maxIssuance)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMaxIssuance(tokenId, _maxIssuance);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public virtual onlyRole(MINTER_ROLE) returns (bool) {
        uint256 newSupply = totalSupply(id) + amount;
        require(newSupply <= _tokenMaxIssuance[id], "max issuance reached");

        _mint(to, id, amount, "");
        return true;
    }

    function setRoyalties(
        uint256 tokenId,
        address recipient,
        uint256 value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, recipient, value);
    }

    // INTERNAL FUNCTIONS //

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setMaxIssuance(uint256 tokenId, uint256 _maxIssuance)
        internal
        virtual
    {
        _tokenMaxIssuance[tokenId] = _maxIssuance;
    }

    // OVERRIDE FUNCTIONS //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
