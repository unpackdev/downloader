// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IFactory.sol";

contract ERC1155Instance is ERC1155Supply, ERC1155Burnable, ReentrancyGuard {

    IFactory public factory;

    string public name;
    string public symbol;

    uint256 public totalIDs;

    mapping(uint256 => bool) public mintIDUsed;

    mapping(uint256 => string) private _tokenURIs;

    event Mint(uint256 mintID, uint256 tokenID, uint256 amount, address sender);

    constructor(string memory _name, string memory _symbol) ERC1155("https://ipfs.io/ipfs/") {
        name = _name;
        symbol = _symbol;
        factory = IFactory(_msgSender());
    }

    function mint(uint256 mintID, uint256 amount, string calldata _tokenURI, uint256 deadline, bytes calldata signature) external nonReentrant {
        require(factory.signer() == ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(block.chainid, mintID, _msgSender(), address(this), amount, _tokenURI, deadline))), signature), "Invalid signature");
        require(deadline >= block.timestamp, "Deadline passed");
        require(!mintIDUsed[mintID], "Mint ID already used");
        mintIDUsed[mintID] = true;
        _tokenURIs[totalIDs] = _tokenURI;
        _mint(_msgSender(), totalIDs, amount, "");
        emit Mint(mintID, totalIDs, amount, _msgSender());
        totalIDs++;
    }

    function uri(uint256 tokenId) public view virtual override returns(string memory) {
        require(exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = super.uri(tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.uri(tokenId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}