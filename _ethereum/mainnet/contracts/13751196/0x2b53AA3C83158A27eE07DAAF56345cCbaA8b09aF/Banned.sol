// SPDX-License-Identifier: MIT

/*  
     
     
           
           #"**T"%"%@  ]b"""""@b ]b"""@#"W%@b]b*%*@#"W%@b@#WWWWW%$@ #%%W8WWW%@
           #        jb @       # ]b   j#   ]b]b   j#   ]b@b       @b#        'Q
           #   ]#    # #   #   @ @b    @b  ]b@b    @b  ]b@b       @M#    #    #
           #   j#   ]#]b   #   @p@b     %  ]b@b     W  ]b@b   @#### #   j#    #
           b        @ @b   #   j#]b        jb]b        jb@b       @ #   j#    #
           b   j#    b@    7    @@b  #     jb]b  #     jb@b   @#### #    #    #
           b   'M    #@    s    @]b  %#    jb]b  @#    jb@b       @ #    #    #
           b        ]b@    #    @jb   @b   jbjb   @b   jb@b       @ #         #
           ########## @##########j#####@####bj#####@####b]mmssmess@ #mmmmmmms#`
     
     
*/

pragma solidity ^0.8.0;

import "./IBanned.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

/*
* @title ERC721 token for Banned
*
* @author original logic by Niftydude, extended by @bitcoinski, @georgefatlion, and borrowed out of love by @andrewjiang
*/
                                                                                                                                               
