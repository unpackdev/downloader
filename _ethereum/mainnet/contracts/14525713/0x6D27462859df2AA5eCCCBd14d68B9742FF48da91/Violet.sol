//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

/**
 *
 *          --------------               -----------------
 *          |   ARTIST   |               |   DEVELOPER   |
 *          --------------               -----------------
 *          jadynviolet.eth               nicoacosta.eth
 *           @jadynviolet                     @0xnico_
 *          jadynviolet.xyz           linktr.ee/nicoacosta.eth
 *
 *
 *
 *                          -------------
 *                          |   INDEX   |
 *                          -------------                     line
 *
 *      VIOLET Contract ...................................... 57
 *
 *          1.  State variables .............................. 59
 *
 *          2.  Constructor .................................. 104
 *
 *          3.  ERC721 extensions ............................ 133
 *
 *          4.  Minting ...................................... 152
 *
 *                  A.  Public minting ....................... 157
 *
 *                  B.  Minting from Glass Token ............. 263
 *
 *                  B.  Internal minting ..................... 396
 *
 *          5.  Metadata ..................................... 321
 *
 *                  A.  Contract URI ......................... 326
 *
 *                  B.  Token URI ............................ 342
 *
 *          6.  Withdrawal ................................... 363
 *
 */

/**
 *  @title Violet
 *  @author Nicolás Acosta (nicoacosta.eth) @0xnico_
 *          linktr.ee/nicoacosta.eth
 *  @notice Jadyn Violet Genesis Collection
 *          NFT ERC721.
 *  @dev Inherits from @openzeppelin/contracts `ERC721` and `Ownable`
 */
