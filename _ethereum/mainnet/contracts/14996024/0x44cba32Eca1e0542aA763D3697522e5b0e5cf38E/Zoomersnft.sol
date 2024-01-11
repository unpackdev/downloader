// SPDX-License-Identifier: MIT

/// @title Zoomers contract
/// @author zhs team

pragma solidity ^0.8.6;
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Zoomersnft is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    bool public paused = true;
    bool public publicSale = false;

    bytes32 public OgMRoot;
    bytes32 public WlMRoot;

    Counters.Counter private IndexOfMint;

    string private _baseTokenURI;

    uint8 public maxMintAmountPerTx = 5;
    uint8 public maxPerWallet = 2;

    uint256 public cost = 0 ether;
    uint32 public totalSupply = 3333;

    mapping(address => uint8) public totalMintByUser;

    constructor() ERC721("Zoomersnft", "zhs") {}

    /// @dev modifer for mint conditions, which includes both public and whitelist sale.
    modifier mintConditions(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) {
        require(!paused, "Zoomers contract is paused!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount! should be greater than 0 and less than 6"
        );
        require(
            IndexOfMint.current() + _mintAmount <= totalSupply,
            "Not enough NFT left to mint!"
        );

        if (!publicSale) {
            if (
                MerkleProof.verify(
                    _merkleProof,
                    OgMRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            ) {
                require(
                    totalMintByUser[msg.sender] + _mintAmount <= 5,
                    "OG cannot hold or mint more than 5  NFT in presale"
                );
            } else if (
                MerkleProof.verify(
                    _merkleProof,
                    WlMRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            ) {
                require(
                    totalMintByUser[msg.sender] + _mintAmount <= 3,
                    "Zhs Whitelist cannot hold or mint more than 3  NFT in presale"
                );
            } else {
                revert(
                    "You are not in Zoomers OG or WL please wait for public sale to start"
                );
            }
        }
        _;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setPublicState(bool _state) external onlyOwner {
        publicSale = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOgMRoot(bytes32 _OgMRoot) external onlyOwner {
        OgMRoot = _OgMRoot;
    }

    function setWlMRoot(bytes32 _WlMRoot) external onlyOwner {
        WlMRoot = _WlMRoot;
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintConditions(_mintAmount, _merkleProof)
    {
        _mintLoop(msg.sender, _mintAmount);
    }

    /// @notice n nfts reserved for future marketing campagins
    function devMint(uint256 _mintAmount) external onlyOwner {
        _mintLoop(msg.sender, _mintAmount);
    }

    function _mintLoop(address _receiver, uint256 _mintquantity) internal {
        for (uint256 i = 0; i < _mintquantity; i++) {
            IndexOfMint.increment();
            _safeMint(_receiver, IndexOfMint.current());
            totalMintByUser[_receiver]++;
        }
    }

    function totalMinted() public view returns (uint256) {
        return IndexOfMint.current();
    }

    /// @dev walletofOwner - IRC721 over written to save some gas.
    /// @return tokens id owned by the given address

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
