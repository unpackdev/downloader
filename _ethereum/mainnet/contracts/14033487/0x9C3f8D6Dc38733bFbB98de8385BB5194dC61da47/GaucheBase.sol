// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./LibGauche.sol";

import "./ERC721A.sol";
import "./Ownable.sol";

/// @title A contract that implements the sale state machine
/// @author Yuut - Soc#0903
/// @notice This contract implements the sale state machine.
abstract contract GaucheBase is ERC721A, Ownable {
    /// @notice Tier 0 artist address. Yes we save this elsewhere, but this is used specifically for the public sale.
    address public artistAddress;

    /// @notice Developer address. Maintains the contract and allows for the dev to get paid.
    address public developerAddress;

    /// @notice Sale state machine. Holds all defs related to token sale.
    GaucheSale internal sale;

    /// @notice Controls the proof of use for Wassilike tokens.
    mapping(uint256 => bool) public accessTokenUsed;

    /// @notice Controls the contract URI
    string internal ContractURI = "https://neophorion.art/api/projects/GaucheGrimoire/contractURI";

    /// @notice Sale status event for front end event listeners.
    /// @param state Controls the frontend sale state.
    event SaleStateChanged(SalesState state);

/// @notice Creates a new instance of the contract and sets required params before initialization.
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint64 _pricePerToken,
        address _accessTokenAddress,
        address _artistAddress,
        address _developerAddress
    ) ERC721A(_tokenName, _tokenSymbol, 10, 3333) {
        sale = GaucheSale(SalesState.Closed, 0x0BB9, _pricePerToken, _accessTokenAddress);
        artistAddress = _artistAddress;
        developerAddress = _developerAddress;
    }

    /// @notice Confirms the caller owns the token
    /// @param _tokenId The token id to check ownership of
    modifier onlyIfTokenOwner(uint256 _tokenId) {
        _checkTokenOwner(_tokenId);
        _;
    }

    /// @notice Confirms the sale mode is in the matching state
    /// @param _mode Mode to Match
    modifier isMode(SalesState _mode) {
        _checkMode(_mode);
        _;
    }

    /// @notice Confirms the sale mode is NOT in the matching state
    /// @param _mode Mode to Match
    modifier isNotMode(SalesState _mode) {
        _checkNotMode(_mode);
        _;
    }

    /// @notice MultiMint to allow multiple tokens to be minted at the same time. Price is .0777e per count
    /// @param _count Total number of tokens to mint
    /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function multiMint(uint256 _count) public payable isMode(SalesState.Active) returns (uint256[] memory _tokenIds) {
        uint256 price = sale.pricePerToken * _count;
        require(msg.value >= price, "GG: Ether amount is under set price");
        require(_count >= 1, "GG: Token count must be 1 or more");
        require(totalSupply() < sale.maxPublicTokens, "GG: Max tokens reached");

        return  _mintToken(_msgSender(), _count, true);
    }

    /// @notice Single mint to allow high level tokens to be minted. Price is .0777e per count
    /// @param _count Total number of levels to mint with
    /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function mint(uint256 _count) public payable isMode(SalesState.Active) returns (uint256[] memory _tokenIds) {
        uint256 price = sale.pricePerToken * _count;
        require(msg.value >= price, "Ether amount is under set price");
        require(_count >= 1, "GG: Min Lvl 1"); // Must buy atleast 1 level, since all tokens start at level 1
        require(_count <= 255, "GG: Max 255 lvl"); // We stop at 254 because we have a max combined level of 255, as all tokens start at level 1
        require(totalSupply() + _count < sale.maxPublicTokens, "GG: Max tokens reached");

        return  _mintToken(_msgSender(), _count, false);
    }

    /// @notice Single mint to allow level 3 tokens to be minted using a Wassilikes token
    /// @param _tokenId Wassilikes Token Id
     /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function mintAccessToken(uint256 _tokenId) isMode(SalesState.AccessToken) public payable returns (uint256[] memory _tokenIds) {
        require(msg.value >= sale.pricePerToken, "Ether amount is under set price");
        IERC721 accessToken = IERC721(sale.accessTokenAddress);
        require(accessToken.ownerOf(_tokenId) == _msgSender(), "Access token not owned");
        require(accessTokenUsed[_tokenId] == false, "Access token already used");

        accessTokenUsed[_tokenId] = true;

        // Wassilikes holders get 1 mint with 3 levels.
        return _mintToken(_msgSender(), 3, false);
    }

    /// @notice Mints reserved tokens for artist + developer + team
    /// @return _tokenIds An array of tokenids, 1 entry per token minted.
    function reservedMint() isMode(SalesState.Closed) onlyOwner public returns (uint256[] memory _tokenIds) {
        require(totalSupply() < 20, "GG: Must be less than 20");
        _mintToken(owner(), 1, false); // The owner takes token 0 to prevent it from ever destroying state
        _mintToken(artistAddress, 10, false); // Artist and dev get 10 levels to ensure all art can be minted later
        _mintToken(developerAddress, 10, false);
        _mintToken(owner(), 10, true); // 10 tokens are the max mint
        _mintToken(owner(), 7, true); // 7 tokens this wraps up the giveaway reservations
    }

    /// @notice Used for checking if a token has been used for claiming or not.
    /// @param _tokenId Wassilikes Token Id
    /// @return bool True if used, false if not
    function checkIfAccessTokenIsUsed(uint256 _tokenId) public view returns (bool) {
        return accessTokenUsed[_tokenId];
    }

    /// @notice Grabs the sale state from the contract
    /// @return uint The current sale state
    function getSaleState() public view returns(uint)  {
        return uint(sale.saleState);
    }

    /// @notice Grabs the contractURI
    /// @return string The current URI for the contract
    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    /// @notice Cha-Ching. Heres how we get paid!
    function withdrawFunds() public onlyOwner {
        uint256 share =  address(this).balance / 20;
        uint256 artistPayout = share * 13;
        uint256 developerPayout =   share * 7;

        if (artistPayout > 0) {
            (bool sent, bytes memory data) = payable(artistAddress).call{value: artistPayout}("");
            require(sent, "Failed to send Ether");
        }

        if (developerPayout > 0) {
            (bool sent, bytes memory data) =  payable(developerAddress).call{value: developerPayout}("");
            require(sent, "Failed to send Ether");
        }
    }

    /// @notice Pushes the sale state forward. Can skip to any state but never go back.
    /// @param _state the integer of the state to move to
    function updateSaleState(SalesState _state) public onlyOwner {
        require(sale.saleState != SalesState.Finalized, "GB: Can't change state if Finalized");
        require( _state > sale.saleState, "GB: Can't reverse state");
        sale.saleState = _state;
        emit SaleStateChanged(_state);
    }

    /// @notice Changes the contractURI
    /// @param _contractURI The new contracturi
    function updateContractURI(string memory _contractURI) public onlyOwner {
        ContractURI = _contractURI;
    }

    /// @notice Changes the artists withdraw address
    /// @param _artistAddress The new address to withdraw to
    function updateArtistAddress(address _artistAddress) public {
        require(msg.sender == artistAddress, "GB: Only artist");
        artistAddress = _artistAddress;
    }

    /// @notice Changes the developers withdraw address
    /// @param _developerAddress The new address to withdraw to
    function updateDeveloperAddress(address _developerAddress) public  {
        require(msg.sender == developerAddress, "GB: Only dev");
        developerAddress = _developerAddress;
    }

    function _checkMode(SalesState _mode) internal view {
        require(_mode == sale.saleState ,"GG: Contract must be in matching mode");
    }

    function _checkNotMode(SalesState _mode) internal view {
        require(_mode != sale.saleState ,"GG: Contract must not be in matching mode");
    }

    function _checkTokenOwner(uint256 _tokenId) internal view {
        require(ERC721A.ownerOf(_tokenId) == _msgSender(),"ERC721: Must own token to call this function");
    }

    function _mintToken(address _toAddress, uint256 _count, bool _batch) internal virtual returns (uint256[] memory _tokenId);
}