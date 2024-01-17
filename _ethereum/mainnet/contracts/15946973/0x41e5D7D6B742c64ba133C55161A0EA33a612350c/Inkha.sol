// SPDX-License-Identifier: MIT

// inkha.net - Art by @MatthewWhoosh, Contract and website by @georgefatlion. Implementation based on the awesome ERC721A contract from AZUKI.

// whooshlabs.co.uk

// ██╗███╗░░██╗██╗░░██╗██╗░░██╗░█████╗░  ███╗░░██╗███████╗████████╗
// ██║████╗░██║██║░██╔╝██║░░██║██╔══██╗  ████╗░██║██╔════╝╚══██╔══╝
// ██║██╔██╗██║█████═╝░███████║███████║  ██╔██╗██║█████╗░░░░░██║░░░
// ██║██║╚████║██╔═██╗░██╔══██║██╔══██║  ██║╚████║██╔══╝░░░░░██║░░░
// ██║██║░╚███║██║░╚██╗██║░░██║██║░░██║  ██║░╚███║██║░░░░░░░░██║░░░
// ╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░

// █░█░█ █░█ █▀█ █▀█ █▀ █░█   █░░ ▄▀█ █▄▄ █▀
// ▀▄▀▄▀ █▀█ █▄█ █▄█ ▄█ █▀█   █▄▄ █▀█ █▄█ ▄█

// █░█ █░░ █▀█ ▀▄▀
// ▀▄▀ █▄▄ █▄█ █░█

pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract INKHA is ERC721A, Ownable {
    constructor() ERC721A("Inkha", "INKHA") {}

    /* ========== STATE VARIABLES ========== */

    uint256 private constant MAX_SUPPLY = 128;
    bool private claimOpen;
    string private baseTokenURI;
    string private contracturi;
    bytes32 private merkleRoot;
    uint8 private maxPerTx = 1;
    uint8 private maxPerWallet = 1;
    mapping(address => uint8) public numberClaimed;
    bool public checkMerkle = true;
    mapping(address=> bool) blockedMarketplaces;

    /* ========== VIEWS ========== */

    /**
     * @notice Get the claim open state.
     *
     */
    function getClaimState() public view returns (bool) {
        return claimOpen;
    }

    /**
     * @notice Get the numbed claimed by an address.
     *
     */
    function getClaimed(address _addr) public view returns (uint8) {
        return numberClaimed[_addr];
    }

    /**
     * @notice Get the max per transaction.
     *
     */
    function getMaxPerTx() public view returns (uint8) {
        return maxPerTx;
    }

    /**
     * @notice Get the max per wallet.
     *
     */
    function getMaxPerWallet() public view returns (uint8) {
        return maxPerWallet;
    }

    /**
     * @notice Get the number claimed by an address.
     *
     */
    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @notice Return the contractURI
     */
    function contractURI() public view returns (string memory) {
        return contracturi;
    }

    function getTokenIDS(address _addr)
        public
        view
        returns (string memory)
    {
        uint256 totalInkhas = this.balanceOf(
            _addr
        );
        string memory tokenIds;

        for (uint256 x = 0; x < totalInkhas; x++) {
            uint256 tokenNo = this.tokenOfOwnerByIndex(_addr, x);
            
            tokenIds = string(
                abi.encodePacked(
                    tokenIds,
                    Strings.toString(tokenNo),
                    ","
                )
            );
            
        }
        return tokenIds;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Mint an Inkha.
     *
     * @param _amount the tokensToClaim.
     * @param _merkleProof the proof for the tx.
     */
    function mintInkha( uint8 _amount, bytes32[] calldata _merkleProof) public {
        // check the claim is open
        require(claimOpen, "Claim is not open");
        require(_amount <= maxPerTx, "Too many at once");
        require(_amount + numberClaimed[ msg.sender] <= maxPerWallet, "Too many in total");

        // Stop contracts calling the method.
        require(tx.origin == msg.sender);

        // Check the amount isn't over the max supply.
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Surpasses supply"
        );
        if (checkMerkle){
        
        require(verifyMerkleProof(_merkleProof, merkleRoot),"Invalid proof");          
        
        }
        numberClaimed[msg.sender] += _amount;

        // Safemint a number of tokens equal to the length of the tokenIDs array.
        _safeMint(msg.sender, _amount);
    }

    /**
     * @notice Set the claim open state.
     *
     * @param _claimState.
     */
    function setClaimState(bool _claimState,bool _merkleState,uint8 _maxPerTx,uint8 _maxPerWallet) external onlyOwner {
        if(_claimState!=claimOpen){
        claimOpen = _claimState;
        }
        
        if(_merkleState!=checkMerkle){
        checkMerkle = _merkleState;
        }

        if(_maxPerTx!=maxPerTx){
        maxPerTx = _maxPerTx;
        }

        if(_maxPerWallet!=maxPerWallet){
        maxPerWallet = _maxPerWallet;
        }
    }
    
    /**
    * @notice Verify the merkle proof for a given root.   
    *     
    * @param proof the merkle proof
    * @param root the merkle root
    */
    function verifyMerkleProof(bytes32[] memory proof, bytes32 root)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
    * @notice edit the merkle root 

    * @param _merkleRoot the merkleRoot.
    */

     function editMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
       merkleRoot = _merkleRoot;
    }       

    /**
     * @notice Admin mint, to allow direct minting of the 1/1s.
     *
     * @param _recipient the address to mint to.
     * @param _quantity the quantity to mint.
     */

    function mintAdmin(address _recipient, uint256 _quantity) public onlyOwner {
        // Check the amount isn't over the max supply.
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");

        // Safemint the quantiy of tokens to the recipient.
        _safeMint(_recipient, _quantity);
    }

    /**
     * @notice Change the contract URI
     *
     * @param _uri the respective base URI
     */
    function setContractURI(string memory _uri) external onlyOwner {
        contracturi = _uri;
    }

    /**
     * @notice Change the base URI for returning metadata
     *
     * @param _baseTokenURI the respective base URI
     */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function isBlocked(address operator) internal view returns (bool){
        return blockedMarketplaces[operator];
    }

    function setBlockedOperator(address operator, bool state) external onlyOwner{
        blockedMarketplaces[operator] = state;
    }
    
    /* ========== OVERRIDES ========== */

    /**
     * @notice Return the baseTokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setApprovalForAll (address operator, bool approved) public virtual override(ERC721A){
        require(!isBlocked(operator), "This operator is blocked");
        super.setApprovalForAll(operator,approved);
    }

    function isApprovedForAll (address account, address operator) public view virtual override(ERC721A) returns (bool){
        if (isBlocked(operator)) return false;
        return super.isApprovedForAll(account,operator);
    }
}
