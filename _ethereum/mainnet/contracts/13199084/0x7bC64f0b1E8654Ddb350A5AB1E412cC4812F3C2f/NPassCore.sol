// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IN.sol";

/**
 * @title NPassCore contract
 * @author Tony Snark
 * @notice This contract provides basic functionalities to allow minting using the NPass
 * @dev This contract should be used only for testing or testnet deployments
 */
abstract contract NPassCore is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_MULTI_MINT_AMOUNT = 32;
    uint256 public constant MAX_N_TOKEN_ID = 8888;

    IN public immutable n;
    bool public openMintActive;
    uint256 public immutable priceInWei;

    /**
     * @notice Construct an NPassCore instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param n_ Address of your n instance (only for testing)
     * @param priceInWei_ Price n token holders need to pay to mint
     */
    constructor(
        string memory name,
        string memory symbol,
        IN n_,
        uint256 priceInWei_
    ) ERC721(name, symbol) {
        n = n_;
        priceInWei = priceInWei_;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param tokenIds Ids to be minted
     */
    function multiMintWithN(uint256[] calldata tokenIds)
        public
        payable
        virtual
        nonReentrant
    {
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= MAX_MULTI_MINT_AMOUNT, "NPass:TOO_LARGE");
        require(
            msg.value == priceInWei * maxTokensToMint,
            "NPass:INVALID_PRICE"
        );
        // To avoid wasting gas we want to check all preconditions beforehand
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(
                n.ownerOf(tokenIds[i]) == msg.sender,
                "NPass:INVALID_OWNER"
            );
        }

        for (uint256 i = 0; i < maxTokensToMint; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice Allow anyone to mint a token, whether they are a N holder or not.
               Success and price of the mint will depend on contract state.
     * @param tokenId Id to be minted
     */
    function mint(uint256 tokenId) public payable virtual nonReentrant {
        require(
            openMintActive || n.ownerOf(tokenId) == msg.sender,
            "NPass:OPEN_MINTING_DISABLED"
        );
        require(tokenId <= maxTokenId(), "NPass:INVALID_ID");
        require(msg.value == priceInWei, "NPass:INVALID_PRICE");

        _safeMint(msg.sender, tokenId);
    }

    /**
     * @return Maximum token id (N -> 8'888)
     */
    function maxTokenId() public pure returns (uint256) {
        return MAX_N_TOKEN_ID;
    }

    /**
     * @notice Switches to "open mint" phase
     */
    function enableOpenMint() external onlyOwner {
        openMintActive = true;
    }

    /**
     * @notice Allows owner to withdraw amount
     */
    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
