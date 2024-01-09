// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//    /ohhhyyyssssssssysyysd                                       
//   N.                   N                                        
//    -N                                                           
//    -N                                                           
//    :                   N                                        
//    :         hssssssoss+N                                       
//    -                   /                                        
//    : N                 /                                        
//    -                   /d                                       
//   N:                   /h                                       
//   N-yh               hh/d                                       
//    dddN             N d                                         
                                                                
                                                                
//    N                                                            
//   N/+oosssooooooooooooo+d                                       
//   N.d                  /y                                       
//    -d                  /y                                       
//    -d                  /y                                       
//   N/d                  +y                                       
//   N+                   /s                                       
//   N+                   /sN                                      
//   N/d                  /sN                                      
//   N/                   /sN                                      
//    /NN                 :y                                       
//    /hhdd    ddddddddddd:s                                       
//    dhyhshdddhhhhhhhhhyhyd                                       
                                                                
                                                                
                                                                
                                                                
                                                                
//          N hhhhhd                                               
//          dydN  NhdN                                             
//         Ndy    NhyN                                             
//          Nhhd  hh                                               
//           NN d NN                                               

/// @creator:     godot movement*
/// @author:      peker.eth - twitter.com/peker_eth

import "./ERC721.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract GodotMovement is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using SafeERC20 for IERC20;
    
    bytes32 public root;
    
    address proxyRegistryAddress;

    string BASE_URI = "https://api.godotmovement.com/metadata/";
    
    bool public IS_PRESALE_ACTIVE = false;
    bool public IS_SALE_ACTIVE = false;
    
    uint constant TOTAL_SUPPLY = 9999;
    uint constant INCREASED_MAX_TOKEN_ID = TOTAL_SUPPLY + 2;
    uint constant MINT_PRICE = 0.08 ether; 
    uint constant MINT_PRICE_ASH = 15 ether; 

    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_TX = 10;
    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 20;
    
    mapping (address => uint) addressToMintCount;

    IERC20 ASH;
    
    address COMMUNITY_WALLET = 0xf15017b4C823E3d4E91D9031F1445cb001c3fecB;
    address TEAM_1 = 0x4a481Ac8F43fC87beBc6470552c9CC505BAC8C68;
    address TEAM_2 = 0x51266b01772C9945D33bd0851C981A94c3F5Bf00;
    address TEAM_3 = 0xEAA37d4e3d977aa2F6D460f2Cc8B81ea5Dd96323;
    address TEAM_4 = 0xe5cB2C6ACe5A67191Fd053c0ec60C75E690937D0;
    address TEAM_5 = 0x3385A612e0Eb663dcd2C068F69aD65d092110be8;
    address TEAM_6 = 0x78B21283E86160E943691134aA5f7961cd828630;
    address TEAM_7 = 0x02a54E66A41BAF1Fba3c141e68169b44A9060DB4;
    address TEAM_8 = 0xf93f4075A896accFCcE1eBD4da735250fB0eb7A9;
    address CONTRACT_DEV = 0xA800F34505e8b340cf3Ab8793cB40Bf09042B28F;
    

    constructor(string memory name, string memory symbol, bytes32 merkleroot, string memory baseURI, address _ashAddress, address _proxyRegistryAddress)
    ERC721(name, symbol)
    {
        root = merkleroot;
        BASE_URI = baseURI;
        ASH = IERC20(_ashAddress);
        proxyRegistryAddress = _proxyRegistryAddress;
        _tokenIdCounter.increment();
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function setBaseURI(string memory newUri) 
    public 
    onlyOwner {
        BASE_URI = newUri;
    }

    function togglePublicSale() public 
    onlyOwner 
    {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function togglePreSale() public 
    onlyOwner 
    {
        IS_PRESALE_ACTIVE = !IS_PRESALE_ACTIVE;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function ownerMint(uint numberOfTokens) 
    public 
    onlyOwner {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function presaleMint(address account, uint numberOfTokens, uint256 allowance, string memory key, bytes32[] calldata proof)
    public
    payable
    onlyAccounts
    {
        require(msg.sender == account, "Not allowed");
        require(IS_PRESALE_ACTIVE, "Pre-sale haven't started");
        require(msg.value >= numberOfTokens * MINT_PRICE, "Not enough ethers sent");

        string memory payload = string(abi.encodePacked(Strings.toString(allowance), ":", key));

        require(_verify(_leaf(msg.sender, payload), proof), "Invalid merkle proof");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= allowance, "Exceeds allowance");

        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint numberOfTokens) 
    public 
    payable
    onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_TX, "Too many requested");
        require(msg.value >= numberOfTokens * MINT_PRICE, "Not enough ethers sent");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function presaleMintASH(address account, uint numberOfTokens, uint256 allowance, string memory key, bytes32[] calldata proof)
    public
    onlyAccounts
    {
        require(msg.sender == account, "Not allowed");
        require(IS_PRESALE_ACTIVE, "Pre-sale haven't started");
        
        ASH.safeTransferFrom(msg.sender, address(this), numberOfTokens * MINT_PRICE_ASH);

        string memory payload = string(abi.encodePacked(Strings.toString(allowance), ":", key));

        require(_verify(_leaf(msg.sender, payload), proof), "Invalid merkle proof");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= allowance, "Exceeds allowance");

        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function publicSaleMintASH(uint numberOfTokens)
    public
    onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_TX, "Too many requested");
        
        ASH.safeTransferFrom(msg.sender, address(this), numberOfTokens * MINT_PRICE_ASH);
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function getCurrentMintCount(address _account) public view returns (uint) {
        return addressToMintCount[_account];
    }

    function mintInternal() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
    }

    function withdrawAll() public onlyOwner {
        withdrawETH();
        withdrawASH();
    }

    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(COMMUNITY_WALLET, (balance * 210) / 1000);
        _withdraw(TEAM_1, (balance * 2000) / 10000);
        _withdraw(TEAM_2, (balance * 2000) / 10000);
        _withdraw(TEAM_3, (balance * 2000) / 10000);
        _withdraw(TEAM_4, (balance * 500) / 10000);
        _withdraw(TEAM_5, (balance * 250) / 10000);
        _withdraw(TEAM_6, (balance * 150) / 10000);
        _withdraw(TEAM_7, (balance * 125) / 10000);
        _withdraw(TEAM_8, (balance * 125) / 10000);
        _withdraw(CONTRACT_DEV, (balance * 750) / 10000);

        _withdraw(owner(), address(this).balance);
    }

    function withdrawASH() public onlyOwner {
        uint256 ashBalance = ASH.balanceOf(address(this));
        require(ashBalance > 0);

        ASH.safeTransfer(COMMUNITY_WALLET, (ashBalance * 210) / 1000);
        ASH.safeTransfer(TEAM_1, (ashBalance * 2000) / 10000);
        ASH.safeTransfer(TEAM_2, (ashBalance * 2000) / 10000);
        ASH.safeTransfer(TEAM_3, (ashBalance * 2000) / 10000);
        ASH.safeTransfer(TEAM_4, (ashBalance * 500) / 10000);
        ASH.safeTransfer(TEAM_5, (ashBalance * 250) / 10000);
        ASH.safeTransfer(TEAM_6, (ashBalance * 150) / 10000);
        ASH.safeTransfer(TEAM_7, (ashBalance * 125) / 10000);
        ASH.safeTransfer(TEAM_8, (ashBalance * 125) / 10000);
        ASH.safeTransfer(CONTRACT_DEV, (ashBalance * 750) / 10000);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current() - 1;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _leaf(address account, string memory payload)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}