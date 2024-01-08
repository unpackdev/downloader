//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";

/*
 __    __  ______  ________  ________   ______   _______   ______   ______   __    __ 
/  \  /  |/      |/        |/        | /      \ /       \ /      | /      \ /  \  /  |
$$  \ $$ |$$$$$$/ $$$$$$$$/ $$$$$$$$/ /$$$$$$  |$$$$$$$  |$$$$$$/ /$$$$$$  |$$  \ $$ |
$$$  \$$ |  $$ |  $$ |__       $$ |   $$ |  $$ |$$ |__$$ |  $$ |  $$ |__$$ |$$$  \$$ |
$$$$  $$ |  $$ |  $$    |      $$ |   $$ |  $$ |$$    $$<   $$ |  $$    $$ |$$$$  $$ |
$$ $$ $$ |  $$ |  $$$$$/       $$ |   $$ |  $$ |$$$$$$$  |  $$ |  $$$$$$$$ |$$ $$ $$ |
$$ |$$$$ | _$$ |_ $$ |         $$ |   $$ \__$$ |$$ |  $$ | _$$ |_ $$ |  $$ |$$ |$$$$ |
$$ | $$$ |/ $$   |$$ |         $$ |   $$    $$/ $$ |  $$ |/ $$   |$$ |  $$ |$$ | $$$ |
$$/   $$/ $$$$$$/ $$/          $$/     $$$$$$/  $$/   $$/ $$$$$$/ $$/   $$/ $$/   $$/ 
 */                                                                                    
                                                                                      
