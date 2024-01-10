//SPDX-License-Identifier: MIT
//Authors: Pineapple & GoatBaloonToken

pragma solidity ^0.8.4;

//@dev Import required contracts
import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract PixelPrimeApes is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY = 10000;
    uint256 public constant RESERVE_AMOUNT = 200;

    uint256 public constant PRICE = 0.055 ether;

    uint256 public constant OG_MAX = 2;
    uint256 public constant PRESALE_MAX = 5;
    uint256 public constant PUBLIC_MAX = 10;

    //@dev: Variables for contract states
    bool public ogSaleOn = false;
    bool public presaleOn = false;
    bool public saleOn = false;
    bool public reserved = false;
    bool public metadataIsFrozen = false;
    bool public finalSupply = false;

    //Addresses for transfers and verifications
    address private immutable _enforcerAddress;
    address private immutable _vaultAddress;
    address private _teamAddress = 0x7141BF3F75aE1994ea7493dfb4724F0969c2369a;

    //@Tracks the hash to verify that the user is minting from site.
    //The notice is generated off-chain using our Presale DB.
    struct Notice {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum MintType {
        OG,
        Presale
    }
    
    //Constructor
    constructor(
        address enforcerAddress_,
        address vaultAddress_
    ) ERC721A("Pixel PrimeApes", "PPA") {
        _enforcerAddress = enforcerAddress_;
        _vaultAddress = vaultAddress_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller must be an EOA!");
        _;
    }

    modifier verifyPayment(uint256 count) {
        require(msg.value >= PRICE * count, "You need to send more ETH!");
        _;
    }

    //@dev Check that the notice was signed by our enforcer address and that user
    //      is allowed to mint during OG/Presale mint
    //@param:dig: data represnting hash of Mint phase and the user address
    //@param: notice: notice generated that verifies member is on the presale list
    function _isValidNotice(bytes32 dig, Notice memory notice) internal view returns (bool) {
        address signer = ecrecover(dig, notice.v, notice.r, notice.s);
        require(signer != address(0), 'ECDSA: Invalid signature');
        return signer == _enforcerAddress;
    }

    //@dev Function that handles presale minting by verifying the notice
    //@dev signed by our enforcerAddress
    //@param quantity: # of tokens minted in the transaction
    //@param notice: notice signed by enforcerAddress
    function ogMint(uint256 quantity, Notice memory notice) external payable callerIsUser verifyPayment(quantity){
        require(ogSaleOn, "First Edition Sale has not started yet!");
        require(numberMinted(msg.sender) + quantity <= OG_MAX, "Max of 2 First Edition PrimeApes!");

        bytes32 dig = keccak256(abi.encode(MintType.OG, msg.sender));

        require(_isValidNotice(dig, notice), "Invalid notice!");

        _safeMint(msg.sender, quantity, true);

    }

    //@dev Function that handles presale minting by verifying the notice
    //@dev signed by our enforcerAddress
    //@param quantity: # of tokens minted in the transaction
    //@param notice: notice signed by enforcerAddress
    function presaleMint(uint256 quantity, Notice memory notice) external payable callerIsUser verifyPayment(quantity){
        require(presaleOn, "Presale has not started!");
        require(numberMinted(msg.sender) - numberMintedFE(msg.sender) + quantity <= PRESALE_MAX, "Max of 5 PPAs during Presale Mint!");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough NFTs left to mint!");

        bytes32 dig = keccak256(abi.encode(MintType.Presale, msg.sender));

        require(_isValidNotice(dig, notice), "Invalid Notice!");

        _safeMint(msg.sender, quantity, false);
    }

    //@dev Public mint function
    //@param quantity: Number of NFTs to be minted by caller
    function mint(uint256 quantity) external payable verifyPayment(quantity) {
        require(saleOn, "Public sale has not started!");
        require(quantity <= PUBLIC_MAX, "Max of 10 Pixel PrimeApes per transaction!");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough NFTs left to mint!");

        _safeMint(msg.sender, quantity, false);
    }

    //@dev Function to reserve NFTs for team members and giveaways
    function reserveMints() external onlyOwner {
        require(!reserved, "Team NFTs have already been reserved!");
        require(totalSupply() + RESERVE_AMOUNT <= MAX_SUPPLY, "Not enough NFTs left to reserve!");
        _safeMint(_teamAddress, RESERVE_AMOUNT, false);

        reserved = true;
    }


    //@dev: Functions to flip the sale checks
    function flipOGSale() external virtual onlyOwner {
        ogSaleOn = !ogSaleOn;
    }

    function flipPresale() external virtual onlyOwner {
        presaleOn = !presaleOn;

    }

    function flipSale() external virtual onlyOwner {
        saleOn = !saleOn;
    }

    //@dev: Function that withdraws funds - split to team address and PPA Vault
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        (bool sent, ) = payable(_vaultAddress).call{value: ((balance*30)/100)}("");
        require(sent, "Failed to transfer to vault!");
        
        (bool sent_team, ) = payable(_teamAddress).call{value: ((balance*70)/100)}("");
        require(sent_team, "Failed to transfer to team!");
    }

    //@dev: metadata URI and metadata functions
    string private _baseTokenURI;
    string private _contractURI = "https://gateway.pinata.cloud/ipfs/QmeHpGwiJFDp4T8S74dqpZcekWMq6NxqSkQSLzjMrmJgGW/contract-metadata.json";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!metadataIsFrozen, "Metadata is frozen and cannot be changed!");
        _baseTokenURI = baseURI;
    }

    function setContractURI(string memory new_contractURI) external onlyOwner {
        _contractURI = new_contractURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberMintedFE(address owner) public view returns (uint256) {
        return _numberMintedFE(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function freezeMetadata() external onlyOwner {
        require(!metadataIsFrozen, "Metadata is already frozen!");

        metadataIsFrozen = true;
    }

    function lowerSupply(uint256 new_supply) external onlyOwner {
        require(!finalSupply, "Max supply cannot be changed!");
        require(new_supply < MAX_SUPPLY, "New supply must be lower than current max!");
        MAX_SUPPLY = new_supply;
    }

    function finalizeSupply() external onlyOwner {
        require(!finalSupply, "Max supply is already finalized!");
        finalSupply = true;
    }

    function setTeamAddress(address new_address) external onlyOwner {
        _teamAddress = new_address;
    }
}