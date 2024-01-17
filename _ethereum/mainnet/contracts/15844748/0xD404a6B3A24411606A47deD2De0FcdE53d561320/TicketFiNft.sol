//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract TicketFi is Ownable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    string public baseTokenURI;
    mapping(uint256 => string) tokenName;
    address minter;
    Counters.Counter private _tokenIdTracker;

    constructor(
        address _ownerAddress,
        string memory _baseURIInput,
        address _minter
    ) ERC721("TicketFi", "TKF") {
        setBaseURI(_baseURIInput);
        minter = _minter;
        _transferOwnership(_ownerAddress);
    }

    /* Owner features */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /* User functions*/
    function getCurrentIndex() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function getBaseURI() external view returns (string memory) {
        return _baseURI();
    }

    function tokensOf(address _owner) external view returns (uint256[] memory) {
        uint256 numTokens = balanceOf(_owner);
        uint256[] memory tokens = new uint256[](numTokens);
        uint256 idx = 0;
        for (uint256 i = 0; i < numTokens; i++) {
            tokens[idx] = tokenOfOwnerByIndex(_owner, i);
            idx++;
        }
        return tokens;
    }

    function mint(
        uint256 tokenId,
        string memory name,
        bytes memory signature
    ) external whenNotPaused {
        // This recreates the message that was signed on the client.
        require(!_exists(tokenId), "TicketFi: can not mint existent token");
        bytes32 rawHash = keccak256(
            abi.encodePacked(msg.sender, tokenId, name)
        );

        bytes32 prefixHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", rawHash)
        );

        address signer = prefixHash.recover(signature);

        require(signer == minter, "TicketFi: not correct signer");

        _mint(msg.sender, tokenId);
        tokenName[tokenId] = name;
        _tokenIdTracker.increment();
    }

    function batchTransfer(
        address[] memory _receivers,
        uint256[] memory _tokenIds
    ) external whenNotPaused returns (bool) {
        require(
            _receivers.length == _tokenIds.length,
            "TicketFi: mismatch input length"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];
            uint256 tokenId = _tokenIds[i];
            safeTransferFrom(_msgSender(), receiver, tokenId);
        }

        return true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "TicketFi: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, "/", tokenName[tokenId], ".json")
                )
                : "";
    }

    /* Override functions */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
