// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Vanguard is ERC721Pausable, AccessControlEnumerable, ReentrancyGuard {
    using Strings for uint256;

    string internal baseURI;
    address public boxContractAddress;

    constructor() ERC721("Seedworld Vanguards", "Seedworld Vanguards") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setBaseURI(
        string calldata uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function setBoxContractAddress(
        address contractAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        boxContractAddress = contractAddress;
    }

    function openBox(
        address to,
        uint256 boxId
    ) external virtual returns (uint256) {
        require(
            _msgSender() == boxContractAddress,
            "Only box contract allowed to call"
        );
        _safeMint(to, boxId);
        return boxId;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId);
    }
}