/// @title NiftorianMintPass
/// @author niftorian.com
/// @notice Founder's Collection Mint Pass NFT owners are eligible to mint up to 3 Niftorian NFTs prior to the public mint. They can avoid the gas wars and own a piece of great art forever.
contract NiftorianMintPass is ERC721, Ownable, AccessControlEnumerable {

    using Counters for Counters.Counter; 
    string private _baseUrl;

    bool private saleIsActive = false; 
    bool private whitelistSaleIsActive = false; 
    bool private terminationProtection = false;
    bool private saleIsClosed = false;

    uint256 constant private MAX_SUPPLY = 2800;
    uint256 constant private MAX_RESERVE = 154;

    uint256 private publicCurrentLimit = 154;
    uint256 private whitelistCurrentLimit = 154;

    address private _adminAddress;

    mapping(uint256 => uint256) private utilityState; 
    mapping(address => uint256) private whitelistPasses;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _tokenIdReserveCounter;

    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    /// @notice The constructor of the smart contract. It will be called on deployment and will setup anything we need to go ahead.
    /// @param url The base URL where the metadata will be stored.
    /// @param name The name of the contract.
    /// @param sym The symbol of the contract.
    constructor(address admin, string memory url, string memory name, string memory sym) ERC721(name, sym) {
        _baseUrl = url;
        _adminAddress = admin;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // setup the owner as admin of the whitelist role
    }

    /// @notice A protection variable so that we do not accidentally close the sale forever
    function deactivateTerminationProtection() external onlyOwner {
        terminationProtection = true;
    }

    /// @notice Close the sale forever - there is no setter funciton for saleIsClosed.
    function closeSale() external onlyOwner{
        require(terminationProtection, "Deactivate termination protection first."); 
        saleIsClosed = true;
    }

    /// @notice Toggle whether the public minting sale is open or not.
    function toggleSaleState() external {
        require(msg.sender == owner() || msg.sender == _adminAddress, "Not the owner or an admin.");
        saleIsActive = !saleIsActive;
    }

    /// @notice Toggle whether the whitelist minting sale is open or not.
    function toggleWhitelistSaleState() external {
        require(msg.sender == owner() || msg.sender == _adminAddress, "Not the owner or an admin.");
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    /// @notice A setter function to set the limit of the whitelist / public sale - we need this in order to limit supply in every stage.
    /// @param limit The new limit.
    /// @param forwhitelist Whether you are changing the whitelist or public limit.
    function setCurrentLimit(uint256 limit, bool forwhitelist) external {
        require(msg.sender == owner() || msg.sender == _adminAddress, "Not the owner or an admin.");
        if(forwhitelist){
            whitelistCurrentLimit = limit;
        }else{
            publicCurrentLimit = limit;
        }
    }

    /// @notice Assign to a list of public addresses our whitelist role that enables the presale access.
    /// @param accounts The list of addresses.
    function addToWhiteList(address[] memory accounts) external onlyOwner{
        for (uint256 account = 0; account < accounts.length; account++) {
            grantRole(WHITELIST_ROLE, accounts[account]);
            whitelistPasses[accounts[account]] = 3;
        }
    }

    /// @notice Removes the whitelist role from a list of addresses.
    /// @param accounts The list of addresses.
    function removeFromWhiteList(address[] memory accounts) external onlyOwner{
        for (uint256 account = 0; account < accounts.length; account++) {
            revokeRole(WHITELIST_ROLE, accounts[account]);
            whitelistPasses[accounts[account]] = 0;
        }

    }

    /// @notice The actual mint function used for presale and public minting then. 
    /// @param amount The number of tokens you're able to mint in one transaction.
    function mint(uint256 amount) external payable {
        require(!saleIsClosed, "The sale is closed.");
        require(amount > 0 && amount <= 3, "Amount must be within [1;3].");

        if(whitelistSaleIsActive){ // check if we are in presale 
            require(hasRole(WHITELIST_ROLE, msg.sender), "You're not on the whitelist.");
            require(whitelistPasses[msg.sender] != 0 && (whitelistPasses[msg.sender] - amount) >= 0, "You are out of utility.");
            require(whitelistCurrentLimit > 0, "We're out of tokens.");
        }else{ // if not check if the public sale is active and we're in the limits
            require(saleIsActive, "Sale not active yet.");
            require(publicCurrentLimit > 0, "We're out of tokens.");
        }

        require((_tokenIdCounter.current() + amount) <= MAX_SUPPLY , "Out of tokens.");
        require(msg.value == (41000000000000000 * amount), "The amount of ether is wrong.");

        for(uint256 idx = 1; idx <= amount; idx++){

            if(hasRole(WHITELIST_ROLE, msg.sender)){ // make sure we reduce the amount of whitelistPasses left of the user and reduce the total limit
                whitelistPasses[msg.sender]--;
                whitelistCurrentLimit--;
            }else{
                publicCurrentLimit--;
            }

            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
            utilityState[_tokenIdCounter.current()] = 3;

        }

    }

    /// @notice Admin mint function that is used for preminting NFTs. 
    /// @param amount The amount of NFTs that can be minted in one transaction.
    function adminMint(address receiver, uint256 amount) external onlyOwner{
        require(!saleIsClosed, "The sale is closed.");
        require(_tokenIdReserveCounter.current() < MAX_RESERVE , "Out of reserve tokens.");
        require(amount > 0 && amount <= 20, "Amount must be within [1;20].");

        for(uint256 idx = 1; idx <= amount; idx++){
            _tokenIdReserveCounter.increment();
            _tokenIdCounter.increment();

            _safeMint(receiver, _tokenIdCounter.current());
            utilityState[_tokenIdCounter.current()] = 3;
        }
    }

    /// @notice Withdraw the entire balance to the owner wallet.
    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to withdraw balance");
    }

    /// @notice Withdraw an amount to the owner / admin wallet.
    /// @param value The amount to withdraw.
    function withdrawAmount(uint256 value) external {
        require(msg.sender == owner() || msg.sender == _adminAddress, "Not the owner or an admin.");
        (bool sent, ) = payable(msg.sender).call{value: value}("");
        require(sent, "Failed to withdraw balance");
    }

    /// @notice Get the remaining token utility for a given tokenId.
    /// @param tokenId The id of the token.
    function getTokenUtility(uint256 tokenId) external view returns (uint256) {
        return utilityState[tokenId];
    }

    /// @notice Set the token utility for a given tokenId.
    /// @param tokenId The id of the token. 
    /// @param utility The to set utility value.
    function setTokenUtility(uint256 tokenId, uint256 utility) external onlyOwner{
        utilityState[tokenId] = utility;
    }

    /// @notice Get the remaining whitelist passes (user-callable function)
    function getWhitelistPasses() external view returns (uint256) {
        return whitelistPasses[msg.sender];
    }

    /// @notice Get the current public limit
    function getCurrentPublicLimit() external view returns (uint256) {
        return publicCurrentLimit;
    }

    /// @notice Get the current whitelist limit
    function getCurrentWhitelistLimit() external view returns (uint256) {
        return whitelistCurrentLimit;
    }

    /// @notice Set the admin to a new address.
    /// @param admin The address of the admin's wallet.
    function setAdmin(address admin) external onlyOwner {
        _adminAddress = admin;
    }

    /// @notice Update the base url.
    /// @param url The new url.
    function setBaseUrl(string memory url) external onlyOwner {
        _baseUrl = url;
    }   

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUrl;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlEnumerable,ERC721) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}
