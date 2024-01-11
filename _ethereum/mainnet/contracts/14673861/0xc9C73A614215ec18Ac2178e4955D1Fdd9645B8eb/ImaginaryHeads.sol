// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC2981Base.sol";

contract ImaginaryHeads is ERC721Enumerable, ERC2981Base, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_MINT_AMOUNT_TX = 10;
    uint256 public constant MAX_AMOUNT_PER_ADDR = 20;
    // ROYALTIES_FACTOR / 1000 provides the final 
    // percentage of royalties
    // Check royaltyInfo() function.
    uint256 public constant ROYALTIES_FACTOR = 75;
    string public constant BASE_EXTENSION = ".json";

    string public baseURI;
    uint256 public maxSupply;
    bool public mintActive = false;
    bool public revealed = false;

    address private royaltiesReceiver;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedUri,
        uint256 _maxSupply,
        address _royaltiesReceiver
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        setBaseURI(_notRevealedUri);
        setRoyaltiesReceiver(_royaltiesReceiver);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _mintAmount(uint256 _amount) internal {
        require(mintActive, "minting not active");
        require(_amount > 0, "need to mint at least 1 NFT");
        require(
            _amount <= MAX_MINT_AMOUNT_TX,
            "max mint amount per tx exceeded"
        );
        uint256 ownerTokenCount = balanceOf(msg.sender);
        require(
            ownerTokenCount + _amount <= MAX_AMOUNT_PER_ADDR,
            "max amount per address exceeded"
        );
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply, "max supply exceeded");

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // public
    function mint(uint256 _amount) external {
        _mintAmount(_amount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory uri = _baseURI();
        if (revealed) {
            return
                bytes(uri).length > 0
                    ? string(
                        abi.encodePacked(
                            uri,
                            _tokenId.toString(),
                            BASE_EXTENSION
                        )
                    )
                    : "";
        }
        return uri;
    }

    function royaltyInfo(uint256, uint256 _value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltiesReceiver;
        royaltyAmount = (_value * ROYALTIES_FACTOR) / 1000;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintActive(bool _state) external onlyOwner {
        mintActive = _state;
    }

    function setRoyaltiesReceiver(address _receiver) public onlyOwner {
        royaltiesReceiver = _receiver;
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "failed to send funds to owner");
    }
}
