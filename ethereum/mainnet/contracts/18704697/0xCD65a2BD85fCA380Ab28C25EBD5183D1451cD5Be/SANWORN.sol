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
 *                   ██╗    ██╗ ██████╗ ██████╗ ███╗   ██╗
 *                   ██║    ██║██╔═══██╗██╔══██╗████╗  ██║
 *                   ██║ █╗ ██║██║   ██║██████╔╝██╔██╗ ██║
 *                   ██║███╗██║██║   ██║██╔══██╗██║╚██╗██║
 *                   ╚███╔███╔╝╚██████╔╝██║  ██║██║ ╚████║
 *                    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
 */

import "./ERC721MintboundPartitioned.sol";
import "./Ownable.sol";
import "./ISANWORN.sol";

/**
 * @title SANWEAR™ by SAN SOUND (Claimed)
 * @author Aaron Hanson <coffee.becomes.code@gmail.com> @CoffeeConverter
 * @notice https://sansound.io/
 */
contract SANWORN is Ownable, ERC721MintboundPartitioned, ISANWORN {
    address public immutable SANWEAR_ADDR;
    string public contractURI;

    constructor(
        string memory _baseUri,
        string memory _contractUri,
        address _sanwear
    )
        ERC721MintboundPartitioned("SANWEAR by SAN SOUND (Claimed)", "SANWORN", 1_000)
        Ownable(_msgSender())
    {
        _setBaseURI(_baseUri);
        contractURI = _contractUri;
        SANWEAR_ADDR = _sanwear;
    }

    function mint(
        address _to,
        uint256 _colorwayId
    )
        external
    {
        if (_msgSender() != SANWEAR_ADDR) revert CallerIsNotSanwear();
        _mint(_to, _colorwayId, 1);
    }

    function mintBatch(
        address _to,
        uint256[] calldata _colorwayIds,
        uint256[] calldata _amounts
    )
        external
    {
        if (_msgSender() != SANWEAR_ADDR) revert CallerIsNotSanwear();
        if (_colorwayIds.length != _amounts.length) revert ArrayLengthMismatch();
        _mintBatch(_to, _colorwayIds, _amounts);
    }

    function setContractURI(string calldata _newContractURI)
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    function setBaseURI(
        string calldata _newBaseUri
    )
        external
        onlyOwner
    {
        _setBaseURI(_newBaseUri);
    }
}
