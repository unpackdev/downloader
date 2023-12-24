//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ITurboNFT.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./ERC2981.sol";

contract TurboNFT is ITurboNFT, ERC721Enumerable, ERC2981 {
    address private immutable minter;
    uint256 public currentId;
    string public URIPrefix;
    string public URISuffix;
    address private uriEditor;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _URIPrefix,
        string memory _URISuffix, 
        address _uriEditor,
		address feeReceiver
    ) ERC721(name_, symbol_) {
        URIPrefix = _URIPrefix;
        URISuffix = _URISuffix;
        minter = msg.sender;
        uriEditor = _uriEditor;
		_setDefaultRoyalty(feeReceiver, 300);
    }

    function drop(address receiver) external override {
        require(msg.sender == minter);
        _safeMint(receiver, currentId++);
    }

    function setTokenURIParts(
        string memory _URIPrefix,
        string memory _URISuffix
    ) public {
        require(msg.sender == uriEditor);    
        URIPrefix = _URIPrefix;
        URISuffix = _URISuffix;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        _requireOwned(_tokenId);
        return string.concat(URIPrefix, Strings.toString(_tokenId), URISuffix);
    }

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }
}
