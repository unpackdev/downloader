// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Importing necessary contracts and libraries from OpenZeppelin
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";

// Interface for interacting with GHO token contract
interface IGHO is IERC20 {
    function permit(
        address owner, 
        address spender, 
        uint256 value, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;
}

// Main contract for GHOPass token
contract GHOPass is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Token address for GHO token
    IGHO public constant GHO_TOKEN = IGHO(0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f);
    address public constant AAVE_DAO_TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // Struct for Edition data
    struct Edition {
        uint256 editionSupply;
        uint256 editionSupplyLimit;
        uint256 startingPrice;
        uint256 minimumPrice;
        uint256 discountRate;
        uint256 saleStartAt;
        string uri;
    }

    // Mapping to store edition data
    mapping(uint256 => Edition) public editions;

    // Event emitted upon successful minting
    event Minted(uint256 indexed edition, address indexed buyer, address indexed recipient, uint256 tokenId, string encryptedData);

    // Constructor initializes ERC721 token with name and symbol
    constructor() ERC721("GHOPass", "GP") {}

    /// @notice Sets the URI of a GHO Pass edition.
    /// @param edition The edition number.
    /// @param uri The new URI.
    function setEditionURI(uint256 edition, string memory uri) external onlyOwner {
        editions[edition].uri = uri;
    }

    /// @notice Updates the data of a particular edition.
    /// @param edition The edition number.
    /// @param _startingPrice The new starting price.
    /// @param _minimumPrice The new minimum price.
    /// @param _discountRate The new discount rate, decreases price by this amount per second.
    /// @param _editionSupplyLimit Cap on the total number of edition NFTs that can be minted.
    /// @param _saleStartAt Block timestamp of relase opening.
    function setEditionData(
        uint256 edition,
        uint256 _startingPrice,
        uint256 _minimumPrice,
        uint256 _discountRate,
        uint256 _editionSupplyLimit,
        uint256 _saleStartAt
    ) external onlyOwner {
        Edition storage ed = editions[edition];
        require(_editionSupplyLimit >= ed.editionSupply,"New edition supply cap must be greater than current edition supply");
        ed.startingPrice = _startingPrice;
        ed.minimumPrice = _minimumPrice;
        ed.discountRate = _discountRate;
        ed.editionSupplyLimit = _editionSupplyLimit;
        ed.saleStartAt = _saleStartAt;
    }

    /// @notice Allows a user to buy a GHOPass token.
    /// @dev Warning: Do not mint directly from contract, data field must be properly encrypted.
    /// @param edition Version number of GHO Pass to mint.
    /// @param encryptedData The encrypted data associated with the token mint.
    /// @param recipient The address to mint the NFT to.
    function buy(uint256 edition, string memory encryptedData, address recipient) public {
        Edition storage ed = editions[edition];

        // Checks
        require(ed.editionSupply < ed.editionSupplyLimit, "No available tokens to mint");
        require(block.timestamp >= ed.saleStartAt, "Edition is not available to mint");
        uint256 price = getPrice(edition);
        require(GHO_TOKEN.balanceOf(msg.sender) >= price, "Not enough GHO tokens");

        // Effects
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        ed.editionSupply++;

        // Interactions
        require(GHO_TOKEN.transferFrom(msg.sender, AAVE_DAO_TREASURY, price), "GHO token transfer failed");
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, ed.uri);

        emit Minted(edition, msg.sender, recipient, tokenId, encryptedData);
    }

    /// @notice Allows a user to buy a GHOPass token using a permit.
    /// @param edition Version number of GHO Pass to mint.
    /// @param encryptedData The encrypted data associated with the token mint.
    /// @param recipient The address to mint the NFT to.
    /// @param deadline The deadline for the permit.
    /// @param amount The amount of permit approval
    /// @param v The recovery id of the signature.
    /// @param r Output value r of the ECDSA signature.
    /// @param s Output value s of the ECDSA signature.
    function buyWithPermit(
        uint256 edition, 
        string memory encryptedData,
        address recipient,
        uint256 amount,
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external {
        GHO_TOKEN.permit(msg.sender, address(this), amount, deadline, v, r, s);
        buy(edition, encryptedData, recipient);
    }

    /// @notice Gets the price of a GHOPass token for a particular edition.
    /// @param edition The edition number.
    /// @return The price of the GHOPass token.
    function getPrice(uint256 edition) public view returns (uint256) {
        Edition storage ed = editions[edition];

        // if sale has not started, return starting price
        if(ed.saleStartAt >= block.timestamp){
            return ed.startingPrice;
        } else {
        uint timeElapsed = block.timestamp - ed.saleStartAt;
        uint discount = ed.discountRate * timeElapsed;

        // Return max(startingPrice - discount, minimumPrice)
        if (ed.startingPrice > discount) {
            uint price = ed.startingPrice - discount;
            return price > ed.minimumPrice ? price : ed.minimumPrice;
        }
        return ed.minimumPrice;
        }
    }

    /// @notice Returns a grouped set of pricing and availability parameters.
    /// @param edition The edition number.
    /// @return The starting price, minimum price, discount rate, sale start timestamp, number of edition tokens, supply cap for edition tokens, and total supply of GHOPass token supply.
    function getPricingAndAvailability(uint256 edition) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        Edition storage ed = editions[edition];
        return (ed.startingPrice, ed.minimumPrice, ed.discountRate, ed.saleStartAt, ed.editionSupply, ed.editionSupplyLimit, totalSupply());
    }

    /// @notice Returns the total number of GHOPass tokens minted so far.
    /// @return The total supply of GHOPass tokens.
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Claims any ERC20 tokens accidentally sent to this contract.
    /// @param tokenAddress The address of the ERC20 token.
    function claimTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Token transfer failed");
    }

    /// @notice Override to disables token transfer, GHOPass is a soulbound token.
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override virtual {
        require(from == address(0), "GHOPass is soulbound, token transfer is blocked");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /// @notice Overrides the _burn function of ERC721.
    /// @param tokenId The id of the token being burned.
    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @notice Overrides the tokenURI function of ERC721.
    /// @param tokenId The id of the token.
    /// @return The URI of the token.
    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmPtSKbMgUdA2BPqUqAcMzdiUaox2B7RyFwQPFwC5z3JcP";
    }
}
