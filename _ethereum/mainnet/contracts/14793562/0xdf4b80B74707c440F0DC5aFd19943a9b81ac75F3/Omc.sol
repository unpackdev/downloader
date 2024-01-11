//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./IOmc.sol";
import "./OMCLib.sol";

contract Omc is IOmc, ERC721 {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public omcEpoch;
    uint256 public totalSupply;
    uint256 public maxTotalSupply = 10000;
    bool public revealed;
    bool public publicMintEnabled;
    uint256 public _mintPrice;
    uint256 private _mintLimitPerUser;
    uint256 private _countLimitPerMint;
    uint256 private _mintStartBlock;
    uint256 private _antibotInterval;

    string private baseURI_;
    string private baseHiddenURI_;

    address private _owner;
    mapping(address => uint256) private _lastCallBlockNumber;

    modifier onlyOwner() {
        require(msg.sender == _owner, "ONLY OWNER");
        _;
    }

    constructor() ERC721("Ostrich Money Club", "OMC") {
        _owner = msg.sender;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function getTotalSupply() external view override returns (uint256) {
        return totalSupply;
    }

    function setOmcEpoch(address _newOmcEpoch) external override onlyOwner {
        omcEpoch = _newOmcEpoch;
    }

    function setBaseURI(string memory _newBaseURI)
        external
        override
        onlyOwner
    {
        baseURI_ = _newBaseURI;
    }

    function setHiddenURI(string memory _newBaseHiddenURI)
        external
        override
        onlyOwner
    {
        baseHiddenURI_ = _newBaseHiddenURI;
    }

    function setPublicMintEnabled(bool _state) external override onlyOwner {
        publicMintEnabled = _state;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function _hiddenURI() internal view returns (string memory) {
        return baseHiddenURI_;
    }

    function reveal(bool _state) external override onlyOwner {
        revealed = _state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NONEXSISTENT TOKEN");

        if (revealed == false) {
            string memory currentNotRevealedUri = _hiddenURI();
            return
                bytes(currentNotRevealedUri).length > 0
                    ? string(
                        abi.encodePacked(
                            currentNotRevealedUri,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function withdrawPayment() external override onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NOTHING TO WITHDRAW");
        require(omcEpoch != address(0), "OMC_EPOCH NOT SET");
        uint256 ownerStake = (balance * 9) / 10;
        IWETH(WETH).deposit{value: balance}();
        OMCLib._safeTransfer(WETH, _owner, ownerStake);
        OMCLib._safeTransfer(WETH, omcEpoch, balance - ownerStake);
    }

    function setSale(
        uint256 _newMintPrice,
        uint256 _newMintLimitPerUser,
        uint256 _newMintStartBlock,
        uint256 _newAntiBotInterval,
        uint256 _newCountLimitPerMint
    ) external override onlyOwner {
        _mintPrice = _newMintPrice;
        _mintLimitPerUser = _newMintLimitPerUser;
        _mintStartBlock = _newMintStartBlock;
        _antibotInterval = _newAntiBotInterval;
        _countLimitPerMint = _newCountLimitPerMint;
    }

    function publicMint(uint256 _mintCount) external payable override {
        require(publicMintEnabled, "PUBLIC SALE NOT ENABLED");
        require(
            _mintCount > 0 && _mintCount <= _countLimitPerMint,
            "INVALID MINTCOUNT"
        );
        require(msg.value >= _mintCount * _mintPrice, "INSUFFIENT PAYMENT");
        require(block.number >= _mintStartBlock, "MINTING NOT STARTED");
        require(
            _lastCallBlockNumber[msg.sender] + _antibotInterval < block.number,
            "BOT IS NOT ALLOWED"
        );
        require(totalSupply + _mintCount <= maxTotalSupply, "OVER MAX SUPPLY");
        require(
            (balanceOf(msg.sender) + _mintCount) <= _mintLimitPerUser,
            "EXCEEDED MAX AMOUNT PER PERSON"
        );
        for (uint256 i = 0; i < _mintCount; i++) {
            _mint(msg.sender, totalSupply);
            totalSupply += 1;
        }
        _lastCallBlockNumber[msg.sender] = block.number;
    }

    //Airdrop Mint
    function airDropMint(address _receiver, uint256 _requestedCount)
        external
        override
        onlyOwner
    {
        require(_requestedCount > 0, "INVALID COUNT");
        for (uint256 i = 0; i < _requestedCount; i++) {
            _mint(_receiver, totalSupply);
            totalSupply += 1;
        }
    }
}
