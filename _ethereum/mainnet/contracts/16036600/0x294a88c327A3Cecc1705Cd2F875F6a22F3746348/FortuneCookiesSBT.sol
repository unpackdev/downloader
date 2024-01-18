// SPDX-License-Identifier: MIT
/*
                                                                     
                  @@@FORTUNE@@@                                      
            @@@@+++++++++++++99++@@@                                 
         @@++++++++++++++++9+9=99+++++@@                             
       @++++++++++++++++++99+9==99+++++++@@@                         
      +++++++++++++++++++999++9===99+++@@+++++@                      
     +++++++++++++++++9=9999+++====99+++++@++99+@                    
    +++9999+++++++++99+999999+++====99+++++@@@+99++@                 
   @++99++9+++++++++9999999999+++====999+++++@@++999+@               
   +++++++++++++++++9999999999+++9====9999+++++@@++99++@             
  @+++999++++99++9+99999999999+++++=====999+++++++@++99+@            
  @++9999999999999999999=99999999+++====99999++++++++++99+@          
   +9+999999999999999====9=9==999++++====99999+++++++++++++@         
   +9+99999999999999999====999999+++++=====9999+++++++++++9+@        
   +999999999999999999=====999999+9++++======9999++++++++++++@       
   @99999999999999=99999==9999999999++++======99999++++++++++++@     
    @99+99999999999999==99999999999++++++9=====999999+++++++++++@    
     @99999999=9==999=99999999999999++++++9======9999999++++99+++    
      @99999999999=====99999999999999++++++9=====99999999+9++9++++   
       @999999===99999===999999999999+++++++9=======999999999+++++@  
         +99999===99=======9999999999+++++++++@+99======9999999999@  
          @9=99999============99999999+++++++++   @@@++999999===9+   
            +9999999=============99=999+++++++++           @@@@+@    
              +9==9999=99========99999999++9++++@                    
                +99===9999======9=99999999+++++++                    
                  @9======9999====9999999999+++++@                   
                    @+9==66==9999===9999999999++++                   
                      @+9==666======999999999+++++@                  
                         @+9==6666========999999+++@                 
                            @@+9==6666666========99@                 
                                @@++9====666666=9+@                  
                                      @@@@+++@@     
*/
pragma solidity ^0.8.14;

import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./PausableUpgradeable.sol";
import "./RevokableDefaultOperatorFiltererUpgradeable.sol";
import "./RevokableOperatorFiltererUpgradeable.sol";

contract FortuneCookiesSBT is 
    ERC721AUpgradeable,     
    ReentrancyGuardUpgradeable, 
    PausableUpgradeable,
    RevokableDefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable
{
    string public baseURI; 
    string public tokenURISuffix;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public MAX_PER_ADDRESS_WL;
    uint256 public MAX_PER_ADDRESS_PUB;
    uint256 public mintStart;
    uint256 public mintEnd;
    uint256 public whitelistEnd;
    uint256 public totalMinted;
    bytes32 public merkleRoot;

    mapping(address => uint256) mintedAccountsWL;
    mapping(address => uint256) mintedAccountsPublic;

    function initialize(
        uint256 _MAX_PER_ADDRESS_WL,
        uint256 _MAX_PER_ADDRESS_PUB,
        string memory _coverBaseURI,
        string memory _tokenURISuffix,
        uint256 _mintStart,
        uint256 _mintEnd,
        uint256 _whitelistEnd,
        bytes32 _merkleRoot        
    ) initializerERC721A initializer public {
        __ERC721A_init('FCUAT', 'FUAT');
        __Ownable_init();
        __RevokableDefaultOperatorFilterer_init();

        MAX_PER_ADDRESS_WL = _MAX_PER_ADDRESS_WL;
        MAX_PER_ADDRESS_PUB = _MAX_PER_ADDRESS_PUB;
        baseURI = _coverBaseURI;
        tokenURISuffix = _tokenURISuffix;        
        mintStart = _mintStart;
        mintEnd = _mintEnd;
        whitelistEnd = _whitelistEnd;
        totalMinted = 0;
        merkleRoot = _merkleRoot;
    }
    
    // Utilities
    function setNewMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    function _merkleTreeLeaf(address _address) internal pure returns (bytes32) {
        return keccak256((abi.encodePacked(_address)));
    }
    
    function _merkleTreeVerify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    // Mint Setup
    function setFreeMintInfo(uint256 _mintStart, uint256 _mintEnd, uint256 _whitelistEnd, uint256 _MAX_PER_ADDRESS_WL, uint256 _MAX_PER_ADDRESS_PUB) public onlyOwner {                
        mintStart = _mintStart;  // block.timestamp to start mint
        mintEnd = _mintEnd; // block.timestamp to end mint
        whitelistEnd = _whitelistEnd; // block.timestamp to end mint
        MAX_PER_ADDRESS_WL = _MAX_PER_ADDRESS_WL;
        MAX_PER_ADDRESS_PUB = _MAX_PER_ADDRESS_PUB;
    }

    // Mint
    function freeMint(uint256 _quantity, bytes32[] calldata proof) external nonReentrant whenNotPaused {
        require(
            (mintStart <= block.timestamp && mintEnd > block.timestamp), 
            "Mint is not active."
        );           
        require(
            totalMinted + _quantity <= MAX_SUPPLY,
            "ALL SOLD!"
        );  
        if (block.timestamp <= whitelistEnd) {
            require(
                totalMinted + _quantity <= MAX_SUPPLY,
                "Whitelist round is sold out!"
            );  
            require(
                mintedAccountsWL[msg.sender] + _quantity <= MAX_PER_ADDRESS_WL,
                "Sorry, you have minted all your quota for Whitelist Round."
            ); 
            require(_merkleTreeVerify(_merkleTreeLeaf(msg.sender), proof),
                "Sorry, you are not whitelisted for this round. Come back later!"
            );
            _safeMint(msg.sender, _quantity);
            totalMinted += _quantity;
            mintedAccountsWL[msg.sender] += _quantity;
        } else {
            require(
                mintedAccountsPublic[msg.sender] + _quantity <= MAX_PER_ADDRESS_PUB,
                "Sorry, you have minted all your quota for Public Round."
            );            
            _safeMint(msg.sender, _quantity);
            totalMinted += _quantity;
            mintedAccountsPublic[msg.sender] += _quantity;
        }
    }

    // Post Mint
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setTokenURISuffix(string memory _newTokenURISuffix) external onlyOwner {
        tokenURISuffix = _newTokenURISuffix;
    }
    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    }

    // Fund Withdraw
    function withdrawETH(address _to) external onlyOwner {
        require(_to != address(0), "Cant transfer to 0 address!");
        (bool withdrawSucceed, ) = payable(_to).call{ value: address(this).balance }("");
        require(withdrawSucceed, "Withdraw Failed");
    }

    // Admin pause
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Soulbound token implementation
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(from == address(0) || to == address(0), "Soulbound token is non-transferrable!");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // Opensea Operator filter registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable) returns (address) {
        return OwnableUpgradeable.owner();
    }
}