// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *   .oooooo.                                       .             oooo   o8o
 *  d8P'  `Y8b                                    .o8             `888   `"'
 * 888          oooo d8b oooo    ooo oo.ooooo.  .o888oo  .ooooo.   888  oooo   .oooooooo  .oooo.
 * 888          `888""8P  `88.  .8'   888' `88b   888   d88' `88b  888  `888  888' `88b  `P  )88b
 * 888           888       `88..8'    888   888   888   888   888  888   888  888   888   .oP"888
 * `88b    ooo   888        `888'     888   888   888 . 888   888  888   888  `88bod8P'  d8(  888
 *  `Y8bood8P'  d888b        .8'      888bod8P'   "888" `Y8bod8P' o888o o888o `8oooooo.  `Y888""8o
 *                       .o..P'       888                                     d"     YD
 *                       `Y8P'       o888o                                    "Y88888P'
 *
 * @title Cryptoliga
 * @author Peter Smith
 *
 **/

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./CryptoligaFX.sol";
import "./CryptoligaWL.sol";

contract Cryptoliga is
    ERC2981,
    ERC721,
    Pausable,
    AccessControl,
    CryptoligaFX,
    CryptoligaWL
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 private root;

    using Strings for uint256;

    string public ContractURI;
    string public baseURI;
    uint256 public maxBatchSize;

    uint16[] private wlAllowances;

    enum Stages {
        CLOSED,
        PUBLIC,
        PRIVATE,
        PRESALE
    }

    struct MintAllowed {
        bool native;
        bool fx;
        bool whitelist;
    }

    MintAllowed private mintAllowed;

    Stages public saleStage;
    uint256 public maxSupply;
    uint256 public mintPrice = 0.222 ether;
    uint256 public presalePrice = 0.1776 ether;
    address public owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256[]) private userMints;

    event StageChanged(Stages stage);

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyWallet,
        uint96 _royaltyRate,
        string memory _URI,
        string memory _contractURI,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _royaltyWallet);
        owner = msg.sender;
        _setDefaultRoyalty(_royaltyWallet, _royaltyRate);
        maxBatchSize = 10;
        ContractURI = _contractURI;
        baseURI = _URI;
        maxSupply = _maxSupply;
        wlAllowances = [0, 10, 10, 10, 10];
        mintAllowed = MintAllowed(false, false, false);
        saleStage = Stages.CLOSED;
    }

    function setRoot(bytes32 _root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoot(_root);
    }

    function setMintPrice(uint256 _price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintPrice = _price;
    }

    function setMaxSupply(uint256 _maxSupply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxSupply = _maxSupply;
    }

    function setMaxBatchSize(uint256 _maxBatchSize)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxBatchSize = _maxBatchSize;
    }

    function setPresalePrice(uint256 _price)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        presalePrice = _price;
    }

    function setWlAllowance(uint _stage, uint16 _allowance)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        wlAllowances[_stage] = _allowance;
    }

    /***
     * @dev Returns the number of tokens remainnig in the current stage.
     * @param to address The address to check
     */
    function wlAllowancesLeft(address to) internal view returns (uint256) {
        if (maxBatchSize == 0) {
            return maxSupply > totalSupply() ? maxSupply - totalSupply() : 0;
        }

        if (userMints[to].length == 0) {
            return wlAllowances[uint(saleStage)];
        }

        return
            wlAllowances[uint(saleStage)] > userMints[to][uint(saleStage)]
                ? wlAllowances[uint(saleStage)] - userMints[to][uint(saleStage)]
                : 0;
    }

    function getSaleInfo(address minter)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            uint(saleStage),
            saleStage == Stages.PUBLIC ? mintPrice : presalePrice,
            saleStage == Stages.CLOSED || minter == address(0)
                ? 0
                : wlAllowancesLeft(minter),
            totalSupply(),
            maxSupply
        );
    }

    function setStage(uint8 _stage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(Stages(_stage) != saleStage, "StageNotChanged");

        saleStage = Stages(_stage);

        if (saleStage == Stages.PUBLIC) {
            mintAllowed = MintAllowed(true, true, false);
        } else if (saleStage > Stages.PUBLIC) {
            mintAllowed = MintAllowed(false, false, true);
        } else {
            mintAllowed = MintAllowed(false, false, false);
        }

        emit StageChanged(Stages(_stage));
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function whitelistMint(
        address to,
        uint64 quantity,
        bytes32[] calldata _merkleProof
    ) external payable whenNotPaused {
        require(mintAllowed.whitelist, "CantMintWL");

        require(okToMint(to, quantity), "NotOK");

        require(_checkValidity(_merkleProof), "NotWL");

        require(msg.value >= quantity * presalePrice, "NoETH");

        _safeMint(to, quantity);
    }

    function fxMint(
        address to,
        uint256 quantity,
        string memory coinSymbol
    ) external {
        require(mintAllowed.fx, "CantMintFX");
        require(okToMint(to, quantity), "NotOK");

        _fxPurchase(quantity, coinSymbol);
        _safeMint(to, quantity);
    }

    function nativeMint(address to, uint64 quantity)
        external
        payable
        whenNotPaused
    {
        require(mintAllowed.native, "CantMintNative");
        require(okToMint(to, quantity), "NotOK");
        require(msg.value >= quantity * mintPrice, "NoETH");
        _safeMint(to, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // enable withdrawal of funds
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory _URI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _URI;
    }

    // for Opensea
    function contractURI() external view returns (string memory) {
        return ContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function okToMint(address _to, uint256 _numberToMint)
        internal
        view
        returns (bool)
    {
        require(
            maxBatchSize == 0 ||
                (maxBatchSize > 0 && _numberToMint <= maxBatchSize),
            "BatchTooBig"
        );

        require(totalSupply() + _numberToMint <= maxSupply, "SoldOut");

        require(
            (userMints[_to].length == 0) ||
                userMints[_to][uint(saleStage)] + _numberToMint <=
                wlAllowances[uint(saleStage)],
            "OverWLAllowance"
        );

        return true;
    }

    function safeMint(address to, uint256 quantity)
        external
        onlyRole(MINTER_ROLE)
    {
        _safeMint(to, quantity);
    }

    function _safeMint(address to, uint256 quantity) internal override {
        if (maxBatchSize > 0 && !hasRole(MINTER_ROLE, msg.sender)) {
            // user minting
            if (userMints[to].length == 0) {
                userMints[to] = [0, 0, 0, 0];
            }

            uint _stage = uint(saleStage);
            userMints[to][_stage] += quantity;
        }

        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            super._safeMint(to, tokenId);
        }
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setOwner(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        owner = newOwner;
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function addCoin(
        string memory _coinSymbol,
        address _coinAddress,
        uint256 _coinPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addCoin(_coinSymbol, _coinAddress, _coinPrice);
    }

    function setCoinPrice(string memory _coinSymbol, uint256 _coinPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setCoinPrice(_coinSymbol, _coinPrice);
    }

    function getCoinPrice(string memory _coinSymbol)
        external
        view
        returns (uint256)
    {
        return _getCoinPrice(_coinSymbol);
    }

    function removeCoin(string memory _coinSymbol)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _removeCoin(_coinSymbol);
    }

    function withdrawCoin(string memory _symbol)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _withdrawCoin(_symbol);
    }
}
