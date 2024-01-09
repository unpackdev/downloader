// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721Full.sol";
import "./Counters.sol";
import "./IERC721.sol";
import "./Strings.sol";

import "./Address.sol";
import "./Bytes32.sol";
import "./Adminable.sol";
import "./Initializable.sol";
import "./DefiPassportStorageV1.sol";
import "./ISapphirePassportScores.sol";
import "./SapphireTypes.sol";

/**
 * @title DefiPassportSkin
 * @dev An upgrade to DefiPassport.sol that transforms the DefiPassport into a skin.
 */
contract DefiPassportSkin is ERC721Full, Adminable, DefiPassportStorageV1, Initializable {

    /* ========== Libraries ========== */

    using Counters for Counters.Counter;
    using Address for address;
    using Bytes32 for bytes32;
    using Strings for uint256;

    /* ========== Events ========== */

    event BaseURISet(string _baseURI);

    event NameAndSymbolChanged(string _name, string _symbol);

    /* ========== Public variables ========== */

    string public override baseURI;

    /**
     * @dev Deprecated. Including this because this is a proxy implementation.
     */
    bytes32 private _proofProtocol;

    /* ========== Restricted Functions ========== */

    function init(
        string calldata name_,
        string calldata symbol_
    )
        external
        onlyAdmin
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Sets the base URI that is appended as a prefix to the
     *      token URI.
     */
    function setBaseURI(
        string calldata _baseURI
    )
        external
        onlyAdmin
    {
        baseURI = _baseURI; 
        emit BaseURISet(_baseURI);
    }

    /**
     * @dev Since this contract transforms the DefiPassport into a skin, we also need a
     *      way to set the name and symbol to reflect the meaning of this contract.
     */
    function setNameAndSymbol(
        string calldata name_,
        string calldata symbol_
    )
        external
        onlyAdmin
    {
        _name = name_;
        _symbol = symbol_;

        emit NameAndSymbolChanged(name_, symbol_);
    }

    /* ========== Public View Functions ========== */

    function name()
        external
        override
        view
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        external
        override
        view
        returns (string memory)
    {
        return _symbol;
    }

    function tokenURI(
        uint256 tokenId
    )
        external
        override
        view 
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}
