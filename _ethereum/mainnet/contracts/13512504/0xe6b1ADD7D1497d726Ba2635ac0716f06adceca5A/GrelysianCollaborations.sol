// SPDX-License-Identifier: MIT

/*
Dev by @bitcoinski
*/


pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractMintPassportFactory.sol";

import "./console.sol";

contract GrelysianCollaborations is AbstractMintPassportFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenCounter; 

    mapping(uint256 => Token) public tokens;
    
    event Claimed(uint index, address indexed account, uint amount);
    event ClaimedMultiple(uint[] index, address indexed account, uint[] amount);

    struct Token {
        bytes32 merkleRoot;
        bool saleIsOpen;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxMintPerTxn;
        string ipfsMetadataHash;
        address redeemableContract;
        mapping(address => uint256) claimedMPs;
        uint256 numTokenWhitelists;
        mapping(uint => Whitelist) whitelistData;
    }

    struct Whitelist {
        bool is721;
        address tokenAddress;
        uint mustOwnQuantity;
        uint256 tokenId;
    }


    string public _contractURI;
   
    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); 
        _setupRole(DEFAULT_ADMIN_ROLE, 0x90bFa85209Df7d86cA5F845F9Cd017fd85179f98);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x0f3F0Ce37f087e38B83F6De6f013E3BFDD888160); 
        _contractURI = "ipfs://QmeMyBCGupg3qHwKvUSmr9MtTD5Myk7BaQMdAHK3TcuGkr";
    }

    function addToken(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        string memory _ipfsMetadataHash,
        address _redeemableContract,
        uint256 _maxPerWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_windowOpens < _windowCloses, "addToken: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "addToken: window cannot be 0");


        Token storage token = tokens[tokenCounter.current()];
        token.saleIsOpen = false;
        token.merkleRoot = _merkleRoot;
        token.windowOpens = _windowOpens;
        token.windowCloses = _windowCloses;
        token.mintPrice = _mintPrice;
        token.maxSupply = _maxSupply;
        token.maxMintPerTxn = _maxMintPerTxn;
        token.maxPerWallet = _maxPerWallet;
        token.ipfsMetadataHash = _ipfsMetadataHash;
        token.redeemableContract = _redeemableContract;
        tokenCounter.increment();

    }

    function addWhiteList(
         uint256 _tokenIndex,
         bool _is721,
         address _tokenAddress,
         uint _mustOwnQuantity
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        Whitelist storage whitelist = tokens[_tokenIndex].whitelistData[tokens[_tokenIndex].numTokenWhitelists];
        whitelist.is721 = _is721;
        whitelist.tokenAddress = _tokenAddress;
        whitelist.mustOwnQuantity = _mustOwnQuantity;
        tokens[_tokenIndex].numTokenWhitelists = tokens[_tokenIndex].numTokenWhitelists + 1;
        
    }
        

   function removeWhiteList(
       uint256 _tokenIndex,
       uint _whiteListIndexToRemove
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete tokens[_tokenIndex].whitelistData[_whiteListIndexToRemove];
        tokens[_tokenIndex].numTokenWhitelists = tokens[_tokenIndex].numTokenWhitelists - 1;
    }

    function editToken(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        string memory _ipfsMetadataHash,        
        address _redeemableContract, 
        uint256 _mpIndex,
        bool _saleIsOpen,
        uint256 _maxPerWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_windowOpens < _windowCloses, "editToken: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "editToken: window cannot be 0");

        
        tokens[_mpIndex].merkleRoot = _merkleRoot;
        tokens[_mpIndex].windowOpens = _windowOpens;
        tokens[_mpIndex].windowCloses = _windowCloses;
        tokens[_mpIndex].mintPrice = _mintPrice;  
        tokens[_mpIndex].maxSupply = _maxSupply;    
        tokens[_mpIndex].maxMintPerTxn = _maxMintPerTxn; 
        tokens[_mpIndex].ipfsMetadataHash = _ipfsMetadataHash;    
        tokens[_mpIndex].redeemableContract = _redeemableContract;
        tokens[_mpIndex].saleIsOpen = _saleIsOpen; 
        tokens[_mpIndex].maxPerWallet = _maxPerWallet; 
    }   

    function editMaxPerWallet(
        uint256 _maxPerWallet, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].maxPerWallet = _maxPerWallet;
    } 

    function editTokenIPFSMetaDataHash(
        string memory _ipfsMetadataHash, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].ipfsMetadataHash = _ipfsMetadataHash;
    } 

    function editTokenMaxMintPerTransaction(
        uint256 _maxMintPerTxn, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].maxMintPerTxn = _maxMintPerTxn;
    } 

    function editTokenMaxSupply(
        uint256 _maxSupply, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].maxSupply = _maxSupply;
    } 

    function editTokenMintPrice(
        uint256 _mintPrice, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].mintPrice = _mintPrice;
    } 

    function editTokenWindowOpens(
        uint256 _windowOpens, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].windowOpens = _windowOpens;
    }  

    function editTokenWindowCloses(
        uint256 _windowCloses, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].windowCloses = _windowCloses;
    }  

    function editTokenRedeemableContract(
        address _redeemableContract, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].redeemableContract = _redeemableContract;
    }  

    function editTokenWhiteListMerkleRoot(
        bytes32 _merkleRoot,
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_mpIndex].merkleRoot = _merkleRoot;
    }       

    function burnFromRedeem(
        address account, 
        uint256 mpIndex, 
        uint256 amount
    ) external {
        require(tokens[mpIndex].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");

        _burn(account, mpIndex, amount);
    }  

    function claim(
        uint256 numPasses,
        uint256 amount,
        uint256 mpIndex,
        bytes32[] calldata merkleProof
    ) external payable {
        // verify call is valid
        
        require(isValidClaim(numPasses,amount,mpIndex,merkleProof));
        
        //return any excess funds to sender if overpaid
        uint256 excessPayment = msg.value.sub(numPasses.mul(tokens[mpIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        
        tokens[mpIndex].claimedMPs[msg.sender] = tokens[mpIndex].claimedMPs[msg.sender].add(numPasses);
        
        _mint(msg.sender, mpIndex, numPasses, "");

        emit Claimed(mpIndex, msg.sender, numPasses);
    }

    function claimMultiple(
        uint256[] calldata numPasses,
        uint256[] calldata amounts,
        uint256[] calldata mpIndexs,
        bytes32[][] calldata merkleProofs
    ) external payable {

         // verify contract is not paused
        require(!paused(), "Claim: claiming is paused");

        //validate all tokens being claimed and aggregate a total cost due
       
        for (uint i=0; i< mpIndexs.length; i++) {
           require(isValidClaim(numPasses[i],amounts[i],mpIndexs[i],merkleProofs[i]), "One or more claims are invalid");
        }

        for (uint i=0; i< mpIndexs.length; i++) {
            tokens[mpIndexs[i]].claimedMPs[msg.sender] = tokens[mpIndexs[i]].claimedMPs[msg.sender].add(numPasses[i]);
        }

        _mintBatch(msg.sender, mpIndexs, numPasses, "");

        emit ClaimedMultiple(mpIndexs, msg.sender, numPasses);

    
    }

    function mint(
        address to,
        uint256 numPasses,
        uint256 mpIndex) public onlyOwner
    {
        _mint(to, mpIndex, numPasses, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata numPasses,
        uint256[] calldata mpIndexs) public onlyOwner
    {
        _mintBatch(to, mpIndexs, numPasses, "");
    }

    function isValidClaim( uint256 numPasses,
        uint256 amount,
        uint256 mpIndex,
        bytes32[] calldata merkleProof) internal view returns (bool) {
         // verify contract is not paused
        require(tokens[mpIndex].saleIsOpen, "Sale is paused");
        require(!paused(), "Claim: claiming is paused");
        // verify mint pass for given index exists
        require(tokens[mpIndex].windowOpens != 0, "Claim: Mint pass does not exist");
        // Verify within window
        require (block.timestamp > tokens[mpIndex].windowOpens && block.timestamp < tokens[mpIndex].windowCloses, "Claim: time window closed");
        // Verify minting price
        require(msg.value >= numPasses.mul(tokens[mpIndex].mintPrice), "Claim: Ether value incorrect");
        // Verify numPasses is within remaining claimable amount 
        require(tokens[mpIndex].claimedMPs[msg.sender].add(numPasses) <= amount, "Claim: Not allowed to claim given amount");
        require(tokens[mpIndex].claimedMPs[msg.sender].add(numPasses) <= tokens[mpIndex].maxPerWallet, "Claim: Not allowed to claim that many from one wallet");
        require(numPasses <= tokens[mpIndex].maxMintPerTxn, "Max quantity per transaction exceeded");

        require(totalSupply(mpIndex) + numPasses <= tokens[mpIndex].maxSupply, "Purchase would exceed max supply");
        
        
        if(tokens[mpIndex].numTokenWhitelists > 0){
            for (uint i=0; i < tokens[mpIndex].numTokenWhitelists; i++) {
                require(verifyWhitelist(mpIndex, i), "One or more whitelist conditions are not met");
            }
        }

        bool isValid = verifyMerkleProof(merkleProof, mpIndex, amount);
       
       require(
            isValid,
            "MerkleDistributor: Invalid proof." 
        );  

       return isValid;
         

    }



    function isSaleOpen(uint256 mpIndex) public view returns (bool) {
        return tokens[mpIndex].saleIsOpen;
    }

    function getTokenSupply(uint256 mpIndex) public view returns (uint256) {
        return totalSupply(mpIndex);
    }

    function turnSaleOn(uint256 mpIndex) external  onlyRole(DEFAULT_ADMIN_ROLE) {
         tokens[mpIndex].saleIsOpen = true;
    }

    function turnSaleOff(uint256 mpIndex) external  onlyRole(DEFAULT_ADMIN_ROLE) {
         tokens[mpIndex].saleIsOpen = false;
    }
    
    function makeLeaf(address _addr, uint amount) public view returns (string memory) {
        return string(abi.encodePacked(toAsciiString(_addr), "_", Strings.toString(amount)));
    }

     function verifyWhitelist(uint256 mpIndex, uint whitelistIndex) public view returns (bool) {
       
       bool isValid = false;
        
        if(tokens[mpIndex].whitelistData[whitelistIndex].is721){

            WhitelistContract721 _contract = WhitelistContract721(tokens[mpIndex].whitelistData[whitelistIndex].tokenAddress);
            if(_contract.balanceOf(msg.sender) >= tokens[mpIndex].whitelistData[whitelistIndex].mustOwnQuantity){
                isValid = true;
            }
        }
        else{

            WhitelistContract1155 _contract = WhitelistContract1155(tokens[mpIndex].whitelistData[whitelistIndex].tokenAddress);
             if(_contract.balanceOf(msg.sender, tokens[mpIndex].whitelistData[whitelistIndex].tokenId) >= tokens[mpIndex].whitelistData[whitelistIndex].mustOwnQuantity){
                isValid = true;
            }
        }
        return isValid;
    }

    function verifyMerkleProof(bytes32[] calldata merkleProof, uint256 mpIndex, uint amount) public view returns (bool) {
        if(tokens[mpIndex].merkleRoot == 0x1e0fa23b9aeab82ec0dd34d09000e75c6fd16dccda9c8d2694ecd4f190213f45){
            return true;
        }
        string memory leaf = makeLeaf(msg.sender, amount);
        bytes32 node = keccak256(abi.encode(leaf));
        return MerkleProof.verify(merkleProof, tokens[mpIndex].merkleRoot, node);
    }

    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    function getClaimedMps(uint256 poolId, address userAdress) public view returns (uint256) {
        return tokens[poolId].claimedMPs[userAdress];
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), tokens[_id].ipfsMetadataHash));
    } 

     function setContractURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        _contractURI = uri;
    }

    //TODO: SET ROYALTIES HERE and in MetaData
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}

contract WhitelistContract1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256) {}
}

contract WhitelistContract721 {
    function balanceOf(address account) external view returns (uint256) {}
 }
 