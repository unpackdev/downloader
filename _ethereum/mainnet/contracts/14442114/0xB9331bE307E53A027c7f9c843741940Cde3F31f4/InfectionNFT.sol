// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
contract InfectionNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public PURCHASE_LIMIT = 1;
    uint256 public PRICE = 0 ether;
    uint256 public whileListMaxMint = 1;
    string public notRevealedUri;
    string public baseExtension = "";
    string private tokenBaseURI = "ipfs://bafybeihigdoqjbmcq7jtdctb5ilyqaktcdauctbcj2j5yrseziy2dwyqjy/metadata/";
    bool private isActive = false;
    bool public isWhileListActive = true;
    bool public revealed = true;
    bytes32 public merkleRoot;
    address public ownerMintingAddr;
    mapping(address => uint256) private _whileListClaimed;

    Counters.Counter private _count;

    constructor(
        string memory _initNotRevealedUri
    ) ERC721("Infection", "INFECTION") {
        setNotRevealedURI(_initNotRevealedUri);
        ownerMintingAddr = msg.sender;
    }

    function whileListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), "Zero address not on While List");
        return _whileListClaimed[owner];
    }
    
    function purchaseWhileList(uint256 index, uint256 numberOfTokens, bytes32[] calldata merkleProof) external payable {

        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "Can only mint up to 2 token"
        );
        
        require(isWhileListActive, "While List is not active");
        
       // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender , numberOfTokens));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Invalid proof.');

        require(
            _count.current() < MAX_SUPPLY,
            "Purchase would exceed max"
        );
        require(numberOfTokens <= whileListMaxMint, "Cannot purchase this many tokens");
        require(_whileListClaimed[msg.sender] + numberOfTokens <= whileListMaxMint, "Purchase exceeds max whileed");
        require(PRICE * numberOfTokens <= msg.value, "ETH amount is not sufficient");
        require(
            _count.current() < MAX_SUPPLY,
            "Purchase would exceed MAX_SUPPLY"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _count.current();

            if (_count.current() < MAX_SUPPLY) {
                _count.increment();
                _whileListClaimed[msg.sender] += 1;
                _safeMint(msg.sender, tokenId +1);
            }
        }
    }

    function purchase(uint256 numberOfTokens) external payable nonReentrant {
        require(isActive, "Contract is not active");

        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "Can only mint up to 1 tokens"
        );
        require(
            _count.current() < MAX_SUPPLY,
            "Purchase would exceed MAX_SUPPLY"
        );

        require(_whileListClaimed[msg.sender] + numberOfTokens <= whileListMaxMint, "Purchase exceeds max whileed");
        require(
            PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _count.current();

            if (_count.current() < MAX_SUPPLY) {
                _count.increment();
                _whileListClaimed[msg.sender] += 1;
                _safeMint(msg.sender, tokenId +1);
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        if(revealed == false) {
            return notRevealedUri;
        }

        return string(abi.encodePacked(tokenBaseURI, tokenId.toString(), baseExtension));
    }

    // ONLY OWNER FUNCTIONS
    function ownerMinting(address to, uint256 numberOfTokens)
        public
        payable
    {
        require(ownerMintingAddr==address(0)||ownerMintingAddr==msg.sender, "Limit owner minting");
        require(
            _count.current() < MAX_SUPPLY,
            "Purchase would exceed MAX_SUPPLY"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _count.current();

            if (_count.current() < MAX_SUPPLY) {
                _count.increment();
                _safeMint(to, tokenId +1);
            }
        }
    }

    function setOwnerMintingAddr(address _ownerMintingAddr) external onlyOwner {
        ownerMintingAddr = _ownerMintingAddr;
    }
    
    function setActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setBaseURI(string memory _tokenBaseURI) external onlyOwner {
        tokenBaseURI = _tokenBaseURI;
    }

    function reveal(bool isRevealed) public onlyOwner() {
      revealed = isRevealed;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setMerkleRoot (bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setIsWhileListActive(bool _isWhileListActive) external onlyOwner {
        isWhileListActive = _isWhileListActive;
    }

    function setWhileListMaxMint(uint256 maxMint) external onlyOwner {
        whileListMaxMint = maxMint;
    }

    function setMaxSupply(uint256 _newMax) public onlyOwner() {
        MAX_SUPPLY = _newMax;
    }

    function setPurchaseLimit(uint256 _newPurchaseMax) public onlyOwner() {
        PURCHASE_LIMIT = _newPurchaseMax;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        PRICE = _newPrice;
    }
  
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}
    
    function _transferEth(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}('');
        require(success, "_transferEth: Eth transfer failed");
    }
    
    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset,address to) onlyOwner external { 
        IERC20(asset).transfer(to, IERC20(asset).balanceOf(address(this)));
    }
}