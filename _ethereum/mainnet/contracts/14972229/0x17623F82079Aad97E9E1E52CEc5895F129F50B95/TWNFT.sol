// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./ERC2981.sol";


contract TWNFT is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    uint256 public constant NUMBER_OF_DEFENDER = 14777;         
    uint256 public constant NUMBER_OF_CONQUEROR = 8888;         
    uint256 public constant NUMBER_OF_RESERVED_CONQUEROR = 500;

    uint256 public maxPerTx = 11;             
    uint256 public maxAllowedPerAddress = 6;  

    uint256 public mintPriceDefender = 0.5 ether;
    uint256 public mintPriceConqueror = 0.8 ether;
    uint256 public defenderMinted;
    uint256 public conquerorMinted;
    uint256 public burned;

    uint256 public supplyLimitDefender;
    uint256 public supplyLimitConqueror;

    uint256 private _tokenIdDefender = 1;
    uint256 private _tokenIdConqueror = 14778;

    string private _defaultUri;
    string private _tokenBaseURI;

    address private adminSigner;

    enum SalePhase {
        Locked,
        PreSale,
        PublicSale,
        LimitedSale
    }

    SalePhase public phase = SalePhase.Locked;
    bool public metadataIsFrozen = false;

    mapping(address => bool) public proxyToApproved;
    mapping(address => uint256) public addressToMintedDefender;
    mapping(address => uint256) public addressToMintedConqueror;
    mapping(address => uint256) public addressToMintedLimitedConqueror;

    constructor(
        string memory _baseURI, 
        address _royaltyRecipient, 
        address _adminSigner) 
    ERC721("TWCollection","NFT") {
        _defaultUri = _baseURI;
        _setRoyalties(_royaltyRecipient, 1000); // 10% royalties
        setAdminSigner(_adminSigner);
    }

    // ======================================================== Owner Functions

    /// Set the adminSigner address
    function setAdminSigner(address _adminSigner) public onlyOwner {
        adminSigner = _adminSigner;
    }

    /// Set the collection royalties
    function setRoyalties(address _recipient, uint256 _value) public onlyOwner {
        _setRoyalties(_recipient, _value);
    }

    /// Set communication pipeline between contracts
    function flipProxyState(address proxyAddress) external onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

	/// Set the base URI for the metadata
	/// @dev modifies the state of the `_tokenBaseURI` variable
	/// @param URI the URI to set as the base token URI
    function setBaseURI(string memory URI) external onlyOwner {
        require(!metadataIsFrozen, 'TW: Metadata is permanently frozen');
        _tokenBaseURI = URI;
    }

	/// Freezes the metadata
	/// @dev sets the state of `metadataIsFrozen` to true
	/// @notice permamently freezes the metadata so that no more changes are possible
	function freezeMetadata() external onlyOwner {
		require(!metadataIsFrozen, 'TW: Metadata is already frozen');
		metadataIsFrozen = true;
	}

    /// @dev modifies the state of the `supplyLimitDefender` and `supplyLimitConqueror`
    /// @param _supplyLimitDefender The new amount of presale supply limit of Defender
    /// @param _supplyLimitConqueror The new amount of presale supply limit of Conqueror
    function setSupplyLimit(uint256 _supplyLimitDefender, uint256 _supplyLimitConqueror) external onlyOwner {
        supplyLimitDefender = _supplyLimitDefender;
        supplyLimitConqueror = _supplyLimitConqueror;
    }

    /// @dev modifies the state of the `maxPerTx`
    function updateMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    /// @dev modifies the state of the `maxAllowedPerAddress`
    function updateMaxAllowedPerAddress(uint256 _maxAllowedPerAddress) external onlyOwner {
        maxAllowedPerAddress = _maxAllowedPerAddress;
    }

    /// Adjust the mint prices
	/// @dev modifies the state of the `mintPriceDefender` and `mintPriceConqueror` variables
	/// @notice sets the price for minting a token
	/// @param _newPriceDefender The new price for minting of Defender
    /// @param _newPriceConqueror The new price for minting of Conqueror
    function adjustMintPrice(uint256 _newPriceDefender, uint256 _newPriceConqueror) external onlyOwner {
        mintPriceDefender = _newPriceDefender;
        mintPriceConqueror = _newPriceConqueror;
    }

	/// Update Phase
	/// @dev Update the sale phase state
    function enterPhase(SalePhase _phase) external onlyOwner {
        phase = _phase;
    }

    /// Allows to configure sale phase
    function configureSalephase(
        SalePhase _phase, 
        uint256 _newPriceDefender, 
        uint256 _newPriceConqueror, 
        uint256 _supplyLimitDefender, 
        uint256 _supplyLimitConqueror
    ) external onlyOwner {
        phase = _phase;
        mintPriceDefender = _newPriceDefender;
        mintPriceConqueror = _newPriceConqueror;
        supplyLimitDefender = _supplyLimitDefender;
        supplyLimitConqueror = _supplyLimitConqueror;
    }

    /// @dev withdraw funds to the address
    /// @param fundsReceiver address of funds receiver
    function withdraw(address fundsReceiver) public payable onlyOwner {
        (bool success, ) = payable(fundsReceiver).call{value: address(this).balance}('');
        require(success, 'TW: Withdraw failed');
    }

    // ======================================================== External Functions

    /// Mint Defender during presale
    /// @dev mints by addresses
    /// @param count number of tokens to mint in transaction
    /// @notice mints tokens with counter token IDs to addresses eligible for presale
    /// @notice tokens number of presale mints allowed is maxAllowedPerAddress - 1
    /// @notice supplyLimitDefender updates during all presale iterations, supplyLimitDefender <= NUMBER_OF_DEFENDER
    function presaleMintDefender(uint256 count, bytes memory signature) external payable validateEthPaymentDefender(count) {
        require(phase == SalePhase.PreSale, 'TW: Presale event is not active.');
        _validateSignature(signature);
        
        require(addressToMintedDefender[_msgSender()] + count < maxAllowedPerAddress, 'TW: Exceeds number of presale mints allowed.');
        if (supplyLimitDefender > 0) {
            require(defenderMinted + count <= supplyLimitDefender, 'TW: Exceeds max presale supply of Defender.');
        }
        require(defenderMinted + count <= NUMBER_OF_DEFENDER, 'TW: Exceeds max supply of Defender.');
        
        addressToMintedDefender[_msgSender()] += count;
        _mintDefenders(_msgSender(), count);
        defenderMinted += count;
    }

    /// Mint Conqueror during presale
    /// @dev mints by addresses
    /// @param count number of tokens to mint in transaction
    /// @notice mints tokens with counter token IDs to addresses eligible for presale
    /// @notice tokens number of presale mints allowed is maxAllowedPerAddress - 1
    /// @notice supplyLimitConqueror updates during all presale iterations, supplyLimit <= NUMBER_OF_CONQUEROR - NUMBER_OF_RESERVED_CONQUEROR
    function presaleMintConqueror(uint256 count, bytes memory signature) external payable validateEthPaymentConqueror(count) {
        require(phase == SalePhase.PreSale, 'TW: Presale event is not active.');
        _validateSignature(signature);
        
        require(addressToMintedConqueror[_msgSender()] + count < maxAllowedPerAddress, 'TW: Exceeds number of presale mints allowed.');
        if (supplyLimitConqueror > 0) {
            require(conquerorMinted + count <= supplyLimitConqueror, 'TW: Exceeds max presale supply of Conqueror.');
        }
        require(conquerorMinted + count <= NUMBER_OF_CONQUEROR - NUMBER_OF_RESERVED_CONQUEROR, 'TW: Exceeds max supply of Conqueror.');
        
        addressToMintedConqueror[_msgSender()] += count;
        _mintConquerors(_msgSender(), count);
        conquerorMinted += count;
    }

	/// @dev mints tokens during public sale
	/// @param count number of tokens to mint in transaction
    /// @notice tokens number per transaction is maxPerTx - 1
    function publicMintDefender(uint256 count) external payable validateEthPaymentDefender(count) {
        require(phase == SalePhase.PublicSale, 'TW: Public sale is not active');
        require(defenderMinted + count <= NUMBER_OF_DEFENDER, 'TW: Exceeds max supply of Defender.');
        require(count < maxPerTx, 'TW: Exceeds max per transaction.');

        _mintDefenders(_msgSender(), count);
        defenderMinted += count;
    }

	/// @dev mints tokens during public sale
	/// @param count number of tokens to mint in transaction
    /// @notice tokens number per transaction is maxPerTx - 1
    function publicMintConqueror(uint256 count) external payable validateEthPaymentConqueror(count) {
        require(phase == SalePhase.PublicSale, 'TW: Public sale is not active.');
        require(conquerorMinted + count <= NUMBER_OF_CONQUEROR - NUMBER_OF_RESERVED_CONQUEROR, 'TW: Exceeds max supply of Conqueror.');
        require(count < maxPerTx, 'TW: Exceeds max per transaction.');

        _mintConquerors(_msgSender(), count);
        conquerorMinted += count;
    }

    /// @dev mints tokens during limited sale
    /// @param count number of tokens to mint in transaction
    /// @notice tokens number of presale mints allowed is maxAllowedPerAddress - 1
    function reserveMintConqueror(uint256 count, bytes memory signature) external payable validateEthPaymentConqueror(count) {
        require(phase == SalePhase.LimitedSale, 'TW: Limited sale is not active.');
        _validateSignature(signature);

        require(addressToMintedLimitedConqueror[_msgSender()] + count < maxAllowedPerAddress, 'TW: Exceeds number of mints allowed.');
        require(conquerorMinted + count <= NUMBER_OF_CONQUEROR, 'TW: Exceeds max supply of Conqueror.');
        
        addressToMintedLimitedConqueror[_msgSender()] += count;
        _mintConquerors(_msgSender(), count);
        conquerorMinted += count;
    }

    // ======================================================== Internal Functions

    /// @dev perform actual minting of the tokens
    function _mintDefenders(address to, uint256 count) internal {
        for (uint256 index = 0; index < count; index++) {
            _mint(to, _tokenIdDefender);
            unchecked {
                _tokenIdDefender++;
            }
        }
    }

    /// @dev perform actual minting of the tokens
    function _mintConquerors(address to, uint256 count) internal {
        for (uint256 index = 0; index < count; index++) {
            _mint(to, _tokenIdConqueror);
            unchecked {
                _tokenIdConqueror++;
            }
        }
    }

    /// @dev validate signature
    function _validateSignature(bytes memory signature) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(_msgSender()));
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature) == getAdminSigner(), 'TW: Signature invalid or unauthorized.');
    }

	// ======================================================== Modifiers

	/// @dev compares the product of the state variable `mintPriceDefender` and supplied `count` to msg.value
	/// @param count factor to multiply by
    modifier validateEthPaymentDefender(uint256 count) {
        require((mintPriceDefender * count) == msg.value, 'TW: Ether value sent is not correct');
        _;
    }

	/// @dev compares the product of the state variable `mintPriceConqueror` and supplied `count` to msg.value
	/// @param count factor to multiply by
    modifier validateEthPaymentConqueror(uint256 count) {
        require((mintPriceConqueror * count) == msg.value, 'TW: Ether value sent is not correct');
        _;
    }

    // ======================================================== Public

    /// Return the totalSupply
    function totalSupply() public view returns (uint256) {
        return defenderMinted + conquerorMinted - burned;
    }

    /// Get the adminSigner address
    function getAdminSigner() public view returns (address) {
        return adminSigner;
    }

    /// @dev Burns `tokenId`
    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TW: Not approved to burn.");
        _burn(tokenId);
        unchecked {
            burned++;
        }
    }

    /// @dev Batch transfer from
    function batchTransferFrom(address from, address to, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    /// @dev Batch safe transfer from
    function batchSafeTransferFrom(address from, address to, uint256[] memory tokenIds, bytes memory data) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i], data);
        }
    }

    // ======================================================== Overrides

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// Return the tokenURI for a given ID
	/// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a custom URI
	/// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been suppleid with a unique custom URI
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), 'TW: Cannot query non-existent token');

		return
			bytes(_tokenBaseURI).length > 0
				? string(
					abi.encodePacked(_tokenBaseURI, '/', tokenId.toString())
				)
				: _defaultUri;
	}

    /// @dev Allow gas less future collection approval for cross-collection interaction.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (proxyToApproved[operator]) return true;
        return super.isApprovedForAll(owner, operator);
    }
}