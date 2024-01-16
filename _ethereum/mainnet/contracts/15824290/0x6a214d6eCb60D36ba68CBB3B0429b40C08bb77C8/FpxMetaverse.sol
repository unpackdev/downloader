// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

contract FpxMetaverse is ERC721A, Ownable, Pausable {
    
    string public baseTokenURI;
    string public defaultTokenURI;
    uint256 public maxSupply = 2019;
    
    uint256 public publicMintPrice = 10 ** 16;
    mapping(address => bool) public publicMintResult;

    constructor(
        string memory _baseTokenURI,
        string memory _defaultTokenURI
    ) ERC721A("FpxMetaverseX", "FPX") {
        baseTokenURI = _baseTokenURI;
        defaultTokenURI = _defaultTokenURI;
        _pause();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint() external payable callerIsUser whenNotPaused {
        require(totalSupply() + 1 <= maxSupply, "Exceed supply");
        require(msg.value >= publicMintPrice, "Value not enough");
        require(
            !publicMintResult[msg.sender],
            "This address has finished public mint"
        );
        publicMintResult[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function airdrop(address[] calldata recipients) external onlyOwner {
        require(totalSupply() + recipients.length <= maxSupply, "Exceed supply");
        for (uint i=0; i<recipients.length; i++) {
            _safeMint(recipients[i], 1);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setPublicMintPrice(uint256 _price) external onlyOwner {
        publicMintPrice = _price;
    }

    function withdraw(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}
