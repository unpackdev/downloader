// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/********************
 * @author: Techoshi.eth *
        <(^_^)>
 ********************/

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./ERC721URIStorage.sol";

contract MissingTooth is Ownable, ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;

    Counters.Counter private _tokenSupply;

    uint256 public constant MAX_TOKENS = 500;
    uint256 public mTL = 20;
    uint256 public whitelistmTL = 20;
    uint256 public tokenPrice = 0.045 ether;
    uint256 public whitelistTokenPrice = 0.045 ether;
    uint256 public maxWhiteListMints = 500;


    bool public publicMintIsOpen  = false;
    bool public whitelistMintIsOpen = true;
    bool public revealed = false;

    string _baseTokenURI;
    string public Author = "Techoshi.eth";
    string public baseExtension = ".json";
    string public hiddenMetadataUri;

    address private _Uno = 0x0000000000000000000000000000000000000000;
    address private _Duece = 0x0000000000000000000000000000000000000000;
    address private _Vault = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) whitelistedAddresses;   

    modifier isGuest(address _address, bytes32 _hash) {
        bool decoy = keccak256(abi.encodePacked("<(^_^)>")) !=
            keccak256(
                abi.encodePacked(
                    "If you want to help grow this project and you can get around the gate go for it. ~Techoshi"
                )
            );

        if (_hash.length > 0) {
            require(
                true,
                "I'm just wasting your time. We did this offline. ~Techoshi"
            );
        }
        _;
    }

    modifier whitelistMissingToothCompliance(
        bool flip,
        bytes32 hash,
        bytes memory signature,
        bytes32 hash2,
        bytes memory signature2
    ) {
        require(whitelistMintIsOpen, "Pre-Sale is not Open");

        require(
            matchMessage(
                flip,
                flip ? hash : hash2,
                flip ? signature : signature2
            ),
            "Direct mint now allowed"
        );
        _;
    }

    constructor(
        address firstAddy,
        address secondAddy,
        address _vault,
        string memory __baseTokenURI,
        string memory _hiddenMetadataUri
    ) ERC721("Missing Tooth NFT", "MTNFT") {
        _Vault = _vault;
        _Uno = firstAddy;
        _Duece = secondAddy;
        _tokenSupply.increment();
        _tokenSupply.increment();
        _safeMint(msg.sender, 1);
        _baseTokenURI = __baseTokenURI;
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function withdraw() external onlyOwner {
        payable(_Vault).transfer(address(this).balance);
    }

    function whitelistMissingToothMint(
        bool mH,
        bytes32 mOne,
        bytes memory mTwo,
        bytes32 mThree,
        bytes32 mFour,
        bytes memory mFive,
        uint256 amount
    )
        external
        payable
        whitelistMissingToothCompliance(mH, mOne, mTwo, mFour, mFive)        
        isGuest(msg.sender, mThree)
    {
        uint256 supply = _tokenSupply.current();

        require(supply + amount <= MAX_TOKENS, "Not enough tokens remaining");
        require(supply + amount <= maxWhiteListMints,"Not enough free mints remaining");
        require(whitelistTokenPrice * amount <= msg.value,"Not enough ether sent");
        require(amount <= whitelistmTL, "Mint amount too large");

        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function publicMissingToothMint(
        uint256 a
    )
        external
        payable
    {
        uint256 supply = _tokenSupply.current();

        require(a <= mTL, "Mint amount too large");
        require(supply + a <= MAX_TOKENS, "Not enough tokens remaining");
        require(tokenPrice * a <= msg.value, "Not enough ether sent");

        for (uint256 i = 0; i < a; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function adminMint(address to, uint256 amount) external onlyOwner {
        uint256 supply = _tokenSupply.current();
        require(supply + amount <= MAX_TOKENS, "Not enough tokens remaining");
        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(to, supply + i);
        }
    }

    function setParams(
        uint256 newPrice,
        uint256 newWhitelistTokenPrice,
        uint256 setpublicMissingToothMintLimit,
        uint256 setwhitelistMissingToothMintLimit,
        bool setPublicMintState,
        bool setWhitelistMintState
    ) external onlyOwner {
        whitelistTokenPrice = newWhitelistTokenPrice;
        tokenPrice = newPrice;
        mTL = setpublicMissingToothMintLimit;
        whitelistmTL = setwhitelistMissingToothMintLimit;
        publicMintIsOpen = setPublicMintState;
        whitelistMintIsOpen = setWhitelistMintState;
    }

    function setTransactionMintLimit(uint256 newMintLimit) external onlyOwner {
        mTL = newMintLimit;
    }

    function setWhitelistTransactionMintLimit(uint256 newWhitelistMintLimit)
        external
        onlyOwner
    {
        whitelistmTL = newWhitelistMintLimit;
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function setFreeMints(uint256 amount) external onlyOwner {
        require(amount <= MAX_TOKENS, "Free mint amount too large");
        maxWhiteListMints = amount;
    }

    function togglePublicMint() external onlyOwner {
        publicMintIsOpen = !publicMintIsOpen;
    }

    function toggleWhitelistMint() external onlyOwner {
        whitelistMintIsOpen = !whitelistMintIsOpen;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current() - 1;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setVaultAddress(address newVault) external onlyOwner {
        _Vault = newVault;
    }

    function setSignerAddress(address newSigner, address newSigner2)
        external
        onlyOwner
    {
        _Uno = newSigner;
        _Duece = newSigner2;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    receive() external payable {}

    function matchMessage(
        bool flip,
        bytes32 hash,
        bytes memory signature
    ) private view returns (bool) {
        address hashAddy = hash.toEthSignedMessageHash().recover(signature);

        bool firstCheck = (flip && address(_Uno) == address(hashAddy));
        bool secondCheck = (!flip && address(_Duece) == address(hashAddy));

        bool returnResult = flip ? firstCheck : secondCheck;

        return returnResult;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }
}
