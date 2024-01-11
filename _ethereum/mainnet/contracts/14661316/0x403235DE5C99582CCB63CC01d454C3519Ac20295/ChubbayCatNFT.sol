// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 ######  ##     ## ##     ## ########  ########  ##    ##     ######     ###    ########    ##    ## ######## ######## 
##    ## ##     ## ##     ## ##     ## ##     ##  ##  ##     ##    ##   ## ##      ##       ###   ## ##          ##    
##       ##     ## ##     ## ##     ## ##     ##   ####      ##        ##   ##     ##       ####  ## ##          ##    
##       ######### ##     ## ########  ########     ##       ##       ##     ##    ##       ## ## ## ######      ##    
##       ##     ## ##     ## ##     ## ##     ##    ##       ##       #########    ##       ##  #### ##          ##    
##    ## ##     ## ##     ## ##     ## ##     ##    ##       ##    ## ##     ##    ##       ##   ### ##          ##    
 ######  ##     ##  #######  ########  ########     ##        ######  ##     ##    ##       ##    ## ##          ## 
*/

/**
---- SOCIAL MEDIA LINKS ---

Web: https://chubbycat.io
Twitter: https://twitter.com/nftchubbycat
Instagram: https://www.instagram.com/chubbycatnft/
Discord: https://discord.com/invite/chubbycatnft

*/

