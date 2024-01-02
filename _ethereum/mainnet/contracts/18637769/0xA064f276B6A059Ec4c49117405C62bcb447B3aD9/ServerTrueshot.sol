// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./IERC2981.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

contract TrueTokens is ERC20, ReentrancyGuard {
    uint256 private constant TOKEN_PRICE = 0.02 ether;
    uint256 private constant MAX_TOKENS_PER_TX = 50 * 10**18;

    address payable private immutable _owner;

    constructor(address to) ERC20("TrueshotToken", "TRUE") {
        _owner = payable(to);
        _mint(to, 100000 * 1e18);
    }

    function buyTokens() public payable nonReentrant {
        require(msg.value >= TOKEN_PRICE, "Insufficient Ether sent");

        uint256 amountToMint = (msg.value * 50) / (1 ether / 10**decimals());

        require(amountToMint <= MAX_TOKENS_PER_TX, "You can buy at most 6 tokens per transaction");
        require(balanceOf(_owner) >= amountToMint, "Insufficient tokens in contract owner's balance");

        _transfer(_owner, msg.sender, amountToMint);

        uint256 amountEtherUsed = (amountToMint * 1 ether) / (50 * 10**decimals());

        uint256 excessEther = msg.value - amountEtherUsed;

        _owner.transfer(amountEtherUsed);

        if (excessEther > 0) {
            payable(msg.sender).transfer(excessEther);
        }
    }
}

contract Trueshot is ERC721, ERC721URIStorage, IERC2981 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IERC20 private _trueTokens;
    address private _owner;
    uint256 private _mintFee;
    uint256 private _royaltyFee;
    mapping(address => bool) private _serverAddresses;
    uint256 private constant chainId = 80001; // Replace with your chainId

    event LogDigest(bytes32 indexed digest);
    event LogRecoveredSigner(address indexed signer);
    event LogNonceMismatch(uint256 providedNonce, uint256 expectedNonce);
    event NFTMinted(uint256 tokenId);
    event LogDomainSeparator(bytes32 domainSeparator);
    event LogSignatureComponents(bytes32 indexed r, bytes32 indexed s, uint8 v);

    bytes32 constant MINT_TYPEHASH = keccak256("MintRequest(address recipient,string tokenURI,uint256 nonce)");
    bytes32 private DOMAIN_SEPARATOR;
    mapping(address => uint) public nonces;

    constructor(IERC20 trueTokens) ERC721("Trueshot", "TRUENFT") {
        _owner = msg.sender;
        _mintFee = 1;
        _royaltyFee = 500;

        _serverAddresses[msg.sender] = true;
        // Initialize _trueTokens with the hardcoded address
        _trueTokens = trueTokens;
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("Trueshot")),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        emit LogDomainSeparator(DOMAIN_SEPARATOR);
    }

function mintNFT(
  address recipient, 
  string calldata _tokenURI, 
  uint256 nonce, 
  bytes calldata signature
) 
external 
returns (uint256) {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01", 
        DOMAIN_SEPARATOR, 
        keccak256(
          abi.encode(
            MINT_TYPEHASH, 
            recipient, 
            keccak256(bytes(_tokenURI)), 
            nonce
          )
        )
      )
    );
    
    emit LogDigest(digest);

    // Break signature down into `v`, `r`, and `s`
    bytes32 r;
    bytes32 s;
    uint8 v;

bytes memory memSignature = new bytes(signature.length);
assembly {
    calldatacopy(memSignature, signature.offset, signature.length)
}


// Divide the signature into r, s and v variables
assembly {
    r := mload(memSignature)  // Start reading directly from the start
    s := mload(add(memSignature, 32))  // Start reading from the 32nd byte
    v := byte(0, mload(add(memSignature, 64))) // Start reading from the 64th byte (for v, but only take the first byte)
}

    
    // New code to adjust the v value
    if (v < 27) {
            v += 27;
        }

    emit LogSignatureComponents(r, s, v);

    address signer = ecrecover(digest, v, r, s);
    
    emit LogRecoveredSigner(signer);

    require(signer != address(0), 'Invalid signature: Signer is zero address');
    require(_serverAddresses[signer], 'Invalid signature: Signer is not a recognized server address');
    require(nonces[recipient] == nonce, 'Invalid nonce');
    nonces[recipient]++;
    return _customMint(_tokenURI);
}



function _customMint(string memory uri) internal returns (uint256) {
    require(_trueTokens.balanceOf(msg.sender) >= _mintFee, "Insufficient token balance for mint fee");
    require(_trueTokens.allowance(msg.sender, address(this)) >= _mintFee, "Contract not approved to transfer enough tokens for mint fee");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    _setTokenURI(newItemId, uri);
    _trueTokens.transferFrom(msg.sender, _owner, _mintFee);
    emit NFTMinted(newItemId);
    return newItemId;
}

function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
}

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (_owner, (salePrice * _royaltyFee) / 10000);
    }

    function getMintFee() public view returns (uint256) {
        return _mintFee;
    }

    function setMintFee(uint256 newMintFee) public {
        require(msg.sender == _owner);
        _mintFee = newMintFee;
    }

    function getRoyaltyFee() public view returns (uint256) {
        return _royaltyFee;
    }

    function setRoyaltyFee(uint256 newRoyaltyFee) public {
        require(msg.sender == _owner);
        _royaltyFee = newRoyaltyFee;
    }

    function addServerAddress(address serverAddress) public {
        require(msg.sender == _owner);
        _serverAddresses[serverAddress] = true;
    }

    function removeServerAddress(address serverAddress) public {
        require(msg.sender == _owner);
        _serverAddresses[serverAddress] = false;
    }
}