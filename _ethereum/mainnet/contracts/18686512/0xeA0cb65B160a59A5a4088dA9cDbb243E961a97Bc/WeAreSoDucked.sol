// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./OperatorFilterer.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract WeAreSoDucked is ERC721A, OperatorFilterer, Ownable {
    
    enum MintState {
        Closed,
        Whitelist,
        Public
    }

    uint256 public MAX_SUPPLY = 555;
    
    uint256 public WL_TOKEN_PRICE = 0 ether;
    uint256 public PUBLIC_TOKEN_PRICE = 0 ether;
    
    uint256 public WL_MINT_LIMIT = 2;
    uint256 public PUBLIC_MINT_LIMIT = 2;
    
    MintState public mintState;

    string public baseURI;
    bytes32 public merkleRoot;

    bool public operatorFilteringEnabled;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) 
    ERC721A("WeAreSoDucked", "WASD") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        if (allocation <= MAX_SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);

        baseURI = baseURI_;
    }

    // Overrides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // Mint Options

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setWhitelistPrice(uint256 _newWhitelistPrice) external onlyOwner {
        WL_TOKEN_PRICE = _newWhitelistPrice;
    }

    function setPublicPrice(uint256 _newPublicPrice) external onlyOwner {
        PUBLIC_TOKEN_PRICE = _newPublicPrice;
    }

    function setWhitelistLimit(uint256 _newWhitelistLimit) external onlyOwner {
        WL_MINT_LIMIT = _newWhitelistLimit;
    }

    function setPublicLimit(uint256 _newPublicLimit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _newPublicLimit;
    }

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    modifier onlyValidProof(bytes32[] calldata proof) {
        bool valid = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        require(valid, "Invalid proof");
        _;
    }

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Mint

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Whitelist;
        else if (newState == 2) mintState = MintState.Public;
        else revert("Mint state does not exist");
    }

    function tokensRemainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Whitelist)
            return WL_MINT_LIMIT - _numberMinted(who);
        else if (mintState == MintState.Public)
            return PUBLIC_MINT_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Mint state mismatch");
    }

    function mintWhitelist(bytes32[] calldata proof, uint256 quantity)
        external
        payable
        onlyExternallyOwnedAccount
        onlyValidProof(proof)
    {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Whitelist, "Mint state mismatch");
        require(msg.value >= WL_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");
        _mint(msg.sender, quantity);
        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity));
    }

    function mintPublic(uint256 quantity)
        external
        payable
        onlyExternallyOwnedAccount
    {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Public, "Mint state mismatch");
        require(msg.value >= WL_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");
        _mint(msg.sender, quantity);
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(recipients.length == quantities.length, "Arguments length mismatch");
        uint256 supply = this.totalSupply();

        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];
            require(supply <= MAX_SUPPLY, "Batch mint exceeds max supply");

            _mint(recipients[i], quantities[i]);
        }
    }

    // Withdraw
 
    function withdrawToRecipients() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner           = 0xA1bBE2029ADd393309B23E448905de2D03d2C843;

        address(owner          ).call{value: balancePercentage * 100}("");
    }
}