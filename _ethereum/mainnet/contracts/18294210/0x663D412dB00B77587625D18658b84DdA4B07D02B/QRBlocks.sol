pragma solidity ^0.8.17;

// import "./ERC721.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC2981.sol";

/*


█▀█ █▀█ █▄▄ █░░ █▀█ █▀▀ █▄▀ █▀
▀▀█ █▀▄ █▄█ █▄▄ █▄█ █▄▄ █░█ ▄█

 */
contract QRBlocks is ERC721A,ERC2981, Ownable,DefaultOperatorFilterer {
    constructor(address payable royaltyReceiver) ERC721A("QRBlocks", "QRBlocks") {
        _setDefaultRoyalty(royaltyReceiver, 500);
    }
    uint8 public MAX_PUBLIC_TX=5;
    uint8 public MAX_ALLOWLIST_MINT=3;
    uint32 public ALLOWLIST_START = 1696948200;
    uint32 public ALLOWLIST_END = 	1696955400;
    uint32 public PUBLIC_START = 	1696955400;
    uint32 public PUBLIC_END = 1697041800;
    uint32 public TRADE_LOCK_END=0;
    uint64 public ALLOWLIST_MINT_PRICE= 0.0097 ether; //TBD
    uint64 public PUBLIC_MINT_PRICE= 0.015 ether; //TBD
    uint256 public MAX_SUPPLY = 3500;
    uint256 public DISCOUNT_THRESHOLD = 0;
    bytes32 public merkleRoot=0x0;
    string public baseURI;
    bool public special_mint_opens=false;
    mapping(address => uint256) private _tokensMinted;
    function getSalesInfo() public view returns (uint8,uint8,uint32,uint32,uint32,uint32,uint64,uint64,uint256){
        return (MAX_PUBLIC_TX,MAX_ALLOWLIST_MINT,ALLOWLIST_START,ALLOWLIST_END,PUBLIC_START,PUBLIC_END,ALLOWLIST_MINT_PRICE,PUBLIC_MINT_PRICE,MAX_SUPPLY);
    }
    function mint_limit_config(uint8 new_public_max,uint8 new_allowlist_max) public onlyOwner{
        MAX_PUBLIC_TX=new_public_max;
        MAX_ALLOWLIST_MINT=new_allowlist_max;
    }
    function set_allowlist_start(uint32 newTime) public onlyOwner {
        ALLOWLIST_START=newTime;
    }
    function set_allowlist_end(uint32 newTime) public onlyOwner {
        ALLOWLIST_END=newTime;
    }
    function set_public_start(uint32 newTime) public onlyOwner {
        PUBLIC_START=newTime;
    }
    function set_public_end(uint32 newTime) public onlyOwner {
        PUBLIC_END=newTime;
    }
    function set_trade_lock_end(uint32 newTime) public onlyOwner {
        TRADE_LOCK_END=newTime;
    }
    function set_allowlist_price(uint64 newPrice) public onlyOwner {
        ALLOWLIST_MINT_PRICE=newPrice;
    }
    function set_public_price(uint64 newPrice) public onlyOwner {
        PUBLIC_MINT_PRICE=newPrice;
    }
    function set_root(bytes32 newRoot) public onlyOwner {
        merkleRoot=newRoot;
    }
    function set_base_uri(string calldata newURI) public onlyOwner{
        baseURI=newURI;
    }
     function set_special_mint(bool isOpen) public onlyOwner {
        special_mint_opens=isOpen;
    }
    function allowlist_minted(address addr) public view  returns (uint256){
       return _tokensMinted[addr];
    }
    function reduce_supply(uint256 newsupply) public onlyOwner{
        require(newsupply<MAX_SUPPLY,"Can't increase supply");
        MAX_SUPPLY=newsupply;
    }
    function set_discount_threshold(uint256 newthreshold) public onlyOwner{
        DISCOUNT_THRESHOLD=newthreshold;
    }
    modifier supplyAvailable(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY,"Sold Out");
        _;
    }


   function team_mint(uint256 quantity,address addr) public payable onlyOwner supplyAvailable(quantity)
    {
        _mint(addr, quantity);
    }
    

    function allowlist_mint(uint256 quantity,bytes32[] calldata proof) public payable supplyAvailable(quantity)
    {
        require(msg.value == ALLOWLIST_MINT_PRICE * quantity, "Insufficient funds");
        require(block.timestamp >= ALLOWLIST_START && block.timestamp <= ALLOWLIST_END, "Not in allowlist mint phase");
        require(quantity > 0 && _tokensMinted[msg.sender]+quantity<=MAX_ALLOWLIST_MINT, "Invalid quantity");
        bytes32 leaf=keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle proof");
        _tokensMinted[msg.sender]+=quantity;
        _mint(msg.sender, quantity);
        

    }
    function public_mint(uint256 quantity) public payable supplyAvailable(quantity)
    {   
        require(msg.value == PUBLIC_MINT_PRICE*quantity, "Insufficient funds");
        require(block.timestamp >= PUBLIC_START && block.timestamp <= PUBLIC_END, "Not in public mint phase");
        require(quantity > 0 && quantity<=MAX_PUBLIC_TX, "Invalid quantity");
        _mint(msg.sender, quantity);

    }
    function backup(uint256 quantity) public payable supplyAvailable(quantity){
        require(special_mint_opens,"Not Available");
        if(totalSupply() < DISCOUNT_THRESHOLD){
            require(msg.value == PUBLIC_MINT_PRICE*(quantity-1), "Insufficient funds");
        }
        else{
            require(msg.value == PUBLIC_MINT_PRICE*(quantity), "Insufficient funds");
        }
        require(block.timestamp >= PUBLIC_START && block.timestamp <= PUBLIC_END, "Not in public mint phase");
        require(quantity > 0 && quantity<=MAX_PUBLIC_TX, "Invalid quantity");
        _mint(msg.sender, quantity);

    }
    function setNewOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    // BASE URI
    function _baseURI() internal view override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

// operation filter override functions
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        require(block.timestamp >= TRADE_LOCK_END, "Trading Temporarily Locked");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        require(block.timestamp >= TRADE_LOCK_END, "Trading Temporarily Locked");
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        require(block.timestamp >= TRADE_LOCK_END, "Trading Temporarily Locked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        require(block.timestamp >= TRADE_LOCK_END, "Trading Temporarily Locked");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        require(block.timestamp >= TRADE_LOCK_END, "Trading Temporarily Locked");
        super.safeTransferFrom(from, to, tokenId, data);
    }
    //royaltyInfo
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}