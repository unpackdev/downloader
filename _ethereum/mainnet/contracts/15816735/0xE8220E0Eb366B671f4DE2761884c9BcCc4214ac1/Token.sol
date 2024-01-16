// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Sig.sol";

contract Token is ERC721Enumerable , Ownable, ReentrancyGuard {

    // ======== Metadata =========
    string public baseTokenURI;


    // ======== Sale Status =========
    bool public saleIsActive = false;

    // ======== Claim Tracking =========
    event Minted(address indexed signer, uint256 tokenId);

    // ======== Signature Management =========
    address public authProvider;

    event AuthProviderChanged(address indexed authProvider);

    constructor(string memory baseURI, address _authProvider) ERC721 ("Metaverse Spectrum NFT", "Spectrum2022") {    
        setBaseURI(baseURI);    
        updateAuthProvider(_authProvider);
    }

    function updateAuthProvider(address _authProvider) public onlyOwner {
        authProvider = _authProvider;
        emit AuthProviderChanged(authProvider);
    }

    /// @notice Recovers the signer from the given signature
    /// @param message The hash of the message that was signed
    /// @param r The r part of the signature
    /// @param s The s part of the signature
    /// @param v The v part of the signature
    /// @return the signer account
    function getSigner(bytes32 message, bytes32 r, bytes32 s, uint8 v) private pure returns(address){
        return Sig.getSigner(message, v, r, s);
    }

    // ======== Mint Functions =========
    /// @notice Mint a single token
    /// @param nonce The nonce part of the signature
    /// @param r The r part of the signature
    /// @param s The s part of the signature
    /// @param v The v part of the signature
    function mint(
        bytes32 nonce,
        bytes32 r,
        bytes32 s,
        uint8 v
        ) public nonReentrant {
        require(msg.sender == tx.origin, "Mint: not allowed from contract");
        require(saleIsActive, "Sale is not active!");
            
        bytes32 message = keccak256(abi.encodePacked(msg.sender, nonce));

        address signer = getSigner(message,r, s ,v);

        require(signer == authProvider, "invalid mint ticket");

        uint256 totalSupply = totalSupply();
        _safeMint(msg.sender, totalSupply + 1);
        emit Minted(msg.sender, totalSupply);
    }
    
    // ======== Metadata =========
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // ======== State Management =========
    /// @notice Toggle sale state
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    // ======== Withdraw =========
    /// @notice Withdraw funds to contract owners address
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }
}