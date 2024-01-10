//SPDX-License-Identifier: MIT
//@dev: Blunt God

pragma solidity ^0.8.11;
import "./ERC1155.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract BluntHeads is ERC1155, Ownable, Pausable, ReentrancyGuard
{
    /*--------------------
        * VARIABLES *
    ---------------------*/
    
    //Init
    string public constant name = "BluntHeads";
    string public constant symbol = "BLUNT";
    string public _BASE_URI = "ipfs://QmamcA6NNQYHyajjiweY3L4mMmyhWQ3paDbQ7P4TPkdbcr/";
    
    //Merkle Root
    bytes32 private root = 0xfdc4c218f8683074c8b4dc0647f943c81bb12c66afc12ce09b9c9be951efbde9;

    //Multisig
    address private immutable _BHMultisig = 0xD98d0432C38536260c5bD323E8ce71144d366A85;

    //Token Amounts
    uint256 public _BLUNTS_MINTED = 1;
    uint256 public _MAX_BLUNTS = 10000;
    uint256 public _MAX_BLUNTS_PURCHASE = 20;
    
    //Price
    uint256 public _BLUNT_PRICE = 0.08 ether;

    //Sale State
    bool public _SALE_IS_ACTIVE_PUBLIC = false;
    bool public _SALE_IS_ACTIVE_BLUNTLIST = true;
    bool public _ALLOW_MULTIPLE_PURCHASES = true;

    //Mint Mapping
    mapping (address => bool) private _MINTED;
    mapping (address => bool) private _CLAIMED;

    //Mint Event
    event BluntHeadsMinted(address indexed recipient, uint256 indexed amount);

    /*--------------------
        * CONSTRUCTOR *
    ---------------------*/

    constructor() ERC1155("https://ipfs.io/ipfs/QmamcA6NNQYHyajjiweY3L4mMmyhWQ3paDbQ7P4TPkdbcr/{id}.json") { _reserveBluntHeads(100); }

    /*--------------------
          * MINT *
    ---------------------*/
    
    /**
     * @dev Public Mints Blunt Heads
     */
    function BluntHeadsMint(uint256 numberOfTokens) public payable nonReentrant whenNotPaused
    {
        require(tx.origin == msg.sender, "No External Contracts");
        require(_SALE_IS_ACTIVE_PUBLIC, "Sale must be active to mint Blunts");
        require(numberOfTokens <= _MAX_BLUNTS_PURCHASE && numberOfTokens > 0, "Can only mint max 20 Blunts at a time, and a minimum of 1");
        require(_BLUNTS_MINTED + numberOfTokens <= _MAX_BLUNTS, "Purchase would exceed max supply of Blunts");
        require(_BLUNT_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct. 0.08 ETH Per Blunt | 80000000000000000 WEI");
        if(!_ALLOW_MULTIPLE_PURCHASES) { require(!_MINTED[msg.sender], "Address Has Already Minted"); }

        _MINTED[msg.sender] = true; 

        //Mints Blunts
        for(uint256 i=0; i < numberOfTokens; i++) 
        {
            if (_BLUNTS_MINTED <= _MAX_BLUNTS) 
            {
                _mint(msg.sender, _BLUNTS_MINTED, 1, "");
                _BLUNTS_MINTED += 1;
            }
        }

        //Purchase 3 Or More, Get 1 Free
        if(numberOfTokens >= 3 && _BLUNTS_MINTED < _MAX_BLUNTS) 
        {
            uint256 numFree = numberOfTokens / 3;
            for(uint256 i = 0; i < numFree; i++)
            {
                _mint(msg.sender, _BLUNTS_MINTED, 1, "");
                _BLUNTS_MINTED += 1;
            }
        }

        //Finishes Mint
        emit BluntHeadsMinted(msg.sender, numberOfTokens);
    }

    /**
     * @dev Mints Blunt Heads from Merkle Proof Bluntlist
     */
    function BluntHeadsMintBluntlist(uint256 numberOfTokens, bytes32[] calldata proof) public payable nonReentrant whenNotPaused
    {
        require(tx.origin == msg.sender, "No External Contracts");
        require(_SALE_IS_ACTIVE_BLUNTLIST, "BluntList Sale Is Not Active");
        require(!_CLAIMED[msg.sender], "User Has Already Claimed Bluntlist Allocation");
        require(_BLUNTS_MINTED + numberOfTokens <= _MAX_BLUNTS, "Purchase would exceed max supply of Blunts");
        require(_BLUNT_PRICE * numberOfTokens == msg.value, "Ether value sent is not correct. 0.08 ETH Per Blunt | 80000000000000000 WEI");
        require(numberOfTokens <= _MAX_BLUNTS_PURCHASE && numberOfTokens > 0, "Can only mint max 20 Blunts at a time, and a minimum of 1");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, root, leaf), "Invalid Merkle Tree, Msg.sender Is Not On BluntList");

        //One BluntList Transaction Per User
        _CLAIMED[msg.sender] = true;

        //Mints Blunts
        for(uint256 i = 0; i < numberOfTokens; i++) 
        {
            if (_BLUNTS_MINTED <= _MAX_BLUNTS) 
            {
                _mint(msg.sender, _BLUNTS_MINTED, 1, "");
                _BLUNTS_MINTED += 1;
            }
        }

        //Purchase 3 Or More, Get 1 Free
        if(numberOfTokens >= 3 && _BLUNTS_MINTED < _MAX_BLUNTS) 
        {
            uint256 numFree = numberOfTokens / 3;
            for(uint256 i = 0; i < numFree; i++)
            {
                _mint(msg.sender, _BLUNTS_MINTED, 1, "");
                _BLUNTS_MINTED += 1;
            }
        }

        //Finishes Mint
        emit BluntHeadsMinted(msg.sender, numberOfTokens);
    }

    /*--------------------
        * PUBLIC VIEW *
    ---------------------*/

    /**
     * @dev URI for decoding storage of tokenIDs
     */
    function uri(uint256 tokenId) override public view returns (string memory) { return(string(abi.encodePacked(_BASE_URI, Strings.toString(tokenId), ".json"))); }

    /**
     * @dev Shows Total Supply
     */
    function totalSupply() public view returns (uint256 supply) { return(_MAX_BLUNTS); }

    /*--------------------
          * ADMIN *
    ---------------------*/

    /**
     * @dev Withdraws Ether From The Contract
     */
    function __withdrawEther() external onlyOwner 
    { 
        require(address(this).balance > 0, "Zero Ether Balance");
        payable(msg.sender).transfer(address(this).balance); 
    }
    
    /**
     * @dev Withdraws ERC-20
     */
    function __withdrawERC20(address tokenAddress) external onlyOwner 
    { 
        IERC20 erc20Token = IERC20(tokenAddress);
        require(erc20Token.balanceOf(address(this)) > 0, "Zero Token Balance");
        erc20Token.transfer(_BHMultisig, erc20Token.balanceOf(address(this))); 
    }

    /**
     * @dev Reserves Blunt Heads For Team
     */
    function _reserveBluntHeads(uint256 numberOfTokens) public onlyOwner
    {
        //Mints Blunts
        for(uint256 i = 0; i < numberOfTokens; i++) 
        {
            if (_BLUNTS_MINTED <= _MAX_BLUNTS) 
            {
                _mint(_BHMultisig, _BLUNTS_MINTED, 1, "");
                _BLUNTS_MINTED += 1;
            }
        }
    }

    /**
     * @dev Sets Base URI For .json hosting
     */
    function __setBaseURI(string memory BASE_URI) external onlyOwner { _BASE_URI = BASE_URI; }

    /**
     * @dev Sets Max Blunts for future Blunt Expansion Packs
     */
    function __setMaxBlunts(uint256 MAX_BLUNTS) external onlyOwner { _MAX_BLUNTS = MAX_BLUNTS; }

    /**
     * @dev Sets Max Blunts Purchaseable by Wallet
     */
    function __setMaxBluntsPurchase(uint256 MAX_BLUNTS_PURCHASE) external onlyOwner { _MAX_BLUNTS_PURCHASE = MAX_BLUNTS_PURCHASE; }

    /**
     * @dev Sets Future Blunt Price
     */
    function __setBluntPrice(uint256 BLUNT_PRICE) external onlyOwner { _BLUNT_PRICE = BLUNT_PRICE; }

    /**
     * @dev Flips Allowing Multiple Purchases for future Blunt Expansion Packs
     */
    function __flip_allowMultiplePurchases() external onlyOwner { _ALLOW_MULTIPLE_PURCHASES = !_ALLOW_MULTIPLE_PURCHASES; }
    
    /**
     * @dev Flips Sale State
     */
    function __Flip_Sale_State_Public() external onlyOwner { _SALE_IS_ACTIVE_PUBLIC = !_SALE_IS_ACTIVE_PUBLIC; }

    /**
     * @dev Flips Sale State BluntList
     */
    function __Flip_Sale_State_BluntList() external onlyOwner { _SALE_IS_ACTIVE_BLUNTLIST = !_SALE_IS_ACTIVE_BLUNTLIST; }

    /**
     * @dev Ends Sale
     */
    function __endSale() external onlyOwner { _SALE_IS_ACTIVE_BLUNTLIST = false; _SALE_IS_ACTIVE_PUBLIC = false; }

    /**
     * @dev Pauses Contract
     */
    function __pause() external onlyOwner { _pause(); }

    /**
     * @dev Unpauses Contract
     */
    function __unpause() external onlyOwner { _unpause(); }

    /**
     * @dev Modifies Merkle Root
     */
    function __modifyMerkleRoot(bytes32 newRoot) external onlyOwner { root = newRoot; }

    /*--------------------
         * INTERNAL *
    ---------------------*/
    
    /**
     * @dev Conforms to ERC-1155 Standard
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override 
    { 
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); 
    }
}