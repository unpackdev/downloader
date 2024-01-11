pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT
//Contract developed by: @moonfarm_eth

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

//   +--   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   --+
//   |                                                                                       |
//
//   .                                    `++//++../+`                                       .
//                                      `/+hhhhssooo+`
//   .                                `:/hhyyyy++o    s.                                     .
//                                    :ddyyyy++ss`
//   .                                :ddhy++dd:-----`                                       .
//                                    :dh++yyyyyyhhhh:.`
//   .                                :ddys----//yyyyyy-                                     .
//                                   `:dy-/yyyyyyhhhh-`
//   .      _______                      .__       .__    ___________.__       .__           .
//          \      \   ____  __ __  ____ |__| _____|  |__ \_   _____/|__| _____|  |__
//   .      /   |   \ /  _ \|  |  \/    \|  |/  ___/  |  \ |    __)  |  |/  ___/  |  \       .
//         /    |    (  <_> )  |  /   |  \  |\___ \|   Y  \|     \   |  |\___ \|   Y  \
//   .     \____|__  /\____/|____/|___|  /__/____  >___|  /\___  /   |__/____  >___|  /      .
//                 \/                  \/        \/     \/     \/            \/     \/
//   .                        :osys/:`/ddooooyyoo                                            .
//                            odhs+:-`:hhddssssdd`
//   .                        odhs+:-`-++sshhhhdd+/`                                         .
//                            odhs+:-`.----oohhddhh/:`
//   .                        odhs+:-``````--ooyyoohh/-`                                     .
//                            odhso+:..````  ------+ohd:
//   .                        odhshdy--`````       .-yd/.`                                   .
//                          `.sdhyhdy:-```````       oyhd:
//   .                      shddddddy::......... ````oyhd/``                                 .
//                          shhyyyhdyyyyyyyyyyy/ /yyyhhhhyyo
//   .                      `.ohhdddyhh   `dhhh+ +hd   `hhhy                                 .
//                            .-:hhdhhh   `dyhhyoyhm   `yhhy
//   .                          .hhddhh   `dyhhs+yhm   `yhhy                                 .
//                              `::::hhmmmmhhhhsoyhdmmmdhhhy
//   .                               :///////ddhhhd+///////:                                 .
//                                           ++++++`
//   |                                                                                       |
//   +--   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   --+

