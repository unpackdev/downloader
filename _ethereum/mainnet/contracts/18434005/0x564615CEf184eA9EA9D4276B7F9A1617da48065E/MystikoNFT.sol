//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./INFT.sol";
import "./IFactory.sol";

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract MystikoNFT is INFT, ERC721, Pausable {
    IFactory public immutable FACTORY;

    uint256 public supplyLimit;
    uint256 public totalSupply;
    uint256 public mintStart;

    string private _name;
    string private _symbol;

    mapping(address => bool) private _minted;

    constructor(address factory) ERC721("", "") {
        require(factory != address(0), "MystikoNFT: zero address");
        FACTORY = IFactory(factory);
    }

    modifier onlyOwner() {
        (, bool isAdmin) = FACTORY.isSignerOrAdmin(_msgSender());
        require(isAdmin, "MystikoNFT: not an owner");
        _;
    }

    /**
     * @dev collection name
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev collection symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev function to initialize collection
     * @notice only for factory
     * @param name_ collection name
     * @param symbol_ collection symbol
     * @param totalSupply_ max amount to mint available
     * @param expirationTime_ mint start
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 expirationTime_
    ) external override {
        require(_msgSender() == address(FACTORY), "MystikoNFT: wrong sender");
        _name = name_;
        _symbol = symbol_;
        supplyLimit = totalSupply_;
        mintStart = expirationTime_;
        _pause();
    }

    /**
     * @dev function to enable token transfers
     */
    function allowTransfers() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev function to disable token transfers
     */
    function forbidTransfers() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev function to issue one token
     * @notice it's neccessary to have signature
     * @param signatureUntil signature expiration time
     * @param signature signature
     */
    function mint(
        uint256 signatureUntil,
        bytes memory signature
    ) external {
        require(block.timestamp >= mintStart, "MystikoNFT: not started");
        (bool isSigner, ) = FACTORY.isSignerOrAdmin(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            _msgSender(),
                            signatureUntil
                        )
                    )
                ),
                signature
            )
        );
        require(!_minted[_msgSender()], "MystikoNFT: NFT already minted");
        _minted[_msgSender()] = true;
        require(isSigner, "MystikoNFT: wrong signature");
        require(block.timestamp < signatureUntil, "MystikoNFT: old signature");

        _safeMint(_msgSender(), totalSupply);

        require(
            supplyLimit > totalSupply++,
            "MystikoNFT: wrong tokenId"
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return
            string.concat(
                FACTORY.baseURI(),
                "/",
                Strings.toHexString(uint256(uint160(address(this))), 20),
                "/"
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        if (from != address(0))
            require(!paused(), "MystikoNFT: transfers forbidden");
    }
}