contract Banned is IBanned, ERC721Enumerable, ERC721Pausable, ERC721Burnable, Ownable, VRFConsumerBase {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private generalCounter; 
    uint public constant MAX_MINT = 10000;

    // VRF stuff
    address public VRFCoordinator;
    address public LinkToken;
    bytes32 internal keyHash;
    uint256 public baseSeed;
  
    struct RedemptionWindow {
        bool open;
        uint8 maxRedeemPerWallet;
        bytes32 merkleRoot;
        uint256 pricePerToken;
    }

    mapping(uint8 => RedemptionWindow) public redemptionWindows;

    // links
    string private baseTokenURI;
    string public _contractURI;
    string public _sourceURI;

    event Minted(address indexed account, string tokens);

    /**
    * @notice Constructor to create contract
    * 
    * @param _name the token name
    * @param _symbol the token symbol
    * @param _maxRedeemPerWallet the max mint per redemption by index
    * @param _merkleRoots the merkle root for redemption window by index
    * @param _prices the prices for each redemption window by index
    * @param _baseTokenURI the respective base URI
    * @param _contractMetaDataURI the respective contract meta data URI
    * @param _VRFCoordinator the address of the vrf coordinator
    * @param _LinkToken link token
    * @param _keyHash chainlink keyhash
    */
    
    constructor (
        string memory _name, 
        string memory _symbol,
        uint8[] memory _maxRedeemPerWallet,
        bytes32[] memory _merkleRoots,
        uint256[] memory _prices,
        string memory _baseTokenURI,
        string memory _contractMetaDataURI,
        address _VRFCoordinator, 
        address _LinkToken,
        bytes32 _keyHash
    ) 
    
    VRFConsumerBase(_VRFCoordinator, _LinkToken)

    ERC721(_name, _symbol) {

        // vrf stuff
        VRFCoordinator = _VRFCoordinator;
        LinkToken = _LinkToken;

        // erc721 stuff
        baseTokenURI = _baseTokenURI;    
        _contractURI = _contractMetaDataURI;
        keyHash = _keyHash;
        
        // set up the different redeption windows
        for(uint8 i = 0; i < _prices.length; i++) {
            redemptionWindows[i].open = false;
            redemptionWindows[i].maxRedeemPerWallet = _maxRedeemPerWallet[i];
            redemptionWindows[i].merkleRoot = _merkleRoots[i];
            redemptionWindows[i].pricePerToken = _prices[i];
        }
    }

    /**
    * @notice Pause redeems until unpause is called. this pauses the whole contract. 
    */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
    * @notice Unpause redeems until pause is called. this unpauses the whole contract. 
    */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
    * @notice edit a redemption window. only writes value if it is different. 
    * 
    * @param _windowID the index of the claim window to set.
    * @param _merkleRoot the window merkleRoot.
    * @param _open the window open state.
    * @param _maxPerWallet the window maximum per wallet. 
    * @param _pricePerToken the window price per token. 
    */
    function editRedemptionWindow(
        uint8 _windowID,
        bytes32 _merkleRoot, 
        bool _open,
        uint8 _maxPerWallet,
        uint256 _pricePerToken
    ) external override onlyOwner {
        if(redemptionWindows[_windowID].open != _open)
        {
            redemptionWindows[_windowID].open = _open;
        }
        if(redemptionWindows[_windowID].maxRedeemPerWallet != _maxPerWallet)
        {
            redemptionWindows[_windowID].maxRedeemPerWallet = _maxPerWallet;
        }
        if(redemptionWindows[_windowID].merkleRoot != _merkleRoot)
        {
            redemptionWindows[_windowID].merkleRoot = _merkleRoot;
        }
        if(redemptionWindows[_windowID].pricePerToken != _pricePerToken)
        {
            redemptionWindows[_windowID].pricePerToken = _pricePerToken;
        }
    }       

    /**
    * @notice Widthdraw Ether from contract.
    * 
    * @param _to the address to send to
    * @param _amount the amount to withdraw
    */
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    /**
    * @notice Mint Banned.
    * 
    * @param windowIndex the index of the claim window to use.
    * @param amount the amount of tokens to mint
    * @param merkleProof the hash proving they are on the list for a given window. only applies to windows 0, 1 and 2.
    */
    function mint(uint8 windowIndex, uint8 amount, bytes32[] calldata merkleProof) external payable override{

        // checks
        require(redemptionWindows[windowIndex].open, "Redeem: window is not open");
        require(amount > 0, "Redeem: amount cannot be zero");

        // check value of transaction is high enough. 
        // if window index is 0 and they have no tokens, 1 mint is free. 
        if (windowIndex == 0 && balanceOf(msg.sender) == 0)
        {
            require(msg.value >= price(amount-1, windowIndex), "Value below price");
        }
        else
        {
            require(msg.value >= price(amount, windowIndex), "Value below price");
        }

        // check if there are enough tokens left for them to mint. 
        require(generalCounter.current() + amount <= MAX_MINT, "Max limit");

        // limit number that can be claimed for given window. 
        require(balanceOf(msg.sender) + amount <=  redemptionWindows[windowIndex].maxRedeemPerWallet, "Too many");

        // check the merkle proof
        require(verifyMerkleProof(merkleProof, redemptionWindows[windowIndex].merkleRoot),"Invalid proof");          

        string memory tokens = "";

        for(uint256 j = 0; j < amount; j++) {
            _safeMint(msg.sender, generalCounter.current());
        
            tokens = string(abi.encodePacked(tokens, generalCounter.current().toString(), ","));
            generalCounter.increment();
        }
        emit Minted(msg.sender, tokens);
    }  

    function ownerMint(
        address to,
        uint8 windowIndex,
        uint8 amount) external onlyOwner
    {
        require(redemptionWindows[windowIndex].open, "Redeem: window is not open");
        require(amount > 0, "Redeem: amount cannot be zero");

        // check if there are enough tokens left for them to mint. 
        require(generalCounter.current() + amount <= MAX_MINT, "Max limit");

        string memory tokens = "";

        for(uint256 j = 0; j < amount; j++) {
            _safeMint(msg.sender, generalCounter.current());
        
            tokens = string(abi.encodePacked(tokens, generalCounter.current().toString(), ","));
            generalCounter.increment();
        }
        emit Minted(msg.sender, tokens);
    }

    /**
    * @notice Verify the merkle proof for a given root.   
    *     
    * @param proof vrf keyhash value
    * @param root vrf keyhash value
    */
    function verifyMerkleProof(bytes32[] memory proof, bytes32 root)
        public
        view
        returns (bool)
    {
        if(root == 0x000000000000000000000000000000000000000000007075626c696373616c65){
            return true;
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
    * @notice assign the returned chainlink vrf random number to baseSeed variable.   
    *     
    * @param requestId the id of the request - unused.
    * @param randomness the random number from chainlink vrf. 
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        baseSeed = randomness;
    }

    /**
    * @notice Get the transaction price for a given number of tokens and redemption window. 
    * 
    * @param _amount the number of tokens
    * @param _windowIndex the ID of the window to check. 
    */
    function price(uint8 _amount, uint8 _windowIndex) public view returns (uint256) {
        return redemptionWindows[_windowIndex].pricePerToken.mul(_amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }  

    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _baseTokenURI the respective base URI
    */
    function setBaseURI(string memory _baseTokenURI) external override onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }

    /**
    * @notice Return the baseTokenURI
    */   
    function _baseURI() internal view override returns (string memory) {
            return baseTokenURI;
    }    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    } 

    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param uri the uri of the processing source code
    */
    function setSourceURI(string memory uri) external onlyOwner{
        _sourceURI = uri;
    }  

    function setContractURI(string memory uri) external onlyOwner{
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
    * @notice Call chainlink to get a random number to use as the base for the random seeds.  
    *     
    */
    function plantSeed(uint256 fee) public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
    * @notice Get the random seed for a given token, expanded from the baseSeed from Chainlink VRF. 
    * 
    * @param tokenId the token id 
    */
    function getSeed(uint256 tokenId) public view returns (uint256)
    {
        require(totalSupply()>tokenId, "Token Not Found");

        if (baseSeed == 0){
            return 0;
        }
        else{
            return uint256(keccak256(abi.encode(baseSeed, tokenId))) % 2000000000;
        }
    }
}