/// Developed by WeCare Labs : https://t.me/wecarelabs
/// @custom:security-contact security@wecarelabs.org
contract ChubbayCatNFT is ERC721Enumerable, ERC721Royalty, Pausable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public notRevealedUri;
    string public baseExtension = ".json";

    uint public totalRound = 3;
    uint public activeRound = 0;

    uint public maxSupply = 10000;
    uint public maxMintAmountPerAddress = 10;

    bool public isBurnable = false;
    bool public onlyWhitelisted = true;

    address public royaltyReceiver;
    address public immutable WeCareCharityWallet = 0xfE4abecf0480CdD528012226054DDB0A3dA18106;
    address[] public whitelistedAddresses;

    // Total minted amount per address
    mapping(address => uint) public addressMintedBalance;
    // Round 1 => 0.07 ether
    mapping(uint => uint) public prices;
    // Round 1 => 2500
    mapping(uint => uint) public maxMintPerRound;
    // Round 1 => 0.06 ether
    mapping(uint => uint) public whitelistPrice;
    // base uri address by roundId
    mapping(uint => string) public baseUris;
    // check if ipfs address revealed by round
    mapping(uint => bool) public reveals;

    event Minted(address indexed _address, uint _amount);
    event SetRoyalityInfo(uint96 _feeNumerator);
    event SetRoyalityForToken(uint _tokenId, uint96 _feeNumerator);
    event SetNotRevealedURI(string _notRevealedURI);
    event SetmaxMintAmountPerAddress(uint _newmaxMintAmount);
    event RevealRound(uint _roundId, bool _value);
    event SetActiveRound(uint _roundId);
    event SetPrice(uint _roundId, uint _price);
    event SetWhitelistPrice(uint _roundId, uint _price);
    event SetMaxMintPerRound(uint _roundId, uint _amount);
    event ToggleBurnable(bool _value);
    event ToggleWhitelisted(bool _value);
    event SetBaseUri(uint _roundId, string _baseUri);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri,
        uint[] memory _totalRounds,
        uint[] memory _whitelistPrices,
        uint[] memory _prices,
        uint[] memory _maxMintPerRound,
        uint96 _royalityFee
    ) ERC721(_name, _symbol) {
        setNotRevealedURI(_initNotRevealedUri);
        royaltyReceiver = address(this);

        setWhitelistPrice(_totalRounds, _whitelistPrices);
        setPrice(_totalRounds, _prices);
        setMaxMintPerRound(_totalRounds, _maxMintPerRound);
        _setDefaultRoyalty(royaltyReceiver, _royalityFee);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint _mintAmount) external payable whenNotPaused nonReentrant {
        require(activeRound > 0, "No active round!");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        
        uint supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(supply + _mintAmount <= maxMintPerRound[activeRound], "Max Mint amount reached for this round");
        require(addressMintedBalance[msg.sender] + _mintAmount <= maxMintAmountPerAddress, "max NFT per address exceeded");

        if (msg.sender != owner()) {
            if(onlyWhitelisted) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                require(msg.value >= whitelistPrice[activeRound] * _mintAmount, "insufficient funds");
            } else {
                require(msg.value >= prices[activeRound] * _mintAmount, "insufficient funds");
            }
        }
        
        for (uint i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }

        emit Minted(msg.sender, _mintAmount);
    }

    function safeMint(address to) external onlyOwner {
        uint tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint tokenId) internal override(ERC721, ERC721Royalty) {
        require(isBurnable, "Burn action disabled!");

        super._burn(tokenId);
    }

    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint _tokenRoundId = _getTokenRound(tokenId);
        if (!reveals[_tokenRoundId]) return notRevealedUri;

        string memory __baseURI = baseUris[_tokenRoundId];
    
        return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, tokenId.toString(), baseExtension)) : "";
    }

    function _getTokenRound(uint _tokenId) internal view returns (uint) {
        for (uint _i = 1; _i <= totalRound; _i++) {
            if (_tokenId <= maxMintPerRound[_i]) return _i;
        }

        return 0;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Royalty, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// Set Default Royality address and fee (%5 = 500)
    function setDefaultRoyality(uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, _feeNumerator);

        emit SetRoyalityInfo(_feeNumerator);
    }

    function setRoyalityForToken(uint256 _tokenId, uint96 _feeNumerator) external onlyOwner {
        _setTokenRoyalty(_tokenId, royaltyReceiver, _feeNumerator);

        emit SetRoyalityForToken(_tokenId, _feeNumerator);
    }

    //// Additions
    function _baseURI() internal view override(ERC721) returns (string memory) {
        for (uint _i = 1; _i <= totalRound; _i++) {
            if (!reveals[_i]) return notRevealedUri;
        }

        return baseUris[1];
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;

        emit SetNotRevealedURI(_notRevealedURI);
    }

    function setmaxMintAmountPerAddress(uint _newmaxMintAmount) external onlyOwner {
        maxMintAmountPerAddress = _newmaxMintAmount;

        emit SetmaxMintAmountPerAddress(_newmaxMintAmount);
    }

    function revealRound(uint _roundId, bool _value) external onlyOwner {
        reveals[_roundId] = _value;

        emit RevealRound(_roundId, _value);
    }

    /// Whitelist
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) return true;
        }

        return false;
    }

    function whitelistUsers(address[] calldata _users) external onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setActiveRound(uint _roundId) external onlyOwner {
        activeRound = _roundId;

        emit SetActiveRound(_roundId);
    }

    function setPrice(uint[] memory _roundIds, uint[] memory _prices) public onlyOwner {
        uint _length = _roundIds.length;
        require(_length <= totalRound, "limit excceded");

        for (uint i = 0; i < _length; i++) {
            prices[_roundIds[i]] = _prices[i];

            emit SetPrice(_roundIds[i], _prices[i]);
        }
    }

    function setWhitelistPrice(uint[] memory  _roundIds, uint[] memory _prices) public onlyOwner {
        uint _length = _roundIds.length;
        require(_length <= totalRound, "limit excceded");

        for (uint i = 0; i < _length; i++) {
            whitelistPrice[_roundIds[i]] = _prices[i];

            emit SetWhitelistPrice(_roundIds[i], _prices[i]);
        }
    }

    // 1 => 2500, 2 => 5000, 3 => 10000
    function setMaxMintPerRound(uint[] memory _roundIds, uint[] memory _amounts) public onlyOwner {
        uint _length = _roundIds.length;
        require(_length <= totalRound, "limit excceded");

        for (uint i = 0; i < _length; i++) {
            maxMintPerRound[_roundIds[i]] = _amounts[i];

            emit SetMaxMintPerRound(_roundIds[i], _amounts[i]);
        }
    }

    function toggleBurnable() external onlyOwner {
        isBurnable = !isBurnable;

        emit ToggleBurnable(!isBurnable);
    }

    function toggleWhitelisted() external onlyOwner {
        onlyWhitelisted = !onlyWhitelisted;

        emit ToggleWhitelisted(!onlyWhitelisted);
    }

    function setBaseUris(uint[] calldata _roundIds, string[] calldata _baseUris) external onlyOwner {
        uint _length = _roundIds.length;
        require(_length <= totalRound, "limit excceded");

        for (uint i = 0; i < _length; i++) {
            baseUris[_roundIds[i]] = _baseUris[i];

            emit SetBaseUri(_roundIds[i], _baseUris[i]);
        }
    }

    function withdraw() external onlyOwner {
        (bool wcr, ) = payable(WeCareCharityWallet).call{value: address(this).balance * 5 / 100}("");
        require(wcr);
        
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
