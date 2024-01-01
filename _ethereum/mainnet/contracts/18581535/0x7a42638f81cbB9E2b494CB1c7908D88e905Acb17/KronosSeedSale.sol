// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./Owned.sol";
import "./ERC721.sol";
import "./LibString.sol";
import "./IERC20.sol";

/// @title Kronos Seed Sale Contract
/// @notice This contract is used to participate in the Kronos Seed Sale
contract KronosSeedSale is Owned, ERC721 {
    using LibString for uint256;

    // Constants
    uint256 public constant MINIMUM_PAYMENT = 500e6;
    uint256 public constant MAXIMUM_TOTAL_PAYMENT = 5000e6;
    uint256 public constant MAXIMUM_RAISE = 250_000e6;

    bool public seedSaleActive;

    // Payment tokens
    address public USDT;
    address public USDC;

    address public immutable withdrawAddress;

    string public baseURI;
    string private _contractURI;

    uint256 public totalSupply;
    uint256 public totalUSDTokenAmountCommitted;

    mapping(address => uint256) public USDTokenAmountCommitted;
    mapping(uint256 => uint256) public tokenIdToMetadataId;
    mapping(address => uint256) public metaIDForAddress;
    mapping(address => bool) private _admins;

    event Payment(address from, uint256 amount, bool USDT);

    /// @notice Constructor
    /// @param _USDT The address of the USDT contract
    /// @param _USDC The address of the USDC contract
    /// @param _baseURI The base URI for the token metadata
    constructor(address _USDT, address _USDC, address _withdraw, string memory _baseURI)
        ERC721("Kronos Titans", "TITAN")
        Owned(msg.sender)
    {
        USDT = _USDT;
        USDC = _USDC;
        withdrawAddress = _withdraw;
        baseURI = _baseURI;
    }

    /// @notice Flip the seed sale active state
    /// @dev Only the owner can call this function
    function flipSeedSaleActive() external onlyOwner {
        seedSaleActive = !seedSaleActive;
    }

    /// @notice Add addresses to the whitelist
    /// @param wallets The addresses to add to the whitelist
    /// @param metadataId The metadata id to assign to these address
    /// @dev The metadata id is the id of the metadata json file that will be used for the token uri
    /// @dev Only admins can call this function
    function addToWhitelist(address[] calldata wallets, uint256 metadataId) external {
        require(_admins[msg.sender] || msg.sender == owner, "Only admins can call this function");
        for (uint256 i; i < wallets.length; i++) {
            require(!isWhitelisted(wallets[i]), "Address is already on the whitelist");
            metaIDForAddress[wallets[i]] = metadataId;
        }
    }

    /// @notice Check if an address is whitelisted
    /// @param wallet The address to check
    /// @return True if the address is whitelisted, false otherwise
    /// @dev An address is whitelisted if it has a metadata id or has made a payment
    function isWhitelisted(address wallet) public view returns (bool) {
        return metaIDForAddress[wallet] > 0 || USDTokenAmountCommitted[wallet] > 0;
    }

    /// @notice Participate in the seed sale with USDT, if whitelisted
    /// @param amount The amount of USDT to commit
    /// @dev requirements are checked in _payWithToken
    function payWithUSDT(uint256 amount) external {
        _payWithToken(USDT, amount);
    }

    /// @notice Participate in the seed sale with USDC, if whitelisted
    /// @param amount The amount of USDC to commit
    /// @dev requirements are checked in _payWithToken
    function payWithUSDC(uint256 amount) external {
        _payWithToken(USDC, amount);
    }

    /// @notice Participate in the seed sale with USDT or USDC, if whitelisted
    /// @param token The address of the token to commit
    /// @param amount The amount of tokens to commit
    /// @dev The amount must be a minimum of USD $250
    /// @dev The total amount must not exceed USD $5000
    /// @dev The total amount must not exceed USD $250,000
    /// @dev This function is called by payWithUSDT and payWithUSDC
    function _payWithToken(address token, uint256 amount) private {
        require(seedSaleActive, "Seed Sale must be active");

        uint256 totalCommittedByUser = USDTokenAmountCommitted[msg.sender];

        // to allow for a payment after a mint, check if the address has made a payment before
        require(
            metaIDForAddress[msg.sender] > 0 || totalCommittedByUser > 0,
            "Address must be on the whitelist"
        );

        unchecked {
            // these cannot overflow since there are enforced maximums in place
            totalCommittedByUser = USDTokenAmountCommitted[msg.sender] += amount;
            totalUSDTokenAmountCommitted += amount;
        }

        require(
            totalCommittedByUser >= MINIMUM_PAYMENT && totalCommittedByUser <= MAXIMUM_TOTAL_PAYMENT
                && totalUSDTokenAmountCommitted <= MAXIMUM_RAISE,
            "Invalid amount"
        );

        // Transfer tokens from the sender to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Payment(msg.sender, amount, token == USDT);
    }

    /// @notice Mint an NFT, if whitelisted
    /// @dev The address must have made a minimum payment of USD $250
    function mint() external {
        uint256 metadataId = metaIDForAddress[msg.sender];
        require(seedSaleActive, "Seed Sale must be active");
        require(metadataId > 0, "Address must be on the whitelist");
        require(
            USDTokenAmountCommitted[msg.sender] >= MINIMUM_PAYMENT,
            "Address must have made a minimum payment of USD $250"
        );

        // reset the metadata id to 0 to prevent minting more than one NFT per address
        // allows the address to make another payment after minting
        // protects against reentrency attacks and reduces gas costs for minter
        metaIDForAddress[msg.sender] = 0;
        tokenIdToMetadataId[totalSupply] = metadataId;

        // mint and increment totalSupply after
        // using totalSupply as the token id
        _safeMint(msg.sender, totalSupply++);
    }

    /// @notice Set the base URI
    /// @param newURI The new base URI
    /// @dev Only the owner can call this function
    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    /// @notice Get the URI for a token
    /// @param tokenID The id of the token
    /// @return The URI for the token
    /// @dev The URI is the base URI + the metadata id
    /// @dev The metadata id is the id of the metadata json file that will be used for the token id
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(tokenID < totalSupply, "This token does not exist");
        //get metadata id from token id
        uint256 metadataId = tokenIdToMetadataId[tokenID];
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, metadataId.toString()))
            : "";
    }

    /// @notice Get the contract URI
    /// @return The contract URI
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /// @notice Set the contract URI
    /// @param newURI The new contract URI
    /// @dev Only the owner can call this function
    function setContractURI(string calldata newURI) external onlyOwner {
        _contractURI = newURI;
    }

    /// @notice Withdraw tokens from the contract
    /// @param token The address of the token to withdraw
    /// @dev Only the owner can call this function
    function withdrawTokens(address token) external {
        require(msg.sender == withdrawAddress, "Only the withdraw address can call this function");
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /// @notice Adds multiple admins to the contract.
    /// @param admins The addresses of the new admins.
    function addAdmins(address[] calldata admins) external onlyOwner {
        for (uint256 i = 0; i < admins.length; i++) {
            _admins[admins[i]] = true;
        }
    }

    /// @notice Removes an admin from the contract.
    /// @param admin The address of the admin to remove.
    function removeAdmin(address admin) external onlyOwner {
        _admins[admin] = false;
    }

    /// @notice Checks if an address is an admin of the contract.
    /// @param admin The address to check.
    /// @return True if the address is an admin, false otherwise.
    function isAdmin(address admin) external view returns (bool) {
        return _admins[admin];
    }
}
