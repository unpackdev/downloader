// SPDX-License-Identifier: MIT
// Creative Commons License: CC0 1.0 Universal

// Creator: @SkuseNFT
// A big thankyou to @Base64Tech

pragma solidity ^0.8.13;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC721NES.sol";
import "./IStakingController.sol";
import "./Errors.sol";

// "I want an Oompa-Loompa!' screamed Veruca". ― Roald Dahl, Charlie and the Chocolate Factory”
contract TheTwoBoys is ERC721NES, OwnableUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;


    // ERC721NES is non-escrow staking so users can still keep their NFT in their own wallet
    // UUPSUpgradeable allows the contract to be upgraded w/o losing token ownership


    // +1 in these constants used for gas optimization 
    uint256 public constant TOTAL_MAX_SUPPLY = 4500 + 1; 
    uint256 public constant MAX_FREE_MINT_PER_WALLET = 1 + 1; 

    // ENUM to determine which mint phase we are performing (INACTIVE = 0, PUBLIC_MINT = 1)
    enum MintType{ INACTIVE, PUBLIC_MINT }

    // Public key used to verify signatures for minting
    address public signatureVerifier;

    // Sales state
    MintType public saleState;

    // Map to track used hashes
    mapping(bytes32 => bool) public usedHashes;

    // Maps to track number minted for each wallet
    mapping(address => uint256) public numberFreeMinted;

    string private _baseTokenURI;

    bool private initialized;

    //initializer instead of constructor
    function initialize() public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        __Ownable_init_unchained();
        __ERC721A_initialize("THETWOBOYS", "TheTwoBoys");
        __UUPSUpgradeable_init_unchained();
        saleState = MintType.INACTIVE;
    }

    /* FUNCTION MODIFIERS for cleaner code*/
    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CallerIsAnotherContract();
        _;
    }

    modifier validatePublicSaleActive() {
        if(saleState != MintType.PUBLIC_MINT) revert PublicSaleIsNotActive();
        _;
    }

    modifier underMaxSupply(uint256 _quantity) {
        if(!(_totalMinted() + _quantity < TOTAL_MAX_SUPPLY)) revert PurchaseWouldExceedMaxSupply();
        _;
    }

    modifier numberMintedUnderAllocation(uint256 _currentNumberOfMints, uint256 _quantity, uint256 _allowance) {
        uint256 totalQuantity = _currentNumberOfMints + _quantity;
        if(!(totalQuantity < _allowance)) revert MintWouldExceedMaxAllocation();
        _;
    }

    /* MINT FUNCTIONS */

    // defaults quantity to 1 because we are only allow 1 mint per user
    // doesn't actually mint token but verifies the user can mint and stores hashes
    function freeMint(bytes memory _signature, uint256 _nonce, bool _toStake) 
        external 
        callerIsUser 
        validatePublicSaleActive 
        numberMintedUnderAllocation(numberFreeMinted[msg.sender], 1, MAX_FREE_MINT_PER_WALLET)
    {
        _froopyMint(_signature, 1, _nonce, MintType.PUBLIC_MINT, _toStake);
        numberFreeMinted[msg.sender] += 1;
    }

    // actually mints the NFT
    function _froopyMint(bytes memory _signature, uint256 _quantity, uint256 _nonce, MintType mintType, bool _toStake) 
        private 
        underMaxSupply(_quantity) 
    {
        bytes32 messageHash = hashMessage(msg.sender, _nonce, mintType);
        uint256 startIndex = _currentIndex;

        if(messageHash.recover(_signature) != signatureVerifier) revert UnrecognizeableHash();
        if(usedHashes[messageHash] == true) revert HashWasAlreadyUsed();

        usedHashes[messageHash] = true;

        _mint(msg.sender, _quantity, "", false);
        
        if(_toStake) {
            for(uint256 i = startIndex; i < startIndex + _quantity; i++) {
                IStakingController(stakingController).stakeFromTokenContract(i, msg.sender);
            }
        }
    }

    /* INTERNAL FUNCTIONS */ 

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Sets external staking controller contract to be used to control staking   
     */
    function setStakingController(address _stakingController) public onlyOwner {
        _setStakingController(_stakingController);
    }


    /* UTILITY FUNCTIONS */ 

    // returns the total number of tokens minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    //gets Ownership data for a token
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }


    //hashing function to compare front end signatures to smart contract
    function hashMessage(address _sender, uint256 _nonce, MintType mintType) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_sender, _nonce, uint256(mintType)))
            )
        );
        
        return hash;
    }

    /* OWNER FUNCTIONS */


    //owner mint to owner wallet
    function ownerMint(uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(msg.sender, _numberToMint, "", false);
    }

    //owner mint and stake to owner wallet
    function ownerMintAndStake(uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        uint256 startIndex = _currentIndex;
        _mint(msg.sender, _numberToMint, "", false);

        for(uint256 i = startIndex; i < startIndex + _numberToMint; i++) {
            IStakingController(stakingController).stakeFromTokenContract(i, msg.sender);
        }
    }

    //owner mint to another wallet/address
    function ownerMintToAddress(address _recipient, uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(_recipient, _numberToMint, "", false);
    }

    //change base uri for token metadata
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    //useless for a free mint but we need it for the interface :P
    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    //set the public key used to verify signatures
    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    //set the state of the sale to active
    function setSaleActive() external onlyOwner {
        saleState = MintType.PUBLIC_MINT;
    }

    //set the state of the sale to inactive
    function pauseMint() external onlyOwner {
        saleState = MintType.INACTIVE;
    }

    //upgrade contract to new implementation
   function _authorizeUpgrade(address) internal override onlyOwner {}
}