contract NounishFish is ERC721A, Ownable, Pausable, PaymentSplitter {
    using SafeMath for uint256;

    // max amount of tokens in the collection
    uint256 public maxTokens;
    // price for first 400 tokens
    uint256 public tokenPrice1 = 0.006969 ether;
    // price per token minted
    uint256 public tokenPrice2 = 0.01 ether;
    // max amount of tokens minted in one transaction
    uint256 public maxTokensPerTxn;
    // amount of reserved tokens
    uint256 public reservedTokens;
    // minted reserved tokens
    uint256 public mintedReservedTokens;

    // ### active sale ###
    // public-sale allows anyone to mint
    // through publicMint()
    bool public publicSaleIsActive;
    // ###

    // saves the baseURI internally
    string private baseURI;
    // saves the baseURI for unrevealed tokens internally
    string private unrevealedBaseURI;

    // save reveal seed
    uint256 public seed;

    // URI for a specific token
    mapping(uint256 => string) private _tokenURIs;

    address[] payees = [
        0xDe87D0C974AD57EF203d0F3e7bF9C43c8BFE6Ec0,
        0xfB4e5480dF2eff848F356e6d99fd5b9312cCcAAc
    ];

    uint256[] payeeShares = [85, 15];

    constructor(
        uint256 _maxTokens,
        uint8 _maxTokensPerTxn,
        uint256 _reservedTokens
    )
        ERC721A("NounishFish", unicode"⌐◧-◨")
        PaymentSplitter(payees, payeeShares)
    {
        maxTokens = _maxTokens;
        maxTokensPerTxn = _maxTokensPerTxn;
        reservedTokens = _reservedTokens;
    }

    // ***************
    // *** Minting ***
    // ***************

    /**
     * Public minting, everyone can mint as long as publicSaleIsActive = true
     */
    function publicMint(uint8 amount)
        external
        payable
        activeSale(publicSaleIsActive)
        payment(amount)
        amountWithinMaxTokens(amount)
    {
        mint(amount, msg.sender);
    }

    /**
     * Free token minting for the owner
     */
    function mintReservedTokens(uint8 amount, address to) external onlyOwner {
        require(
            mintedReservedTokens.add(amount) <= reservedTokens,
            "Can not mint more than reserved"
        );

        uint256 batches = amount / maxTokensPerTxn;
        for (uint8 i; i < batches; i++) {
            _safeMint(to, maxTokensPerTxn);
        }
        uint256 remainder = amount - batches.mul(maxTokensPerTxn);
        if (remainder > 0) {
            _safeMint(to, remainder);
        }

        mintedReservedTokens += amount;
    }

    function mint(uint8 amount, address to) private whenNotPaused {
        require(to != address(0), "No address");
        require(amount <= maxTokensPerTxn, "Too many mints in a txn");
        _safeMint(to, amount);
    }

    // **********************
    // *** Administration ***
    // **********************

    /**
     * set which sale(s) should be active or inactive
     */
    function setPublicSale(bool _publicSaleIsActive) public onlyOwner {
        require(
            mintedReservedTokens == reservedTokens,
            "mint all reserved tokens first"
        );
        publicSaleIsActive = _publicSaleIsActive;
    }

    /**
     * set minting price
     * _tokenPrice1: cost for first 400 tokens
     * _tokenPrice2: normal cost for tokens
     */
    function setMintPrice(uint256 _tokenPrice1, uint256 _tokenPrice2)
        public
        onlyOwner
    {
        tokenPrice1 = _tokenPrice1;
        tokenPrice2 = _tokenPrice2;
    }

    /**
     * set a specific tokens URI
     * note: make sure you use the tokenId and not the generated reveal-id
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * set the baseURI for the collection
     */
    function setUnrevealedBaseURI(string memory _URI) external onlyOwner {
        unrevealedBaseURI = _URI;
    }

    /**
     * set the baseURI for the collection
     */
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    /**
     * call to reveal tokens
     */
    function revealTokens() public onlyOwner {
        require(seed == 0, "Can only reveal once");
        seed =
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        block.number
                    )
                )
            ) %
            (maxTokens - reservedTokens);
    }

    /**
     * pause contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * unpause contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // ***************
    // **** Utils ****
    // ***************

    /**
     * get the baseURI internally
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * get the tokenURI based on seeds generated in reveal
     * note: returns unrevealedBaseURI if tokenId hasn't been revealed yet
     */
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
        if (seed == 0) {
            return unrevealedBaseURI;
        }

        string memory base = _baseURI();
        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is a specific token URI, return the token URI.
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // Don't scramble reserved tokens
        if (tokenId < reservedTokens) {
            return string(abi.encodePacked(base, uint2str(tokenId)));
        }

        // Calculate revealed id from rotation
        uint256 revealedId = (seed + tokenId) % (maxTokens - reservedTokens);
        // Bundle id with base uri
        return
            string(
                abi.encodePacked(base, uint2str(revealedId + reservedTokens))
            );
    }

    /**
     * convert int to str
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // *****************
    // ** Extensions ***
    // *****************

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        require(!paused(), "Pausable: token transfer while paused");
    }

    // *****************
    // *** Modifiers ***
    // *****************

    modifier activeSale(bool sale) {
        require(sale, "this sale is not active");
        _;
    }

    modifier payment(uint8 amount) {
        bool first400 = totalSupply() < 400 &&
            tokenPrice1.mul(amount) <= msg.value;
        require(
            first400 || tokenPrice2.mul(amount) <= msg.value,
            "Not enough ether to mint"
        );
        _;
    }

    modifier amountWithinMaxTokens(uint8 amount) {
        require(
            totalSupply().add(amount) <=
                maxTokens.sub(reservedTokens.sub(mintedReservedTokens)),
            "Not enough tokens left to mint"
        );
        _;
    }
}
