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
import "./PaymentSplitter.sol";


contract TheMonsterCommunity is Ownable, ERC721, ERC721URIStorage, PaymentSplitter {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;

    struct user {
        address userAddress;
        uint8 entries;
        bool isExist;
    }
    // mapping(address => user) public giveAwayAllowance;
    // mapping(address => uint256) public giveAwayMints;
    // uint16 public remainingReserved;

    Counters.Counter private _tokenSupply;
    Counters.Counter private _freeSupply;

    uint256 public constant MAX_TOKENS = 3333;
    uint256 public publicMintMaxLimit = 50;
    uint256 public whitelistMintMaxLimit = 50;
    uint256 public tokenPrice = 0.05 ether;
    uint256 public whitelistTokenPrice = 0.0 ether;
    uint256 public maxAfterHoursMonsterMints = 900;

    bool public publicMintIsOpen = false;
    bool public privateMintIsOpen = true;
    bool public revealed = false;

    string _baseTokenURI;
    string public baseExtension = ".json";
    string public hiddenMetadataUri;

    address private _MonsterVault = 0x0000000000000000000000000000000000000000;
    address private _MonsterSigner = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) whitelistedAddresses;

    string public Author = "techoshi.eth";
    string public MonsterTeam = "kuma420.eth, samadoption.eth, softich.eth";

    struct MonsterPass {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function _isVerifiedMonsterPass(
        bytes32 digest,
        MonsterPass memory monsterPass
    ) internal view returns (bool) {
        address signer = ecrecover(
            digest,
            monsterPass.v,
            monsterPass.r,
            monsterPass.s
        );

        require(signer != address(0), "ECDSA: invalid signature");
        return signer == _MonsterSigner;
    }

    modifier isWhitelisted(uint8 amount, MonsterPass memory monsterPass) {
        bytes32 digest = keccak256(
            abi.encode(amount, msg.sender)
        );

        require(
            _isVerifiedMonsterPass(digest, monsterPass),
            "Invalid Monster Pass"
        ); // 4
        _;
    }

    constructor(
        address _vault,
        address _signer,
        string memory __baseTokenURI,
        string memory _hiddenMetadataUri,
        address[] memory _payees, uint256[] memory _shares
    ) ERC721("The Monster Community", "TMC")  PaymentSplitter(_payees, _shares) payable {
        _MonsterVault = _vault;
        _MonsterSigner = _signer;
        _tokenSupply.increment();
        _tokenSupply.increment();
        _safeMint(msg.sender, 1);
        _baseTokenURI = __baseTokenURI;
        hiddenMetadataUri = _hiddenMetadataUri;
        
    }
   
    function updateSplitter(address[] memory _payees, uint256[] memory _shares) external onlyOwner {
        //PaymentSplitter(_payees, _shares);
    }
    
    function withdraw() external onlyOwner {
        payable(_MonsterVault).transfer(address(this).balance);
    }

    function afterHoursMonsterMint(
        uint8 quantity, //Whitelist,
        uint8 claimable,
        MonsterPass memory monsterPass
    ) external payable isWhitelisted(claimable, monsterPass) {
        require(
            whitelistTokenPrice * quantity <= msg.value,
            "Not enough ether sent"
        );

        uint256 supply = _tokenSupply.current();        

        require(privateMintIsOpen == true, "Claim Mint Closed");
        require(quantity + (supply-1) <= MAX_TOKENS, "Not enough tokens remaining");
        require(quantity <= claimable, "Mint quantity can't be greater than claimable");
        require(quantity > 0, "Mint quantity must be greater than zero");
        require(quantity <= whitelistMintMaxLimit, "Mint quantity too large");
        require(
            _freeSupply.current() + quantity <= maxAfterHoursMonsterMints,
            "Not enough free mints remaining"
        );

        // giveAwayMints[msg.sender] += quantity;        

        for (uint256 i = 0; i < quantity; i++) {
            _tokenSupply.increment();
            _freeSupply.increment();
            _safeMint(msg.sender, supply + i);
        }

    }

    function openMonsterMint(uint256 quantity) external payable {
        require(tokenPrice * quantity <= msg.value, "Not enough ether sent");
        uint256 supply = _tokenSupply.current();
        require(publicMintIsOpen == true, "Public Mint Closed");
        require(quantity <= publicMintMaxLimit, "Mint amount too large");
        require(quantity + (supply-1) <= MAX_TOKENS, "Not enough tokens remaining");

        for (uint256 i = 0; i < quantity; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function monsterMint(address to, uint256 amount) external onlyOwner {
        uint256 supply = _tokenSupply.current();
        require((supply-1) + amount <= MAX_TOKENS, "Not enough tokens remaining");
        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(to, supply + i);
        }
    }

    function setParams(
        uint256 newPrice,
        uint256 newWhitelistTokenPrice,
        uint256 setopenMonsterMintLimit,
        uint256 setafterHoursMonsterMintLimit,
        bool setPublicMintState,
        bool setPrivateMintState
    ) external onlyOwner {
        whitelistTokenPrice = newWhitelistTokenPrice;
        tokenPrice = newPrice;
        publicMintMaxLimit = setopenMonsterMintLimit;
        whitelistMintMaxLimit = setafterHoursMonsterMintLimit;
        publicMintIsOpen = setPublicMintState;
        privateMintIsOpen = setPrivateMintState;
    }

    function setTransactionMintLimit(uint256 newMintLimit) external onlyOwner {
        publicMintMaxLimit = newMintLimit;
    }

    function setWhitelistTransactionMintLimit(uint256 newprivateMintLimit)
        external
        onlyOwner
    {
        whitelistMintMaxLimit = newprivateMintLimit;
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function setFreeMints(uint256 amount) external onlyOwner {
        require(amount <= MAX_TOKENS, "Free mint amount too large");
        maxAfterHoursMonsterMints = amount;
    }

    function togglePublicMint() external onlyOwner {
        publicMintIsOpen = !publicMintIsOpen;
    }

    function togglePresaleMint() external onlyOwner {
        privateMintIsOpen = !privateMintIsOpen;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current() - 1;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setVaultAddress(address newVault) external onlyOwner {
        _MonsterVault = newVault;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    //receive() external payable {}

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

    function setSignerAddress(address newSigner) external onlyOwner {
        _MonsterSigner = newSigner;
    }


}
