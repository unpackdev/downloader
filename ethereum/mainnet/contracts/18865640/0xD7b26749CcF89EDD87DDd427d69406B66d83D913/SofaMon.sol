// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";
import "./OperatorFilterer.sol";

contract SofaMon is ERC721A, ERC2981, OperatorFilterer, Ownable {
    string public baseURI;

    uint256 public price = 0.0169 ether;

    uint256 public constant totalTokens = 10000;
    uint256 public constant freeTotalTokens = 5555;
    uint256 public constant maxFreeState = 0;
    uint256 public constant maxPaidState = 3;
    uint256 public mintedFree = 0;
    uint256 public mintedPaid = 0;
    uint256 public mintedTreasury = 0;

    bytes32 private freeRoot;
    bytes32 private paidRoot;

    enum SaleStage {
        Closed,
        Free,
        Public,
        Finished
    }

    SaleStage public saleState = SaleStage.Closed;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public publicMinted;
    mapping(address => uint256) public treasuryMinted;

    bool public operatorFilteringEnabled = true;
    bool public paused = false;

    constructor() ERC721A("Sofamon Seed", "Sofamon Seed") {
        setBaseURI("ipfs://bafybeif55dqn47zs4rd4gdhejufow3mb2bwmm2zj3nzosbulzgkyohx2ju/seed_json/");
        _setDefaultRoyalty(msg.sender, 500);
        _registerForOperatorFiltering();
    }

    function mintFree(
        uint256 _amount,
        uint256 _maxAmount,
        bytes32[] calldata merkleProof
    ) external eoaCheck notPaused isStageValid(SaleStage.Free) {
        require(freeMinted[msg.sender] + _amount <= _maxAmount, "Exceeding max eligible amount.");
        require(mintedFree + _amount <= freeTotalTokens, "Exceeding max supply of free tokens.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        require(MerkleProof.verify(merkleProof, freeRoot, leaf), "Proof does not match.");
        freeMinted[msg.sender] += _amount;
        mintedFree += _amount;
        _mint(msg.sender, _amount);
    }

    function mintPublic(uint256 _amount) external payable notPaused isStageValid(SaleStage.Public) {
        require(publicMinted[msg.sender] + _amount <= maxPaidState, "Exceeding max tokens of Public sale");
        require(totalSupply() + _amount <= totalTokens, "Exceeding max supply of total tokens.");
        require(msg.value == price * _amount, "Incorrect Ether value.");
        publicMinted[msg.sender] += _amount;
        mintedPaid += _amount;
        _mint(msg.sender, _amount);
    }

    modifier notPaused() {
        require(!paused, "error: sale paused!");
        _;
    }

    //Functions

    modifier isStageValid(SaleStage requiredState) {
        require(saleState == requiredState, "wrong sale state");
        _;
    }

    modifier eoaCheck() {
        require(tx.origin == msg.sender, "contract not allowed");
        _;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        freeRoot = _root;
    }

    function setBaseURI(string memory newbaseURI) public onlyOwner {
        baseURI = newbaseURI;
    }

    function setSaleStage(SaleStage _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to withdraw payment");
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function mintTreasury(address to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= totalTokens, "Exceeding max supply of total tokens.");
        _mint(to, _amount);
        mintedTreasury += _amount;
        treasuryMinted[to] += _amount;
    }

    function airdrop(address[] memory to) external onlyOwner {
        require(totalSupply() + to.length <= totalTokens, "Exceeding max supply of total tokens.");

        for (uint i = 0; i < to.length; ) {
            _mint(to[i], 1);
            treasuryMinted[to[i]] += 1;
            unchecked {
                i++;
            }
        }
    }

    // IERC2981

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    bool private isAllowTransfer = false;

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function assertAllowTransfer(address from) internal view {
        if (!isAllowTransfer) {
            require(from == address(0) || from == owner(), "transfer reach limit");
        }
    }

    function setAllowTransfer(bool _isAllow) public onlyOwner {
        isAllowTransfer = _isAllow;
    }

    // OperatorFilterer

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        assertAllowTransfer(operator);
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        assertAllowTransfer(operator);
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        assertAllowTransfer(from);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        assertAllowTransfer(from);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function toggleOperatorFilteringEnabled() external onlyOwner {
        operatorFilteringEnabled = !operatorFilteringEnabled;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    struct SofaMonDashboard {
        uint256 price;
        uint256 totalTokens;
        uint256 freeTotalTokens;
        uint256 paidTotalTokens;
        uint256 maxFreeState;
        uint256 maxPaidState;
        uint256 mintedFree;
        uint256 mintedPaid;
        bool paused;
        uint256 userFreeMinted;
        uint256 userPublicMinted;
        SaleStage stage;
    }

    function dashboardStatus(address _addr) public view returns (SofaMonDashboard memory dashboard) {
        dashboard.price = price;
        dashboard.totalTokens = totalTokens;
        dashboard.freeTotalTokens = freeTotalTokens;
        dashboard.paidTotalTokens = totalTokens - mintedFree;
        dashboard.maxFreeState = maxFreeState;
        dashboard.maxPaidState = maxPaidState;
        dashboard.mintedFree = mintedFree;
        dashboard.mintedPaid = mintedPaid;

        dashboard.paused = paused;
        dashboard.stage = saleState;

        dashboard.userPublicMinted = publicMinted[_addr];
        dashboard.userFreeMinted = freeMinted[_addr];
        dashboard.stage = saleState;
    }
}
