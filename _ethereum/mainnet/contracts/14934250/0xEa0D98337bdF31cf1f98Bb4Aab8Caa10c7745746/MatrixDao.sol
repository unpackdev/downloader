// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

import "./ERC721A.sol";
import "./IPFSConvert.sol";

error NonTransferable();
error ReachedMaxSupply();
error TransactionExpired();
error ExceedMaxAllowedMintAmount();
error IncorrectSignature();
error InsufficientPayments();
error RevealNotAllowed();
error RevealNotOwner();
error RevealNotAuthorized();
error TokenAlreadyRevealed();
error IncorrectRevealManyLength();
error TokenRevealQueryForNonexistentToken();
error NotRevealer();

/// @title MatrixDAO NFT
/// @author Teahouse Finance
contract MatrixDao is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    address private signer;
    // Test price = 0.01, Production = 2.5
    uint256 public price = 2.5 ether;
    uint256 public maxCollection;

    string public unrevealURI;
    bool public allowReveal = false;

    mapping(uint256 => bytes32) private tokenBaseURIHash;
    
    event Revealed(uint256 indexed tokenId);

    /// @param _name Name of the NFT
    /// @param _symbol Symbol of the NFT
    /// @param _initSigner Signer address of whitelist minting
    /// @param _maxCollection Maximum allowed number of tokens
    constructor(
        string memory _name,
        string memory _symbol,
        address _initSigner,            // whitelist signer address
        uint256 _maxCollection          // total supply
    ) ERC721A(_name, _symbol) {
        signer = _initSigner;
        maxCollection = _maxCollection;
    }

    /// @notice Set token minting price
    /// @param _newPrice New price in wei
    /// @dev Only owner can do this
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    /// @notice Set whitelist minting signer address
    /// @param _newSigner New signer address
    /// @dev Only owner can do this
    function setSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    /// @notice Set token URI for unrevealed tokens
    /// @param _newURI New token URI
    /// @dev Only owner can do this
    function setUnrevealURI(string calldata _newURI) external onlyOwner {
        unrevealURI = _newURI;
    }

    /// @notice Set whether to allow reveal requests
    /// @param _allowReveal true to allow reveal requests, false to disallow
    /// @dev Only owner can do this
    function setAllowReveal(bool _allowReveal) external onlyOwner {
        allowReveal = _allowReveal;
    }

    function isAuthorized(address _sender, uint32 _allowAmount, uint64 _expireTime, bytes memory _signature) private view returns (bool) {
        bytes32 hashMsg = keccak256(abi.encodePacked(_sender, _allowAmount, _expireTime));
        bytes32 ethHashMessage = hashMsg.toEthSignedMessageHash();

        return ethHashMessage.recover(_signature) == signer;
    }

    function revealAuthorized(uint256 _tokenId, bytes32 _hash, bytes memory _signature) private view returns (bool) {
        bytes32 hashMsg = keccak256(abi.encodePacked(_tokenId, _hash));
        bytes32 ethHashMessage = hashMsg.toEthSignedMessageHash();

        return ethHashMessage.recover(_signature) == signer;
    }
    /// @notice Whitelist minting
    /// @param _amount Number of tokens to mint
    /// @param _allowAmount Allowed amount of tokens
    /// @param _expireTime Expiry time
    /// @param _signature The signature signed by the signer address
    /// @dev The caller must obtain a valid signature signed by the signer address from the server
    /// @dev and pays for the correct price to mint
    /// @dev The resulting token is sent to the caller's address
    function mint(uint32 _amount, uint32 _allowAmount, uint64 _expireTime, bytes calldata _signature) external payable {
        if (totalSupply() + _amount > maxCollection) revert ReachedMaxSupply();
        if (block.timestamp > _expireTime) revert TransactionExpired();
        if (_numberMinted(msg.sender) + _amount > _allowAmount) revert ExceedMaxAllowedMintAmount();
        if (!isAuthorized(msg.sender, _allowAmount, _expireTime, _signature)) revert IncorrectSignature();

        uint256 finalPrice = price * _amount;
        if (msg.value != finalPrice) revert InsufficientPayments();
        
        _safeMint(msg.sender, _amount);
    }

    /// @notice Developer minting
    /// @param _amount Number of tokens to mint
    /// @param _to Address to send the tokens to
    /// @dev Only owner can do this
    function devMint(uint256 _amount, address _to) external onlyOwner {
        if (totalSupply() + _amount > maxCollection) revert ReachedMaxSupply();

        _safeMint(_to, _amount);
    }


    function devMintMultiple(address[] calldata _to) external onlyOwner {
        if (totalSupply() + _to.length > maxCollection) revert ReachedMaxSupply();
        
        for(uint256 i=0; i < _to.length; i++){
            _safeMint(_to[i], 1);
        }
    }

    /// @notice Request to reveal token
    /// @param _tokenId TokenId to reveal
    /// @param _hash hash of metadata from IPFS.
    /// @param _signature The signature signed by the signer address
    /// @dev Only token owner can do this.
    /// @dev The backend server will send hash of metadata and signature to set user's tokenBaseURIHash, and upload metada to IPFS.
    function reveal(uint256 _tokenId, bytes32 _hash, bytes calldata _signature) external nonReentrant {
        
        if (!allowReveal) revert RevealNotAllowed();
        if (ownerOf(_tokenId) != msg.sender) revert RevealNotOwner();
        if (!revealAuthorized(_tokenId, _hash, _signature)) revert RevealNotAuthorized();
        if (tokenBaseURIHash[_tokenId] != 0) revert TokenAlreadyRevealed();

        tokenBaseURIHash[_tokenId] = _hash;

        emit Revealed(_tokenId);
    }

    /// @notice Returns token URI of a token
    /// @param _tokenId Token Id
    /// @return uri Token URI
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
	    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        
        if (tokenBaseURIHash[_tokenId] == 0) {
            return unrevealURI;
        }
        else {
            bytes32 hash = tokenBaseURIHash[_tokenId];
            return string(abi.encodePacked("ipfs://", IPFSConvert.cidv0FromBytes32(hash)));
        }
	}

    /// @notice Returns the number of all minted tokens
    /// @return minted Number of all minted tokens
    function totalMinted() external view returns (uint256 minted) {
        return _totalMinted();
    }

    /// @notice Returns the number of all minted tokens from an address
    /// @param _minter Minter address
    /// @return minted Number of all minted tokens from the minter
    function numberMinted(address _minter) external view returns (uint256 minted) {
        return _numberMinted(_minter);
    }

    /// @notice Returns the reveal status of a token
    /// @param _tokenId Token Id
    /// @return isRevealed true if already revealed
   
    function tokenReveal(uint256 _tokenId) external view returns (bool isRevealed) {
        if (!_exists(_tokenId)) revert TokenRevealQueryForNonexistentToken();

        isRevealed = tokenBaseURIHash[_tokenId] != 0;
    }

    /// @notice Returns all tokenIds owned by an address
    /// @param _addr The address
    /// @param _startId starting tokenId
    /// @param _endId ending tokenId (inclusive)
    /// @return tokenIds Array of all tokenIds owned by the address
    /// @return endTokenId ending tokenId
    function ownedTokens(address _addr, uint256 _startId, uint256 _endId) external view returns (uint256[] memory tokenIds, uint256 endTokenId) {
        if (_endId == 0) {
            _endId = _currentIndex - 1;
        }

        if (_startId < _startTokenId() || _endId >= _currentIndex) revert TokenIndexOutOfBounds();

        uint256 i;
        uint256 balance = balanceOf(_addr);
        if (balance == 0) {
            return (new uint256[](0), _endId + 1);
        }

        if (balance > 256) {
            balance = 256;
        }

        uint256[] memory results = new uint256[](balance);
        uint256 idx = 0;
        
        address owner = ownerOf(_startId);
        for (i = _startId; i <= _endId; i++) {
            if (_ownerships[i].addr != address(0)) {
                owner = _ownerships[i].addr;
            }

            if (!_ownerships[i].burned && owner == _addr) {
                results[idx] = i;
                idx++;

                if (idx == balance) {
                    if (balance == balanceOf(_addr)) {
                        return (results, _endId + 1);
                    }
                    else {
                        return (results, i + 1);
                    }
                }
            }
        }

        uint256[] memory partialResults = new uint256[](idx);
        for (i = 0; i < idx; i++) {
            partialResults[i] = results[i];
        }        

        return (partialResults, _endId + 1);
    }

    /// @notice Withdraw funds in the NFT
    /// @param _to The address to send the funds to
    /// @dev Only owner can do this
    function withdraw(address payable _to) external payable onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success);
	}

    function _startTokenId() override internal view virtual returns (uint256) {
        // the starting token Id
        return 1;
    }

}
