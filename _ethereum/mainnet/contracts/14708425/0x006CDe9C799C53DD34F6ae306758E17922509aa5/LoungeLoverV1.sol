// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./PausableUpgradeable.sol";

import "./StringsUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract LoungeLoversV1 is Initializable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _mintsAmount;

    bool public isSaleActive;
    uint256 private batchMints;
    uint256 public totalTokens;
    uint256 public mintingPrice;
    uint256 public mintPerUser;
    string private baseTokenURI;
    string private baseMetaDataExtension;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("LoungeLovers", "LL-NFT");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        isSaleActive = true;
        batchMints = 20;
        totalTokens = 100;
        mintingPrice = 0.17 ether;
        mintPerUser = 3;
        baseTokenURI = "https://ipfs.io/ipfs/QmfMv9eqcPaKyj9hN84EabaFFwJ3ESTXBxoeZcuFwnAre2/";
        baseMetaDataExtension = ".json";
    }

    function mint(uint256 _amount) external payable {
        require(isSaleActive, "Contract Error: Sale Not Active, Try Again Later!");
        require(_amount > 0, "Contract Error: You Need To Mint Atleast 1 Nft");
        require(totalTokens >= _amount + _tokenIds.current(), "Contract Error: Not Enough Tokens, Contact Developer!");
        require(_mintsAmount.current() + _amount  <= batchMints, "Contract Error: Not Enough Supply, Contact Developer!");
        require(msg.value >= mintingPrice * _amount, "Contract Error: Not Enough Ether, Please Purchase More!");
        //require(balanceOf(msg.sender) <= mintPerUser, "Contract Error: User Cannot Buy That Amount");
        require(balanceOf(msg.sender) + _amount <= mintPerUser, "Contract Error: User Has Execded Nft Limit");

        for(uint256 i = 0; i < _amount; i++){
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
            _mintsAmount.increment();
        }

        if (_mintsAmount.current() == batchMints) 
        {   
            isSaleActive = false;
            _mintsAmount.reset();
        }
    }

    function credit() pure external returns (string memory) {
        return "Ghandy#3880, Riannater1234#0001 - Blockchain developer V1";
    }

    function version() pure external returns (string memory) {
        return "v1";
    }

    // Owners functions
    function batchMintsSoFar() external view onlyOwner returns (uint256) {
        return _mintsAmount.current();
    }

    function mintsSoFar() external view onlyOwner returns (uint256) {
        return _tokenIds.current();
    }
   
    function startSale (bool _state) external onlyOwner {
        isSaleActive = _state;
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unPauseContract() external onlyOwner {
        _unpause();
    }

    function setMintingPrice (uint256 _newPrice) external onlyOwner {
        mintingPrice = _newPrice;
    }

    function setBatchMintsPerSale(uint256 _newBatch) external onlyOwner {
        require((totalTokens - totalSupply()) >= _newBatch, "Contract Error: Not Enough Tokens For Provided Batch Mints");
        batchMints = _newBatch;
    }

    function setMaxTokens(uint256 _newMax) external onlyOwner {
        totalTokens = _newMax;
    }

    function setMaxMintsPerUser (uint256 _newMax) external onlyOwner {
        require(totalTokens >= _newMax, "Contract Error: Not Enough Tokens For Selected Mints Amount Per User");
        require(batchMints >= _newMax, "Contract Error: User Will Be Unable To Mint That Much Due To The Amount Selected For BatchMints Per Sale");
        mintPerUser = _newMax;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseMetaDataExtension = _newBaseExtension;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Contract Error: Balance Is Empty!");
        payable(msg.sender).transfer(balance);
    }
    
    //overrides
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
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
            "Contract Error: Metadata URI Query For Nonexistent Token"
        );
        

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, StringsUpgradeable.toString(tokenId), baseMetaDataExtension))
            : "";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}