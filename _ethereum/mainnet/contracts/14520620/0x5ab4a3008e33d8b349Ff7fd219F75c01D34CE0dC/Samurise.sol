// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.13;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC721NES.sol";
import "./IStakingController.sol";
import "./SamuRiseErrors.sol";

/*
 ▄█        ▄██████▄     ▄████████     ███     
███       ███    ███   ███    ███ ▀█████████▄ 
███       ███    ███   ███    █▀     ▀███▀▀██ 
███       ███    ███   ███            ███   ▀ 
███       ███    ███ ▀███████████     ███     
███       ███    ███          ███     ███     
███▌    ▄ ███    ███    ▄█    ███     ███     
█████▄▄██  ▀██████▀   ▄████████▀     ▄████▀   
▀                                             

   ▄████████    ▄████████   ▄▄▄▄███▄▄▄▄   ███    █▄     ▄████████  ▄█     ▄████████    ▄████████ 
  ███    ███   ███    ███ ▄██▀▀▀███▀▀▀██▄ ███    ███   ███    ███ ███    ███    ███   ███    ███ 
  ███    █▀    ███    ███ ███   ███   ███ ███    ███   ███    ███ ███▌   ███    █▀    ███    █▀  
  ███          ███    ███ ███   ███   ███ ███    ███  ▄███▄▄▄▄██▀ ███▌   ███         ▄███▄▄▄     
▀███████████ ▀███████████ ███   ███   ███ ███    ███ ▀▀███▀▀▀▀▀   ███▌ ▀███████████ ▀▀███▀▀▀     
         ███   ███    ███ ███   ███   ███ ███    ███ ▀███████████ ███           ███   ███    █▄  
   ▄█    ███   ███    ███ ███   ███   ███ ███    ███   ███    ███ ███     ▄█    ███   ███    ███ 
 ▄████████▀    ███    █▀   ▀█   ███   █▀  ████████▀    ███    ███ █▀    ▄████████▀    ██████████ 
                                                       ███    ███                                
samurise.xyz
*/
contract SamuRise is ERC721NES, OwnableUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // +1 in these constants used for gas optimization 
    // for use in conditional statements
    uint256 public constant TOTAL_MAX_SUPPLY = 10020 + 1; 
    uint256 public constant MAX_FREE_MINT_PER_WALLET = 1 + 1; 
    uint256 public constant MAX_PRESALE_MINT_PER_WALLET = 1 + 1; 
    uint256 public constant MAX_PRESALE_ROUND2_PER_WALLET = 3 + 1; 
    uint256 public constant MAX_PUBLIC_MINT_PER_WALLET = 3 + 1; 

    // allocation reserved for team
    uint256 public constant TEAM_ALLOCATION = 600;
    
    // Onna Musha mint count
    uint256 public constant ONNA_MUSHA_MINT_COUNT = 21;

    // ENUM to determine which mint phase we are performing
    enum MintType{ INACTIVE, FREE_MINT, PRESALE_MINT, PRESALE_ROUND_2_MINT, PUBLIC_MINT }

    // Price for presale / public mint
    uint256 public constant TOKEN_PRICE = .047 ether;

    // Public key used to verify signatures
    address public signatureVerifier;

    // Sales state
    MintType public saleState;

    // Provenance hash
    string public provenanceHash;

    // Map to track used hashes
    mapping(bytes32 => bool) public usedHashes;

    // Maps to track number minted for each sale state
    mapping(address => uint256) public numberFreeMinted;
    mapping(address => uint256) public numberPreSaleMinted;
    mapping(address => uint256) public numberPreSaleRound2Minted;
    mapping(address => uint256) public numberPublicMinted;

    string private _baseTokenURI;
    bool private initialized;

    function initialize() public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        __Ownable_init_unchained();
        __ERC721A_initialize("SAMURISE", "SamuRise");
        __UUPSUpgradeable_init_unchained();
        saleState = MintType.INACTIVE;
    }

    /* FUNCTION MODIFIERS */
    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CallerIsAnotherContract();
        _;
    }

    modifier validatePreSaleActive() {
        if(saleState != MintType.PRESALE_MINT) revert PreSaleIsNotActive();
        _;
    }

    modifier validatePreSaleRound2Active() {
        if(saleState != MintType.PRESALE_ROUND_2_MINT) revert PreSaleRound2IsNotActive();
        _;
    }

    modifier validatePublicSaleActive() {
        if(saleState != MintType.PUBLIC_MINT) revert PublicSaleIsNotActive();
        _;
    }

    modifier correctAmountSent(uint256 _quantity) {
        if(!(msg.value >= TOKEN_PRICE * _quantity)) revert NotEnoughETHSent();
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
    function freeMint(bytes memory _signature, uint256 _nonce, bool _toStake) 
        external 
        callerIsUser 
        validatePreSaleActive 
        numberMintedUnderAllocation(numberFreeMinted[msg.sender], 1, MAX_FREE_MINT_PER_WALLET)
    {
        _samuriseMint(_signature, 1, _nonce, MintType.FREE_MINT, _toStake);
        numberFreeMinted[msg.sender] += 1;
    }

    function preSaleMint(bytes memory _signature, uint256 _nonce, bool _toStake) 
        external payable 
        callerIsUser 
        validatePreSaleActive 
        numberMintedUnderAllocation(numberPreSaleMinted[msg.sender], 1, MAX_PRESALE_MINT_PER_WALLET)
        correctAmountSent(1) 
    {
        _samuriseMint(_signature, 1, _nonce, MintType.PRESALE_MINT, _toStake);
        numberPreSaleMinted[msg.sender] += 1;
    }

    function preSaleMintRound2(bytes memory _signature, uint256 _quantity, uint256 _nonce, bool _toStake) 
        external payable 
        callerIsUser 
        validatePreSaleRound2Active 
        numberMintedUnderAllocation(numberPreSaleRound2Minted[msg.sender], _quantity, MAX_PRESALE_ROUND2_PER_WALLET)
        correctAmountSent(_quantity) 
    {
        _samuriseMint(_signature, _quantity, _nonce, MintType.PRESALE_ROUND_2_MINT, _toStake);
        numberPreSaleRound2Minted[msg.sender] += _quantity;
    }

    function publicMint(bytes memory _signature, uint256 _quantity, uint256 _nonce, bool _toStake) 
        external payable 
        callerIsUser 
        validatePublicSaleActive 
        numberMintedUnderAllocation(numberPublicMinted[msg.sender], _quantity, MAX_PUBLIC_MINT_PER_WALLET)
        correctAmountSent(_quantity) 
    {
        _samuriseMint(_signature, _quantity, _nonce,  MintType.PUBLIC_MINT, _toStake);
        numberPublicMinted[msg.sender] += _quantity;
    }

    function _samuriseMint(bytes memory _signature, uint256 _quantity, uint256 _nonce, MintType mintType, bool _toStake) 
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

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

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

    function ownerMint(uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(msg.sender, _numberToMint, "", false);
    }

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

    function teamAllocationMint() external onlyOwner
        underMaxSupply(TEAM_ALLOCATION)
    {
        _mint(msg.sender, TEAM_ALLOCATION, "", false);
    }

    function onnaMushaMint() external onlyOwner
        underMaxSupply(ONNA_MUSHA_MINT_COUNT)
    {
        _mint(msg.sender, ONNA_MUSHA_MINT_COUNT, "", false);
    }


    function ownerMintToAddress(address _recipient, uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(_recipient, _numberToMint, "", false);
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    function setPublicSaleActive() external onlyOwner {
        saleState = MintType.PUBLIC_MINT;
    }

    function setPreSaleActive() external onlyOwner {
        saleState = MintType.PRESALE_MINT;
    }

    function setPreSaleRound2Active() external onlyOwner {
        saleState = MintType.PRESALE_ROUND_2_MINT;
    }

    function pauseMint() external onlyOwner {
        saleState = MintType.INACTIVE;
    }

   function _authorizeUpgrade(address) internal override onlyOwner {}
}
