// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**                       ███████╗ █████╗ ███╗   ██╗
 *                        ██╔════╝██╔══██╗████╗  ██║
 *                        ███████╗███████║██╔██╗ ██║
 *                        ╚════██║██╔══██║██║╚██╗██║
 *                        ███████║██║  ██║██║ ╚████║
 *                        ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝
 *
 *                              █████████████╗
 *                              ╚════════════╝
 *                               ███████████╗
 *                               ╚══════════╝
 *                            █████████████████╗
 *                            ╚════════════════╝
 *
 *                    ██╗    ██╗███████╗ █████╗ ██████╗
 *                    ██║    ██║██╔════╝██╔══██╗██╔══██╗
 *                    ██║ █╗ ██║█████╗  ███████║██████╔╝
 *                    ██║███╗██║██╔══╝  ██╔══██║██╔══██╗
 *                    ╚███╔███╔╝███████╗██║  ██║██║  ██║
 *                     ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
 */

import "./Ownable.sol";
import "./AccessControl.sol";
import {ERC1155URIStorage, ERC1155}
    from "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./ArrayUtils.sol";
import "./ISANWEAR.sol";
import "./ISANWORN.sol";
import "./ERC2981Plus.sol";

/**
 * @title SANWEAR™ by SAN SOUND
 * @author Aaron Hanson <coffee.becomes.code@gmail.com> @CoffeeConverter
 * @notice https://sansound.io/
 */
contract SANWEAR is Ownable, AccessControl, ERC1155URIStorage, ERC2981Plus, ISANWEAR {
    error ArrayLengthMismatch();
    error ClaimAmountZero();
    error ClaimInactive();
    error InvalidTokenId();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    ISANWORN public SANWORN;
    string public constant name = "SANWEAR by SAN SOUND";
    string public constant symbol = "SANWEAR";
    string public contractURI;

    constructor(
        string memory _uri,
        string memory _contractUri,
        address _royaltyReceiver,
        uint96 _royaltyBps
    )
        ERC1155(_uri)
        Ownable(_msgSender())
    {
        contractURI = _contractUri;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyBps);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function claim(
        uint256 _id,
        uint256 _amount
    )
        external
    {
        if (address(SANWORN) == address(0)) revert ClaimInactive();
        if (_amount == 0) revert ClaimAmountZero();
        _burn(_msgSender(), _id, _amount);
        if (_amount == 1) SANWORN.mint(_msgSender(), _id);
        else {
            (uint256[] memory ids, uint256[] memory amounts) = ArrayUtils._toSingletonArrays(_id, _amount);
            SANWORN.mintBatch(_msgSender(), ids, amounts);
        }
    }

    function claimBatch(
        uint256[] memory _ids,
        uint256[] memory _amounts
    )
        external
    {
        if (address(SANWORN) == address(0)) revert ClaimInactive();
        _burnBatch(_msgSender(), _ids, _amounts);
        SANWORN.mintBatch(_msgSender(), _ids, _amounts);
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    )
        external
        onlyRole(MINTER_ROLE)
    {
        if (_id == 0) revert InvalidTokenId();
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    )
        public
        onlyRole(MINTER_ROLE)
    {
        for (uint i; i < _ids.length; ++i) {
            if (_ids[i] == 0) revert InvalidTokenId();
        }
        _mintBatch(_to, _ids, _amounts, "");
    }

    function mintBatches(
        address[] calldata _tos,
        uint256[][] calldata _ids,
        uint256[][] calldata _amounts
    )
        external
        onlyRole(MINTER_ROLE)
    {
        uint256 numTos = _tos.length;
        for (uint i; i < numTos; ++i) {
            mintBatch(_tos[i], _ids[i], _amounts[i]);
        }
    }

    function setSanworn(
        address _sanworn
    )
        external
        onlyOwner
    {
        SANWORN = ISANWORN(_sanworn);
    }

    function setContractURI(string calldata _newContractURI)
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    function setTokenURI(
        uint256 _tokenId,
        string calldata _tokenURI
    )
        external
        onlyOwner
    {
        _setURI(_tokenId, _tokenURI);
    }

    function setTokenURIBatch(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    )
        external
        onlyOwner
    {
        if (_tokenIds.length != _tokenURIs.length) revert ArrayLengthMismatch();
        for (uint i; i < _tokenIds.length; ++i) {
            _setURI(_tokenIds[i], _tokenURIs[i]);
        }
    }

    function setTokenBaseURI(
        string calldata _tokenBaseURI
    )
        external
        onlyOwner
    {
        _setBaseURI(_tokenBaseURI);
    }

    function setURI(
        string calldata _newURI
    )
        external
        onlyOwner
    {
        _setURI(_newURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
