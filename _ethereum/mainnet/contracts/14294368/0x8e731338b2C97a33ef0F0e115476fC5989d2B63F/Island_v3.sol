// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ReentrancyGuard.sol";
import "MerkleProof.sol";
import "Ownable.sol";
import "ERC721A.sol";

contract Metablocks is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;
    // uint256 public constant decimals = 18;
    uint256 public constant _whiteBatch = 2;
    uint256 public constant _whiteMaxMint = 2;
    uint256 public constant _publicBatch = 2;
    uint256 public constant _publicMaxMint = 8888;
    uint256 public reservedForPrivileged = 30;
    uint256 public eth_mint_price;
    uint256 public maxNftCap;
    string private _notRevealedURL;
    string private _revealedURL;
    bytes32 private _merkleRootHash;
    address private _developer;
    address[2] private _whitdrawAddr;
    
    enum Stages {
        NotStarted,
        OnlyWhitelistMint,
        PublicMint,
        Revealed
    }
    Stages private _currentStage = Stages.NotStarted;

    mapping(address => uint256) private _whiteCapMap;
    mapping(address => uint256) private _publicCapMap;

    // Constructor, 
    constructor(
        address param_whitdrawAddr1,
        address param_whitdrawAddr2,
        uint256 param_maxNftCap,
        uint256 param_eth_mint_price,
        string memory param_notRevealedURL,
        string memory param_revealedURL,
        bytes32 param_root_hash
    ) ERC721A("Metablock", "MB") {

        //Withdrawals
        _whitdrawAddr[0] = param_whitdrawAddr1;
        _whitdrawAddr[1] = param_whitdrawAddr2;

        //Nft config
        maxNftCap = param_maxNftCap;
        eth_mint_price = param_eth_mint_price;

        // Urls
        _notRevealedURL = param_notRevealedURL;
        _revealedURL = param_revealedURL;

        // Developer
        _developer = msg.sender;
        _merkleRootHash = param_root_hash;       
    }

    // Modifiers / Rights
    modifier developerOnly() {
        require(msg.sender == _developer, "You are not a developer");
        _;
    }
    modifier withdrawerOnly() {
        require( (msg.sender == _whitdrawAddr[0]) || (msg.sender == _whitdrawAddr[1]), "You are not a withdrawer" );
        _;
    }
    modifier privilegedOnly() {
        require( (msg.sender == _whitdrawAddr[0]) || 
                 (msg.sender == _whitdrawAddr[1]) ||
                 (msg.sender == _developer), 
                 "You are not privileged." );
        _;
    }
   


    // MINTING FUNCTIONS

    function PublicMint(uint256 quant) external payable {
        require(_currentStage == Stages.PublicMint, "It is not the public mint stage.");
        require(msg.value >= eth_mint_price, "You don't have enough ETH");

        // Mint config for public
        require(quant <= _publicBatch);
        require(_publicCapMap[msg.sender] + quant <= _publicMaxMint);

        require( _currentIndex + quant <= maxNftCap , "Maximum nft reached" );

        _safeMint(msg.sender, quant);
        _publicCapMap[msg.sender] += quant;
    }

    function WhitelistMint(uint256 quant, bytes32[] calldata _merkleProof ) external payable {       
        require(_currentStage == Stages.OnlyWhitelistMint, "Whitelist stage is over. Try public mint.");
        require(msg.value >= eth_mint_price, "You don't have enough ETH");

        //Check whitelisted members!
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _merkleRootHash, leaf), "Invalid proof");

        // Mint config for whitelisted members
        require(quant <= _whiteBatch);
        require(_whiteCapMap[msg.sender] + quant <= _whiteMaxMint);

        require( _currentIndex + quant <= maxNftCap , "Maximum nft reached" );

        _safeMint(msg.sender, quant);
        _whiteCapMap[msg.sender] += quant;
    }

    function OwnerMint(uint256 quant, address to) external privilegedOnly{
        require(quant <= reservedForPrivileged);

        _safeMint(to, quant);
        reservedForPrivileged -= quant;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (_currentStage != Stages.Revealed) {
            return string(abi.encodePacked(_notRevealedURL));
        } else {
            return string(abi.encodePacked(_revealedURL, tokenId.toString()));
        }
    }

    function CurrentStage() public view returns (string memory) {
        string memory ret;
        if (_currentStage == Stages.NotStarted) ret = "NotStarted";
        if (_currentStage == Stages.OnlyWhitelistMint) ret = "OnlyWhitelistMint";
        if (_currentStage == Stages.PublicMint) ret = "PublicMint";
        if (_currentStage == Stages.Revealed) ret = "Revealed";
        return ret;
    }

    // GETTER FUNCTIONS

    function getSmartContractBalance() public view returns (uint256) {
         return address(this).balance;
     }

    // SETTER FUNCTIONS

    function set_maxNftCap(uint256 x) external developerOnly{
        maxNftCap = x;
    }

    function set_notRevealedUrl(string memory x) external developerOnly{
        _notRevealedURL = x;
    }

    function set_revealedUrf(string memory x) external developerOnly{
        _revealedURL = x;
    }

    function set_eth_mint_price(uint256 x) external developerOnly{
        eth_mint_price = x;
    }

    function set_merkleRootHash(bytes32 x) external developerOnly{
        _merkleRootHash = x;
    }

    // DEVELOPER FUNCTIONS ONLY

    function goNextStage() public developerOnly() {
        require(_currentStage != Stages.Revealed);
        if (_currentStage == Stages.NotStarted) _currentStage = Stages.OnlyWhitelistMint;
        else if (_currentStage == Stages.OnlyWhitelistMint) _currentStage = Stages.PublicMint;
        else if (_currentStage == Stages.PublicMint) _currentStage = Stages.Revealed;
    }

    function goPreviousStage() public developerOnly() {
        require(_currentStage != Stages.NotStarted);
        if (_currentStage == Stages.Revealed) _currentStage = Stages.PublicMint;
        else if (_currentStage == Stages.PublicMint) _currentStage = Stages.OnlyWhitelistMint;
        else if (_currentStage == Stages.OnlyWhitelistMint) _currentStage = Stages.NotStarted;
    }

    // WITHDRAWER FUNCTIONS ONLY

    function withdrawAll() external withdrawerOnly nonReentrant {
        require(getSmartContractBalance() > 0, "Smart Contracts wallet is empty");
        uint256 _currentB = getSmartContractBalance();
        uint256 _divedB = _currentB/2;
        require(_divedB<_currentB);
        (bool success1, ) = payable(_whitdrawAddr[0]).call{value: _divedB}("");
        (bool success2, ) = payable(_whitdrawAddr[1]).call{value: _divedB}("");
        require(success1, "Failed withdraw ");
		require(success2, "Failed withdraw ");
	}

    function isAWithdrawal(address sender) external view returns(bool){
        return sender == _whitdrawAddr[0] || sender == _whitdrawAddr[1];
    }

    function isOnWhitelist(address sender, bytes32[] calldata _merkleProof ) external view returns(bool){

        //Check whitelisted members!
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        bool ret = MerkleProof.verify(_merkleProof, _merkleRootHash, leaf);

        return ret;
    }

    // helpful functions
    function _bytes32ToAdress(bytes32 data) internal pure returns (address) {
        return address(uint160(uint256(data)));
    }

    // temp_ functions
    function send_eth() public payable {
        
    }

}