contract Violet is ERC721, Ownable {
    /// ---------------------
    /// 1. State variables
    /// ---------------------

    /// @notice Artist address
    address private constant ARTIST =
        0x94A8F46E3e05d8aB61Fb22eDc2893bE249C11D66; // jadynviolet.eth

    /// @notice Developer address
    address private constant DEV = 0xab468Aec9bB4b9bc59b2B2A5ce7F0B299293991f; // nicoacosta.eth

    /// @notice Public minting start date
    /// @return mintingStartDate Public minting start date
    uint256 public constant MINTING_START_DATE = 1649178000; // Tue Apr 05 17:00:00 2022 UTC

    /// @notice Maximum amount of tokens that can be publicly minted
    /// @return maxPublicMintingSupply Maximum amount of tokens that can be publicly minted
    uint256 public maxPublicMintingSupply;

    /// @notice Amount of tokens publicly minted so far
    /// @return publicMintingTokensMinted Amount of tokens publicly minted so far
    uint256 public publicMintingTokensMinted = 0;

    /// @notice Public minting price per token. 50% OFF during the first 11 days
    uint256 private _mintingPrice = 0.08 ether;

    /// @notice Music video glass contract
    /// @dev Used to verify if someone has minted a video token when trying to mint their free Violet token
    /// @return glassVideo Music video glass contract
    IERC721 public glassVideo;

    /// @notice Wheter some video token has been already used to mint a Violet first edition token
    /// @return bool wheter some video token has been already used to mint a Violet first edition token
    mapping(uint256 => bool) public usedGlassVideoTokenForMinting;

    /// @notice Last minted token id
    uint256 private _lastId;

    /// @notice Collection metadata IPFS URI
    string private _collectionURI;

    /// @notice Addresses for ETH and tokens withdrawal
    address private immutable _withdrawalAddress1;
    address private immutable _withdrawalAddress2;

    /// -----------------
    /// 2. Constructor
    /// -----------------

    constructor(
        string memory contractURI_,
        address withdrawalAddress1_,
        address withdrawalAddress2_
    ) ERC721("Violet", "VIOLET") {
        // Mint first edition tokens for artist and dev
        _safeMint(ARTIST, 1);
        _safeMint(DEV, 2);
        _safeMint(ARTIST, 3);
        _safeMint(ARTIST, 4);

        // Set last id to #4. First public minting call will mint #5
        _lastId = 4;

        // Set initial maxPublicMintingSupply to 60
        maxPublicMintingSupply = 60;

        // Set initial collection metadata
        setContractURI(contractURI_);

        // Set withdrawal addresses
        _withdrawalAddress1 = withdrawalAddress1_;
        _withdrawalAddress2 = withdrawalAddress2_;
    }

    /// -----------------------
    /// 3. ERC721 extensions
    /// -----------------------

    /// @notice Total amount of tokens minted so far
    /// @return totalSupply Total amount of tokens minted so far
    function totalSupply() external view returns (uint256) {
        return _lastId;
    }

    /// @notice Checks if token has been minted.
    /// @dev Returns ERC721's internal `_exists`
    /// @param tokenId Token id
    /// @return Bool: whether the token has been minted or not
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// -------------
    /// -------------
    /// 4. Minting
    /// -------------
    /// -------------

    /// ------------------------
    /// 4.A. Public minting
    /// ------------------------

    /// @notice Verifies if public minting has already started
    modifier mintingStarted() {
        require(
            block.timestamp >= MINTING_START_DATE,
            "VioletFirstEdition: Public minting has not started yet"
        );
        _;
    }

    /// @notice Checks if public minting first period (11 days) is active
    /// @return bool wheter public minting first period is active
    function isFirstMintingPeriodActive() public view returns (bool) {
        return block.timestamp < MINTING_START_DATE + 11 days;
    }

    /// @notice Returns current minting price depending on timestamp
    /// @return mintingPrice Current minting price
    function mintingPrice() external view returns (uint256) {
        if (isFirstMintingPeriodActive()) return _mintingPrice / 2;
        return _mintingPrice;
    }

    /// @notice Update public minting price
    /// @param newPrice New minting price per token
    function updateMintingPrice(uint256 newPrice) external onlyOwner {
        _mintingPrice = newPrice;
    }

    /// @notice Update maximum public minting supply
    /// @param newSupply a parameter just like in doxygen (must be followed by parameter name)
    function updateMaxPublicMintingSupply(uint256 newSupply)
        external
        onlyOwner
    {
        maxPublicMintingSupply = newSupply;
    }

    /// @notice Amount of tokens that still can be publicly minted
    /// @return tokensLeftToMint Amount of tokens that still can be publicly minted
    function tokensLeftToMint() external view returns (uint256) {
        return maxPublicMintingSupply - publicMintingTokensMinted;
    }

    /// @notice Mint first edition Violet token. If first period (11 days) is active minting price is 0.04 ETH; otherwise minting price is 0.08 ETH and maximum amount of tokens cannot be exceeded.
    /// @param to Token recipient
    function mintViolet(address to) external payable mintingStarted {
        uint256 currentMintingPrice;

        if (isFirstMintingPeriodActive()) {
            currentMintingPrice = _mintingPrice / 2;
        } else {
            currentMintingPrice = _mintingPrice;

            require(
                publicMintingTokensMinted < maxPublicMintingSupply,
                "VioletFirstEdition: Maximum amount of tokens already minted"
            );
        }

        require(
            msg.value == currentMintingPrice,
            "VioletFirstEdition: Invalid ETH amount"
        );

        publicMintingTokensMinted++;

        // Mint Violet token
        _mintOneToken(to);
    }

    /// @notice Mint first edition Violet tokens. If first period (11 days) is active minting price is 0.04 ETH; otherwise minting price is 0.08 ETH and maximum amount of tokens cannot be exceeded.
    /// @param to Token recipient
    /// @param amount Amount of tokens to be minted
    function mintViolets(address to, uint256 amount)
        external
        payable
        mintingStarted
    {
        uint256 currentMintingPrice;

        if (isFirstMintingPeriodActive()) {
            currentMintingPrice = _mintingPrice / 2;
        } else {
            currentMintingPrice = _mintingPrice;

            require(
                publicMintingTokensMinted + amount <= maxPublicMintingSupply,
                "VioletFirstEdition: Cannot mint that amount of tokens"
            );
        }

        require(
            msg.value == currentMintingPrice * amount,
            "VioletFirstEdition: Invalid ETH amount"
        );

        publicMintingTokensMinted += amount;

        // Mint Violet tokens
        _mintSeveralTokens(to, amount);
    }

    /// ----------------------------------
    /// 4.B. Minting from Glass Token
    /// ----------------------------------

    /// @notice Set glass music video contract address
    /// @param _contract Glass music video contract address
    function setGlassVideoContract(address _contract) public onlyOwner {
        glassVideo = IERC721(_contract);
    }

    /// @notice Mint one first edition Violet token for free if caller has minted Violet's first music video.
    /// @param videoTokenOwner Music video token owner and Violet token recipient
    /// @param videoTokenId Music video token ID
    function mintVioletFromGlassVideo(
        address videoTokenOwner,
        uint256 videoTokenId
    ) external {
        require(
            videoTokenOwner == glassVideo.ownerOf(videoTokenId),
            "VioletFirstEdition: Caller is not video token owner"
        );
        require(
            !usedGlassVideoTokenForMinting[videoTokenId],
            "VioletFirstEdition: Video token has been already used to mint a Violet token"
        );

        // Save that this video token has been used to mint a Violet token.
        usedGlassVideoTokenForMinting[videoTokenId] = true;

        // Mint Violet token
        _mintOneToken(videoTokenOwner);
    }

    /// --------------------------
    /// 4.C. Internal minting
    /// --------------------------

    /// @notice Mint next token id
    /// @param _to Token recipient
    function _mintOneToken(address _to) internal {
        _lastId++;

        _safeMint(_to, _lastId);
    }

    /// @notice Mint next token ids
    /// @param _to Token recipient
    function _mintSeveralTokens(address _to, uint256 _amount) internal {
        uint256 id = _lastId;

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, id + i);
        }

        _lastId = id + _amount;
    }

    /// --------------
    /// --------------
    /// 5. Metadata
    /// --------------
    /// --------------

    /// ----------------------
    /// 5.A. Contract URI
    /// ----------------------

    /// @notice Collection metadata IPFS URI
    /// @return string Collection metadata IPFS URI
    function contractURI() external view returns (string memory) {
        return _collectionURI;
    }

    /// @notice Set/update collection metadata IPFS URI
    /// @param newURI a parameter just like in doxygen (must be followed by parameter name)
    function setContractURI(string memory newURI) public onlyOwner {
        _collectionURI = newURI;
    }

    /// -------------------
    /// 5.B. Token URI
    /// -------------------

    /// @notice Returns a token metadata IPFS URI
    /// @dev Calls token's edition contract to get its metadata
    /// @param tokenId Token id
    /// @return string Token metadata IPFS URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Violet: URI query for nonexistent token");

        return
            "https://ipfs.io/ipfs/bafybeiehchwkoo5lkfckp2nts2zdudvywb4z4ge36cu2y2wsgnnn4wbkya";
    }

    /// ----------------
    /// ----------------
    /// 6. Withdrawal
    /// ----------------
    /// ----------------

    /// @notice Enable contract to receive ETH
    receive() external payable {}

    /// @notice Verifies if caller is authorized to withdraw funds
    modifier onlyWithdrawalAddresses() {
        require(
            msg.sender == owner() ||
                msg.sender == _withdrawalAddress1 ||
                msg.sender == _withdrawalAddress2,
            "Splitter: Caller cannot withdraw funds"
        );
        _;
    }

    /// @notice Amount to be transfered to _withdrawalAddress1
    /// @param _totalBalance Total balance to be withdrawn
    /// @return uint256 Amount to be transfered to _withdrawalAddress1
    function _withdrawalAmountForWithdrawalAddress1(uint256 _totalBalance)
        private
        pure
        returns (uint256)
    {
        return (_totalBalance * 15) / 100;
    }

    /// @notice Withdraw contract's ETH balance to withdrawal addresses
    function withdrawETH() external onlyWithdrawalAddresses {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "Splitter: No ETH balance to transfer");

        uint256 _amount1 = _withdrawalAmountForWithdrawalAddress1(_balance);

        payable(_withdrawalAddress1).transfer(_amount1);
        payable(_withdrawalAddress2).transfer(_balance - _amount1);
    }

    /// @notice Withdraw contract's ERC20 balance to withdrawal addresses
    function withdrawERC20(address erc20) external onlyWithdrawalAddresses {
        IERC20 token = IERC20(erc20);
        uint256 _balance = token.balanceOf(address(this));
        require(_balance > 0, "Splitter: No token balance to transfer");

        uint256 _amount1 = _withdrawalAmountForWithdrawalAddress1(_balance);

        token.transfer(_withdrawalAddress1, _amount1);
        token.transfer(_withdrawalAddress2, _balance - _amount1);
    }
}
