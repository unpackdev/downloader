//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./IERC721A.sol";

contract CTC_ERC721A is IERC721A, ERC2981ContractWideRoyalties, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public maxSupply = 5555;
    bool public paused = false;
    bool public revealed = false;

    bytes32 public whiteListMerkleRoot;
    bool public whiteListMintOpened = true;
    uint256 public whiteListPrice = 0 ether;
    mapping(address => uint256) public whiteListBalanceMap;
    mapping(address => uint256) public publicSaleBalanceMap;

    bool public isPublicSaleOpened = false;
    uint256 public publicSaleCost = 0.05 ether;

    function mint(
        uint256 mintAmount,
        bool isWhiteListMint,
        bytes32[] calldata proof
    ) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender == owner()) {
            whiteListBalanceMap[msg.sender] += mintAmount;
            _safeMint(msg.sender, mintAmount);
            return;
        }

        uint256 ownerMintedCount = whiteListBalanceMap[msg.sender];

        if (isWhiteListMint) {
            require(whiteListMintOpened, "white list mint closed");
            require(ownerMintedCount == 0, "white list already mint");

            // Verify merkle proof, or revert if not in tree
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintAmount));
            bool isValidLeaf = MerkleProof.verify(
                proof,
                whiteListMerkleRoot,
                leaf
            );
            require(isValidLeaf, "white list not validate");

            if (whiteListPrice != 0) {
                require(
                    msg.value >= whiteListPrice * mintAmount,
                    "insufficient funds for white list mint"
                );
            }

            whiteListBalanceMap[msg.sender] = mintAmount;
            _safeMint(msg.sender, mintAmount);
            return;
        }

        require(isPublicSaleOpened, "public sale not open yet");
        require(
            msg.value >= publicSaleCost * mintAmount,
            "insufficient funds for public sale mint"
        );
        publicSaleBalanceMap[msg.sender] += mintAmount;
        _safeMint(msg.sender, mintAmount);
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _baseURI,
        string memory _notRevealedUri
    ) IERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        baseURI = _baseURI;
        notRevealedUri = _notRevealedUri;
        _setRoyalties(msg.sender, 1);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function nftAdmin1(
        bytes32 _whiteListMerkleRoot,
        uint256 _whiteListPrice,
        uint256 _publicSaleCost,
        bool _whiteListMintOpened,
        bool _isPublicSaleOpened
    ) public onlyOwner {
        whiteListMerkleRoot = _whiteListMerkleRoot;
        whiteListPrice = _whiteListPrice;
        publicSaleCost = _publicSaleCost;
        whiteListMintOpened = _whiteListMintOpened;
        isPublicSaleOpened = _isPublicSaleOpened;
    }

    function nftAdmin2(
        string memory _baseURI,
        string memory _baseExtension,
        string memory _notRevealedUri,
        bool _paused,
        bool _revealed,
        address recipient,
        uint256 royaltyValue
    ) public onlyOwner {
        baseURI = _baseURI;
        baseExtension = _baseExtension;
        notRevealedUri = _notRevealedUri;
        paused = _paused;
        revealed = _revealed;
        _setRoyalties(recipient, royaltyValue);
    }

    function withdraw(address withdrawTo) public payable onlyOwner {
        (bool hs, ) = payable(withdrawTo).call{value: (address(this).balance)}(
            ""
        );
        require(hs);
    }
}
