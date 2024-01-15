// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

/**
 * @title contract
 * @dev Extends ERC721A
 */
contract Pirates is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;

    // mint configuration
    address public whiteListSigner; // WhiteList signer wallet address
    address public waitListSigner;  // WaitList signer wallet address
    uint256 public maxMint = 2;     // mint per wallet
    uint256 public mintPause = 1;   // 0 = unpaused , 1 = paused
    uint256 public mintPhase = 0;   // 0 = not started , 1 = whitelistMint, 2 = waitlist, 3 = publicMint

    // URI configuration
    string public baseURI;
    string private _contractURI;

    // mint key handling
    mapping(bytes => bool) public claimedKeys;
    uint256 public COLLECTION_SIZE = 3200;

    constructor(
        string memory initContractURI
    ) ERC721A("Pirates", "PIRATES") {
        _contractURI = initContractURI;
    }

    /// @notice You can mint with the mintKey (get mintKey from the piratesnft.xyz)
    /// @dev Whitelist mint function
    /// @param mintKey was generated off-chain and one address has only one key.
    function whiteListMint(bytes calldata mintKey) external nonReentrant {
        require(mintPause == 0, "Mint is not live");
        require(mintPhase == 1 || mintPhase == 2, "Whitelist mint is not live!");
        require(totalSupply() + maxMint <= COLLECTION_SIZE, "All tokens were minted out!");
        require(!claimedKeys[mintKey], "Address and MintKey was used!");
        require(checkSignature(whiteListSigner, msg.sender, mintKey), "Address is not on the Whitelist");
        claimedKeys[mintKey] = true;
        _safeMint(msg.sender, maxMint);
    }

    /// @notice You can mint with the mintKey (get mintKey from the piratesnft.xyz)
    /// @dev Waitlist mint function
    /// @param mintKey was generated off-chain and one address has only one key.
    function waitListMint(bytes calldata mintKey) external nonReentrant {
        require(mintPause == 0, "Mint is not live");
        require(mintPhase == 2, "WaitList mint is not live!");
        require(totalSupply() + maxMint <= COLLECTION_SIZE, "All tokens were minted out!");
        require(!claimedKeys[mintKey], "Address and MintKey was used!");
        require(checkSignature(waitListSigner, msg.sender, mintKey), "Address is not on the WaitList");
        claimedKeys[mintKey] = true;
        _safeMint(msg.sender, maxMint);
    }

    /// @dev Public mint function
    function publicMint() external nonReentrant {
        require(mintPause == 0, "Mint is not live");
        require(mintPhase == 3, "Public mint is not live!");
        require(totalSupply() + maxMint <= COLLECTION_SIZE, "All tokens were minted out!");
        _safeMint(msg.sender, maxMint);
    }

    /// @dev Owner mint function
    function ownerMint(uint256 _quantity, address _address) external onlyOwner nonReentrant {
        require(totalSupply() + _quantity <= COLLECTION_SIZE, "All tokens were minted out!");
        _safeMint(_address, _quantity);
    }

    // setter function for mint configuration

    function setMintConfig(uint256 _mintPause, uint256 _mintPhase) external onlyOwner {
        mintPause = _mintPause;
        mintPhase = _mintPhase;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setMintPause(uint256 _mintPause) external onlyOwner {
        mintPause = _mintPause;
    }

    function setMintPhase(uint256 _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    function setWhiteListSigner(address _signer) external onlyOwner {
        whiteListSigner = _signer;
    }

    function setWaitListSigner(address _signer) external onlyOwner {
        waitListSigner = _signer;
    }

    // metadata

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // withdrawMoney

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // burn

    /// @notice Limits the COLLECTION_SIZE to the current totalSupply
    function burn() external onlyOwner {
        COLLECTION_SIZE = totalSupply();
    }

    // verify mint key

    function checkSignature(address _signer, address sender, bytes memory signature) private pure returns (bool) {
        return _signer == 
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(uint256(uint160(sender))) // creates the 0x000000000000000000000000<sender> expected format
                )
            ).recover(signature);
    }
}