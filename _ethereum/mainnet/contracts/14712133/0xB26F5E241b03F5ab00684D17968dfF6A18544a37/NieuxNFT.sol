//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "./console.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EIP712Allowlisting.sol";

contract NieuxNFT is 
    ERC721, 
    IERC2981, 
    Ownable, 
    EIP712Allowlisting, 
    ReentrancyGuard 
{
    uint256 public constant COST = 0.7 ether;
    uint256 public totalSupply;
    uint256 public totalMinted;
    string private customBaseURI;
    bool public paused;
    address private paymentSplitter;
    address private royaltyContract;

    mapping(address => bool) public hasMinted;

    // Private = 0 
    // Public = 1
    enum Phase {
        Private,
        Public
    }

    Phase public phase;
    
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 totalSupply_,
        string memory customBaseURI_,
        bool paused_,
        address signingKey,
        address paymentSplitter_,
        address royaltyContract_
    ) ERC721(tokenName, tokenSymbol) EIP712Allowlisting() ReentrancyGuard() {
        totalSupply = totalSupply_;
        customBaseURI = customBaseURI_;
        paused = paused_;
        setAllowlistSigningAddress(signingKey);
        phase = Phase.Private;
        paymentSplitter = paymentSplitter_;
        royaltyContract = royaltyContract_;
    }

    /***********
        receive function
    */
    receive() external payable { 
        (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
        require(sent, "Failed to receive Ether");
    }

    /*************
        minting functions
    */
    function mint()
        external
        payable
        nonReentrant 
    {
        require(!paused, "paused");
        require(totalMinted < (totalSupply - 1), "sold out");
        require(msg.value == COST, "ether != COST");
        require(hasMinted[msg.sender] == false, "already minted");
        require(phase == Phase.Public, "not in public phase");

        _safeMint(msg.sender);
    }

    function mintBySignature(bytes calldata signature) 
        external 
        payable 
        requiresAllowlist(signature) 
        nonReentrant 
    {
        require(!paused, "paused");
        require(totalMinted < (totalSupply - 1), "sold out");
        require(msg.value == COST, "ether != COST");
        require(hasMinted[msg.sender] == false, "already minted");

        _safeMint(msg.sender);
    }

    function mintByOwner(address to) 
        public  
        payable 
        onlyOwner
        nonReentrant 
    {
        require(totalMinted < totalSupply, "sold out");

        _safeMint(to);
    }

    function mintByOwnerBulk(address[] memory to) 
        external 
        payable 
        onlyOwner
        nonReentrant 
    {
        require(totalMinted + to.length <= totalSupply, "too many to mint");

        for (uint i = 0; i < to.length; i++) {
            _safeMint(to[i]);
        }
    }

    function _safeMint(address to) internal virtual {
        
        hasMinted[to] = true;

        uint256 _totalMinted = ++totalMinted;
        
        _safeMint(to, _totalMinted);

        (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
        require(sent, "Failed to pay Ether");
        
        emit Minted(to, _totalMinted);
    }
    
    /**************
        pause/unpause 
    */
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /*******************
        set phase
    */
    function setPhase(Phase _phase) 
        external 
        onlyOwner 
    {
        phase = _phase;
    }

    /*****************
        token uri
    */
    function baseTokenURI() 
        public 
        view 
        returns (string memory) 
    {
        return customBaseURI;
    }

    function setBaseURI(string memory customBaseURI_) 
        external 
        onlyOwner 
    {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return customBaseURI;
    }

    /*********
        whitelist functions
    */
    function checkAllowlist(bytes calldata signature) 
        public 
        view 
        requiresAllowlist(signature) returns (bool) 
    {
        return !hasMinted[msg.sender];
    }

    /**********
        supported interfaces 
    */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721, IERC165) returns (bool) 
    {   
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /***********
        IERC2981 interface
    */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        override
        view
        returns (address receiver, uint256 royaltyAmount) 
    {    
        royaltyAmount = (salePrice * 1000) / 10000;
        receiver = royaltyContract;

        return (receiver, royaltyAmount);
    }

    /**************
        public function to get state of mint
    */
    function mintState() 
        public 
        view
        returns (
            bool isPaused, 
            Phase mintPhase, 
            uint256 numMinted, 
            string memory baseUri,
            uint256 mintCost,
            uint256 supply
        ) 
    {        
        return (paused, phase, totalMinted, customBaseURI, COST, totalSupply);
    }

    /*************
        events
    */
    event Minted(address indexed to, uint256 tokenId);
    event Paused();
    event Unpaused();
}
