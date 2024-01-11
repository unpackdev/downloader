/*

██████╗░██╗██╗░░░░░██╗░░░░░░█████╗░░██████╗░█████╗░██████╗░██╗░░██╗███████╗██████╗░░██████╗
██╔══██╗██║██║░░░░░██║░░░░░██╔══██╗██╔════╝██╔══██╗██╔══██╗██║░░██║██╔════╝██╔══██╗██╔════╝
██████╔╝██║██║░░░░░██║░░░░░██║░░██║╚█████╗░██║░░██║██████╔╝███████║█████╗░░██████╔╝╚█████╗░
██╔═══╝░██║██║░░░░░██║░░░░░██║░░██║░╚═══██╗██║░░██║██╔═══╝░██╔══██║██╔══╝░░██╔══██╗░╚═══██╗
██║░░░░░██║███████╗███████╗╚█████╔╝██████╔╝╚█████╔╝██║░░░░░██║░░██║███████╗██║░░██║██████╔╝
╚═╝░░░░░╚═╝╚══════╝╚══════╝░╚════╝░╚═════╝░░╚════╝░╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░


 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "Address.sol";
import "Strings.sol";
import "ERC721AQueryable.sol";
import "ReentrancyGuard.sol";

enum State {
    NotStarted,
    WhitelistSale,
    PublicSale,
    Frozen,
    SoldOut
}

contract PillHub is ERC721AQueryable, Ownable, ReentrancyGuard {
    // Base URI before for metadata
    string public baseURI;
    // Blind URI before reveal
    string public blindURI;

    uint256 public constant COLLECTION_SIZE = 5555;
    uint256 public tokenPrice = 0.12 ether;

    uint256 public WHITELIST_MINT_LIMIT = 5;
    uint256 public PUBLIC_MINT_LIMIT = 10;

    // Reveal enable/disable
    bool public reveal;

    // Current Contract state
    State public state = State.NotStarted;
    mapping(address => uint256) public whitelistMembers;

    //todo: constructor

    constructor(string memory _blindURI)
        ERC721A("Pillosophers by Pillhub", "PILL")
    {
        blindURI = _blindURI;
    }

    /********************/
    /**    MODIFIERS   **/
    /********************/
    // This means that if the smart contract is frozen by the owner, the
    // function is executed an exception is thrown
    modifier notFrozen() {
        require(state != State.Frozen, "Pillosophers: frozen!");
        _;
    }
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract!");
        _;
    }

    /******************************/
    /**    ONLYOWNER Functions   **/
    /******************************/
    /// @notice reveal now, called only by owner
    /// @dev reveal metadata for NFTs
    function revealNow() external onlyOwner {
        reveal = true;
    }

    /// @notice setBaseURI, called only by owner
    /// @dev set Base URI
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function setBlindURI(string memory _URI) external onlyOwner {
        blindURI = _URI;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function freeMintByOwner(address _receiver, uint256 _quantity)
        external
        onlyOwner
        notFrozen
    {
        require(
            totalSupply() + _quantity <= COLLECTION_SIZE,
            "Reached max supply!"
        );
        require(
            state == State.PublicSale || state == State.WhitelistSale,
            "Pillosophers: Sale not started!"
        );

        _safeMint(_receiver, _quantity);
    }

    /// @notice freeze now, called only by owner
    /// @dev freeze minting !! only an emergency function!!
    function freezeNow() external onlyOwner notFrozen {
        state = State.Frozen;
    }

    function startWhitelistSale() external onlyOwner {
        state = State.WhitelistSale;
    }

    function startPublicSale(uint256 _newPrice) external onlyOwner {
        state = State.PublicSale;
        tokenPrice = _newPrice;
    }

    function soldOut() external onlyOwner notFrozen {
        require(totalSupply() == COLLECTION_SIZE, "Sale is still on!");
        state = State.SoldOut;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function seedWhitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistMembers[addresses[i]] = WHITELIST_MINT_LIMIT;
        }
    }

    /******************************/
    /**      Public Functions    **/
    /******************************/

    function isWhitelisted(address _user) public callerIsUser returns (bool) {
        bool whitelisted = (whitelistMembers[_user] > 0);
        return whitelisted;
    }

    function tokenMint(uint256 _quantity)
        external
        payable
        callerIsUser
        notFrozen
    {
        require(
            (state == State.WhitelistSale || state == State.PublicSale),
            "Sale has not started yet."
        );
        require(msg.value >= _quantity * tokenPrice, "Insufficient funds.");
        require(
            totalSupply() + _quantity <= COLLECTION_SIZE,
            "reached max supply"
        );
        require(tokenPrice != 0, "token sale has not begun yet");
        if (state == State.WhitelistSale) {
            require(
                isWhitelisted(msg.sender),
                "not eligible for whitelist mint"
            );
            require(
                whitelistMembers[msg.sender] >= _quantity,
                "you will exceed your wallet limit"
            );
            require(
                _quantity <= WHITELIST_MINT_LIMIT,
                "you will exceed the max whitelist limit"
            );
            whitelistMembers[msg.sender]--;
            _safeMint(msg.sender, _quantity);
        }
        if (state == State.PublicSale) {
            require(
                numberMinted(msg.sender) + _quantity <= PUBLIC_MINT_LIMIT,
                "can not mint this many"
            );
        }
        _safeMint(msg.sender, _quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (!reveal) {
            return
                string(
                    abi.encodePacked(
                        blindURI,
                        "/",
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /******************************/
    /**     Internal Functions   **/
    /******************************/
}
