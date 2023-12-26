// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract SwissCheeseNFT is ERC721A, ReentrancyGuard, Ownable {

    /// Custom errors ///
    error WhitelistSaleIsEnded();
    error AllNftsHasBeenMintedAlready();
    error MaxMintPerWalletExceeded();
    error NotWhitelisted();
    error TryLowerAmount();
    error InvalidEthAmount();
    error WhitelistSaleIsGoingOn();
    error ETHTransferFailed();
    
    /// Mint price for different phases
    uint256 public whitelistMintPrice = 0.08 ether;
    uint256 public publicMintPrice = 0.13 ether;
    
    /// MAX SUPPLY OF COLLECTION
    uint256 public MAX_SUPPLY = 6000;
    /// MAX MINT PER WALLET
    uint256 public MAX_MINT_PER_WALLET = 10;
    /// PAYMENNT WALLET
    address public paymentWallet;
    
    /// WhiteslistMint status
    bool public whitelistMintLive;
    
    /// merkleroot
    bytes32 public merkleRoot;
    
    /// uri suffix
    string public uriSuffix = ".json";
    /// base uri
    string public baseURI = "";
   
    /// mapping to check how much a user has minted
    mapping(address => uint256) public userMinted;

    constructor() ERC721A("SwissCheese", "SWCH") Ownable(msg.sender) {
        whitelistMintLive = true;
        merkleRoot = 0x487a9eaeba0b0d7041a0541ce617ccd16852fa32914ed4ac1cc47b01f255747a;
        paymentWallet = 0x04743dF82Aa54c2ae9aaa745577E98699B3Fb6E5;
        transferOwnership(0xEA99C29AE9073ee1D57FB5Cf6092e2558c00fE73);

    }
    
  
    /// @dev whitelist mint for user
    /// @param amount: no. of nft a user want to mint
    /// @param proof: bytes32[] proof required to prove that user is in a whitelist
    function whitelistMint(uint256 amount, bytes32[] calldata proof)
        external payable
        nonReentrant
    {
        if (!whitelistMintLive) {
            revert WhitelistSaleIsEnded();
        }
        if(totalSupply() == MAX_SUPPLY){
          revert AllNftsHasBeenMintedAlready();
        }
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert TryLowerAmount();
        }
        if (userMinted[msg.sender] + amount > MAX_MINT_PER_WALLET) {
            revert MaxMintPerWalletExceeded();
        }
        bool isValid = MerkleProof.verify(
            proof,
            merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );
        if (!isValid) {
            revert NotWhitelisted();
        }
        uint256 ethRequired = amount * whitelistMintPrice;
        if(msg.value != ethRequired){
          revert InvalidEthAmount();
        }
        (bool sent,) = payable(paymentWallet).call{value: ethRequired}("");
        if(!sent){
          revert ETHTransferFailed();
        }
        userMinted[msg.sender] = userMinted[msg.sender] + amount;
        _mint(msg.sender, amount);
    }
    
    
    /// @dev public mint for users
    /// @param amount: no. of 
    function publicMint (uint256 amount) external payable nonReentrant {

        if(totalSupply() == MAX_SUPPLY){
          revert AllNftsHasBeenMintedAlready();
        }
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert TryLowerAmount();
        } 
        if (whitelistMintLive) {
            revert WhitelistSaleIsGoingOn();
        }
        
        if (userMinted[msg.sender] + amount > MAX_MINT_PER_WALLET) {
            revert MaxMintPerWalletExceeded();
        }
        uint256 ethRequired = amount * publicMintPrice;
        if(msg.value != ethRequired){
          revert InvalidEthAmount();
        }
        (bool sent,) = payable(paymentWallet).call{value: ethRequired}("");
        if(!sent){
          revert ETHTransferFailed();
        }
        userMinted[msg.sender] = userMinted[msg.sender] + amount;
        _mint(msg.sender, amount);
    }
    
    /// toggle b/w whitelist and public sale mode
    function toggleMode() external onlyOwner {
      whitelistMintLive = !whitelistMintLive;
    }
    
    /// set price for whitelist and public mint
    function setPrice(uint256 wMint, uint256 pMint) external onlyOwner {
      whitelistMintPrice = wMint;
      publicMintPrice = pMint;
    }
    
    /// set merkleroot
    function setMerkleRoot(bytes32 _merkleroot) external onlyOwner {
      merkleRoot = _merkleroot;
    }
    
    /// set base uri
    function setBaseURI(string memory __baseURI) external onlyOwner {
         baseURI = __baseURI;
    }
    
    /// set uri suffix
    function setURISuffix (string memory __suffix) external onlyOwner {
       uriSuffix = __suffix;
    }

            /// override required by solidity ///

    /// first token id
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// return token token URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)) : '';
    }

}