// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721AUpgradeable.sol";

import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";


contract GyrenautsImplementation is ERC721AUpgradeable, IERC2981, OwnableUpgradeable {
    using Strings for uint256;

    // Defining state variables for contract
    uint256 public maxSupply;  // Maximum tokens that can be minted
    uint256 public price;  // Price per token
    uint256 public maxMintAmount;  // Maximum tokens a single address can mint
    address public treasury;  // Address to receive mint funds

    // Royalty variables for any marketplaces that honour this for secondary sales
    address public royaltiesRecipient;  // Address to receive royalties, for exchanges that honour this
    uint256 public royaltiesPercentage;

    // Marketplace blocklist
    mapping(address => bool) public operatorBlocklist;

    // URI related state variables
    string public contractURI;
    string public baseURI;

    // Control variables to enable or disable minting
    bool public publicMintEnabled = false;
    bool public approvalListMintEnabled = false;

    // Merkle root for approval list minting
    bytes32 private merkleRoot;

    // Storage for user's background choices
    string[] public backgrounds;
    mapping (uint256 => uint256) private _backgroundChoices;

    // Storage to track number of tokens minted
    uint256 private nextTokenId;

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _treasury, address _royaltiesRecipient) initializerERC721A initializer public {
        __ERC721A_init("Gyrenauts", "GYRE");
        __Ownable_init();

        require(_treasury != address(0), "Treasury address must be valid");
        require(_royaltiesRecipient != address(0), "Royalties address must be valid");
        treasury = _treasury;
        royaltiesRecipient = _royaltiesRecipient;
        maxSupply = 2949;
        price = 0.029 ether;
        maxMintAmount = 20;
        royaltiesPercentage = 10; // 10%

        // Set background choices
        backgrounds.push("Global Brigades - No Poverty");
        backgrounds.push("Planting Justice - Zero Hunger");
        backgrounds.push("Happy Goat - Good Health");
        backgrounds.push("New Earth - Quality Education");
        backgrounds.push("Women's Earth Alliance - Gender Equality");
        backgrounds.push("Thirst Project - Clean Water and Sanitation");
        backgrounds.push("Solar Electric Light Fund - Affordable and Clean Energy");
        backgrounds.push("Leap Lab - Decent Work and Economic Growth");
        backgrounds.push("Human Needs Project - Industry Innovation and Infrastructure");
        backgrounds.push("Wikitongues - Reduced Inequalities");
        backgrounds.push("Society of Native Nations - Sustainable Cities and Communities");
        backgrounds.push("5 Gyres - Responsible Consumption");
        backgrounds.push("Extinction Rebellion - Climate Action");
        backgrounds.push("Global Coralition - Life Below Water");
        backgrounds.push("Lemur Conservation Foundation - Life on Land");
        backgrounds.push("The Society Library - Peace Justice");
        backgrounds.push("Angel Giving - Partnerships for the Goals");
    }

    // Public minting function
    function mint(address _to, uint256 quantity, uint256[] memory _backgrounds) external payable {
        require(publicMintEnabled, "Minting has not been enabled");
        _mintTokens(_to, quantity, _backgrounds);  // Internal function to handle the minting process
    }

    // Approval list minting function
    function approvalListMint(address _to, uint256 quantity, bytes32[] calldata merkleProof, uint256[] memory _backgrounds) external payable {
        require(approvalListMintEnabled, "Minting has not been enabled");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(_to))), "Invalid proof");
        _mintTokens(_to, quantity, _backgrounds);  // Internal function to handle the minting process
    }

    // Function to set the base URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
	}

    // Function to set the contract URI
	function setContractURI(string memory _newContractURI) public onlyOwner {
	    contractURI = _newContractURI;
	}

    // Function to toggle public minting on and off
	function toggleMinting() external onlyOwner {
        publicMintEnabled = !publicMintEnabled;
    }

    // Function to toggle approval list minting on and off
    function toggleApprovalListMinting() external onlyOwner {
        approvalListMintEnabled = !approvalListMintEnabled;
    }

    // Overridden function to provide token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

    // Function to update the Merkle root
    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    // Function to update the minting price
    function updatePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    // Function to update the maximum mint amount
    function updateMaxMintAmount(uint256 newMaxMintAmount) external onlyOwner {
        maxMintAmount = newMaxMintAmount;
    }

    // Function to update the treasury address
    function updateTreasuryAddress(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    // Function to update the total supply, but ensuring it can only be lowered
    function updateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < maxSupply, "New max supply must be lower than current max supply");
        maxSupply = newMaxSupply;
    }

    // Function to get the number of tokens minted by a specific address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Function to query background choice based on tokenID
    function getBackgroundChoiceByToken(uint256 tokenID) public view returns (string memory) {
        uint256 backgroundID = _backgroundChoices[tokenID];
        require(backgroundID >= 0 && backgroundID < backgrounds.length, "Invalid backgroundID");
        require(_exists(tokenID), "Background query for nonexistent token");
        return backgrounds[backgroundID];
    }

    // Function that allows the owner of the contract to withdraw all Ether stored in the contract.
    function withdraw() public {
        uint256 balance = address(this).balance;
        // The low-level 'call' function is used here instead of 'transfer'.
        // This line sends the entire balance and also forwards all remaining gas, mitigating potential issues with receiving contracts.
        // It returns a boolean value indicating the success or failure of the operation, and any data returned by the call.
        (bool success, ) = payable(treasury).call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    // EIP2981 standard royalties
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltiesRecipient, (_salePrice * royaltiesPercentage) / 100);
    }

    function updateRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        royaltiesRecipient = _royaltiesRecipient;
    }

    function updateRoyaltiesPercentage(uint256 _royaltiesPercentage) external onlyOwner {
        royaltiesPercentage = _royaltiesPercentage;
    }

    // EIP2981 standard Interface return. Adds to ERC721AUpgradeable and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    // Overridden function to provide base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Overridden function to specify the starting token ID
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Internal function to handle the minting process
    function _mintTokens(address _to, uint256 quantity, uint256[] memory _backgrounds) internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + quantity <= maxSupply, "Total Supply has been minted");
        require(numberMinted(_to) + quantity <= maxMintAmount, "Address has already minted maximum amount allowed");
        require(quantity > 0, "Must specify at least 1 token");
        require(_backgrounds.length == quantity, "Each token requires a background selection");
        require(msg.value >= price * quantity, "Insufficient amount of ether sent");

        // store the background choices
        for (uint256 i = 0; i < quantity; i++) {
            require(_backgrounds[i] < backgrounds.length, "Invalid background choice");
            uint256 newTokenId = _totalSupply + 1 + i; // Assuming token ID starts from 1
            _backgroundChoices[newTokenId] = _backgrounds[i]; // Save the background for this token
        }

        _safeMint(_to, quantity);
    }

    /*
    --
    The following are methods to block transfers to/from specific contracts (read: marketplaces).
    No longer using the filter registry due to OpenSea sunsetting support for it.
    --
    */

    // Function to check if an operator is allowed
    function isOperatorAllowed(address _contract) public view returns (bool) {
        return !operatorBlocklist[_contract];
    }

    // Function to update the blocklist mapping
    function updateOperatorBlocklist(address _contract, bool _blocked) public onlyOwner {
        operatorBlocklist[_contract] = _blocked;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(isOperatorAllowed(operator), "Operator not allowed to perform this action");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override {
        require(isOperatorAllowed(operator), "Operator not allowed to perform this action");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        require(isOperatorAllowed(msg.sender), "Operator not allowed to perform this action");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        require(isOperatorAllowed(msg.sender), "Operator not allowed to perform this action");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        require(isOperatorAllowed(msg.sender), "Operator not allowed to perform this action");
        super.safeTransferFrom(from, to, tokenId, data);
    }

}
