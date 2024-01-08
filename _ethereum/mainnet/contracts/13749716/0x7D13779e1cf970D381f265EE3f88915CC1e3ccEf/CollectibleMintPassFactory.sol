// SPDX-License-Identifier: MIT

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMWWMWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMM
MMMMMMMMMMMMMMMWX0XWWNMMMWWMMMMMMMMMMMMMMMMMMMMMWWNNNXXXKKXNWMMMMWWMMMWMWMMMMMMMMMMMMMMMMMMNKK00OkOXMMWOllcc::oXWWWWWWWWWWWWWWWWWWMMMMMMMMMM
MMMMMMMMMMMMMMXo,,,;;dNMO:,;;::ccllooddxkOXWWk:;,,''.......':dXMMNOxxkkkkOO0000klcc::;:OMM0;...    cNMK,      '0WNK0OkkOO0XWWWWWWWWMMMMMMMMM
MMMMMMMMMMMMMMO..:. ;OWMo                 .cOc                ;0MO'         ...        cNMx.       'OMO.      ,ko,.      ..,cxKWWWWWMMMMMMMM
MMMMMMMMMMMMMMXdlcc::kWWc     ...  ..       ..       .l:       lWk.                    '0Md         oWk.       .              .dNWWWWMMMMMMM
MMMMMMMMMMMMMMMMMMMOcOMWd,,':xKKxook0c               :KO,      ;Xx.       .:lcc:'      .dWl         ;Xx.             .lO:      '0WWWWMMMMMMM
MMMMMMMMMMMMMMOlloolc0MXc...;dOOxxx0Xl.              .cc.      cNd        ;XMMMM0,      cXc         .Od              .OWd.     .OWWWWWMMMMMM
MMMMMMMMMMMMMM0d: .cdKM0'       .:co:       'c.              .c0Wo        ,OKKXWWl      'Oc          oo               'dkkxddolkNWWWWWMMMMMM
MMMMMMMMMMMMMNx:' .lkNMk.                .'lKK;              .l0Nc         ....xWO'     .l;          ,;       cc.       .;dKWWWWWWWWWWWMMMMM
MMMMMMMMMMMMMXocddddONMx.                cKMMN:        .       .kc             oWNc      .     .;.           .kWOl.        .cONWWWWWWWWMMMMM
MMMMMMMMMMMMMO.'dkkOXMMo                  'xNWl       :Ko.      c;        ,olloKMMk.           :0:           .dXXNKx:.       .oNWWWWWWWMMMMM
MMMMMMMMMMMMMx..::::kWWx'..'cxxxdc;c:.      lNo       :N0,      ..       .xMWMMMMMN:           cNx.           ...',;d0o.      .kWWWWWWWMMMMM
MMMMMMMMMMMMMOckMMNXWMNd'',:xKNWXOkKXo.     '0x.      ,KX;               .kMWMMMMMMx.          oWX:                 :XWl      .dWWWWWWWMMMMM
MMMMMMMMMMMMMo'oodo,kMK;     .''',;,'.      ;Xk.      '0Nc                ';:::xNMMX;         .xMWk.                :XK;      .kWWWWWWWMMMMM
MMMMMMMMMMMMWo......kM0'                   ;0M0'      ,0Wx'.''',.              ;KMMWd.      ..;0MMNx;;::ccllol'      ..       :XWWWWWWWMMMMM
MMMMMMMMMMMMMN00OOk0NMNxlcc::;;,'''.....'cxNMMW0xxkOOOKWMWNXNNWW0c;,,'''''.....lNMMMNkxxkkO00KXWMMMMMMMMMMMMMWXx:..        .'lKWWWWWWWWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXKXWMMMMMMMMMMMMMMMMWMMMMMMWWWWWWWNNNNXXXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWN0kxdooodx0XWWWWWWWWWWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWMMMMMM
Dev by @bitcoinski
*/


pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractMintPassFactory.sol";

import "./console.sol";




contract CollectibleMintPassFactory is AbstractMintPassFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private mpCounter; 
  
    mapping(uint256 => MintPass) public mintPasses;
    
    event Claimed(uint index, address indexed account, uint amount);
    event ClaimedMultiple(uint[] index, address indexed account, uint[] amount);

    struct MintPass {
        bytes32 merkleRoot;
        bool saleIsOpen;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 numMinted;
        uint256 maxPerWallet;
        uint256 maxMintPerTxn;
        string ipfsMetadataHash;
        address redeemableContract; // contract of the redeemable NFT
        mapping(address => uint256) claimedMPs;
    }

    string public _contractURI;
   
    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC1155("ipfs://ipfs/") {
        name_ = _name;
        symbol_ = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); 
        _setupRole(DEFAULT_ADMIN_ROLE, 0x90bFa85209Df7d86cA5F845F9Cd017fd85179f98);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x9013Ee19024D916BeD4CE530f9d570ED924E7EF6);
        _contractURI = "ipfs://QmQbpbceN3BexSLgKUkKpxJZWnbYg2pE7ZCzPKSVkKTHoL";
    }

    function addMintPass(
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
        require(_windowOpens < _windowCloses, "addMintPass: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "addMintPass: window cannot be 0");


        MintPass storage mp = mintPasses[mpCounter.current()];
        mp.saleIsOpen = false;
        mp.merkleRoot = _merkleRoot;
        mp.windowOpens = _windowOpens;
        mp.windowCloses = _windowCloses;
        mp.mintPrice = _mintPrice;
        mp.maxSupply = _maxSupply;
        mp.maxMintPerTxn = _maxMintPerTxn;
        mp.maxPerWallet = _maxPerWallet;
        mp.numMinted = 0;
        mp.ipfsMetadataHash = _ipfsMetadataHash;
        mp.redeemableContract = _redeemableContract;
        mpCounter.increment();

    }

    function editMintPass(
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
        require(_windowOpens < _windowCloses, "editMintPass: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "editMintPass: window cannot be 0");

        
        mintPasses[_mpIndex].merkleRoot = _merkleRoot;
        mintPasses[_mpIndex].windowOpens = _windowOpens;
        mintPasses[_mpIndex].windowCloses = _windowCloses;
        mintPasses[_mpIndex].mintPrice = _mintPrice;  
        mintPasses[_mpIndex].maxSupply = _maxSupply;    
        mintPasses[_mpIndex].maxMintPerTxn = _maxMintPerTxn; 
        mintPasses[_mpIndex].ipfsMetadataHash = _ipfsMetadataHash;    
        mintPasses[_mpIndex].redeemableContract = _redeemableContract;
        mintPasses[_mpIndex].saleIsOpen = _saleIsOpen; 
        mintPasses[_mpIndex].maxPerWallet = _maxPerWallet; 
    }   

    
    function editMaxPerWallet(
        uint256 _maxPerWallet, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].maxPerWallet = _maxPerWallet;
    } 

    function editTokenIPFSMetaDataHash(
        string memory _ipfsMetadataHash, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].ipfsMetadataHash = _ipfsMetadataHash;
    } 

    function editTokenMaxMintPerTransaction(
        uint256 _maxMintPerTxn, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].maxMintPerTxn = _maxMintPerTxn;
    } 

    function editTokenMaxSupply(
        uint256 _maxSupply, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].maxSupply = _maxSupply;
    } 

    function editTokenMintPrice(
        uint256 _mintPrice, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].mintPrice = _mintPrice;
    } 

    function editTokenWindowOpens(
        uint256 _windowOpens, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].windowOpens = _windowOpens;
    }  

    function editTokenWindowCloses(
        uint256 _windowCloses, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].windowCloses = _windowCloses;
    }  

    function editTokenRedeemableContract(
        address _redeemableContract, 
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].redeemableContract = _redeemableContract;
    }  

    function editTokenWhiteListMerkleRoot(
        bytes32 _merkleRoot,
        uint256 _mpIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPasses[_mpIndex].merkleRoot = _merkleRoot;
    }         

    function burnFromRedeem(
        address account, 
        uint256 mpIndex, 
        uint256 amount
    ) external {
        require(mintPasses[mpIndex].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");

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
        uint256 excessPayment = msg.value.sub(numPasses.mul(mintPasses[mpIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        
        mintPasses[mpIndex].claimedMPs[msg.sender] = mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses);
        
        uint numToMint = 0;
        if(mpIndex == 0){
               numToMint += numPasses;
               
        }
        else if(mpIndex == 1){
            mintPasses[mpIndex].numMinted = mintPasses[mpIndex].numMinted.add(numPasses);
            numToMint += numPasses * 6;
        }
        else if(mpIndex == 2){
           mintPasses[mpIndex].numMinted = mintPasses[mpIndex].numMinted.add(numPasses);
           numToMint += numPasses * 12;
        }
         else if(mpIndex == 3){
           mintPasses[mpIndex].numMinted = mintPasses[mpIndex].numMinted.add(numPasses);
           numToMint += numPasses;
        }

        _mint(msg.sender, 0, numToMint, "");



        emit Claimed(0, msg.sender, numToMint);
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
            mintPasses[mpIndexs[i]].claimedMPs[msg.sender] = mintPasses[mpIndexs[i]].claimedMPs[msg.sender].add(numPasses[i]);
        }

        uint numToMint = 0;
        for (uint i=0; i< mpIndexs.length; i++) {
           if(mpIndexs[i] == 0){
               numToMint += numPasses[i];
               
           }
           else if(mpIndexs[i] == 1){
               mintPasses[mpIndexs[i]].numMinted = mintPasses[mpIndexs[i]].numMinted.add(numPasses[i]);
               numToMint += numPasses[i] * 6;
           }
           else if(mpIndexs[i] == 2){
               mintPasses[mpIndexs[i]].numMinted = mintPasses[mpIndexs[i]].numMinted.add(numPasses[i]);
               numToMint += numPasses[i] * 12;
           }
           else if(mpIndexs[i] == 3){
               mintPasses[mpIndexs[i]].numMinted = mintPasses[mpIndexs[i]].numMinted.add(numPasses[i]);
               numToMint += numPasses[i];
           }
        }

        _mint(msg.sender, 0, numToMint, "");
        uint256[] memory emitID = new uint256[](1);
        emitID[0] = 0;
        uint256[] memory emitAmount = new uint256[](1);
        emitAmount[0] = numToMint;
        emit ClaimedMultiple(emitID, msg.sender, emitAmount);

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
        require(mintPasses[mpIndex].saleIsOpen, "Sale is paused");
        require(!paused(), "Claim: claiming is paused");
        // verify mint pass for given index exists
        require(mintPasses[mpIndex].windowOpens != 0, "Claim: Mint pass does not exist");
        // Verify within window
        require (block.timestamp > mintPasses[mpIndex].windowOpens && block.timestamp < mintPasses[mpIndex].windowCloses, "Claim: time window closed");
        // Verify minting price
        require(msg.value >= numPasses.mul(mintPasses[mpIndex].mintPrice), "Claim: Ether value incorrect");
        // Verify numPasses is within remaining claimable amount 
        require(mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses) <= amount, "Claim: Not allowed to claim given amount");
        require(mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses) <= mintPasses[mpIndex].maxPerWallet, "Claim: Not allowed to claim that many from one wallet");
        require(numPasses <= mintPasses[mpIndex].maxMintPerTxn, "Max quantity per transaction exceeded");

        require(getTokenSupply(mpIndex) + numPasses <= mintPasses[mpIndex].maxSupply, "Purchase would exceed max supply");
        
        bool isValid = verifyMerkleProof(merkleProof, mpIndex, amount);
       
       require(
            isValid,
            "MerkleDistributor: Invalid proof." 
        );  
       return isValid;
         

    }



   function isSaleOpen(uint256 mpIndex) public view returns (bool) {
        if(paused()){
            return false;
        }
        if(block.timestamp > mintPasses[mpIndex].windowOpens && block.timestamp < mintPasses[mpIndex].windowCloses){
            return mintPasses[mpIndex].saleIsOpen;
        }
        else{
            return false;
        }
        
    }

    function getTokenSupply(uint256 mpIndex) public view returns (uint256) {
        if(mpIndex > 0){
            return mintPasses[mpIndex].numMinted;
        }
        else{
            return totalSupply(mpIndex);
        }
        
    }

    function turnSaleOn(uint256 mpIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
         mintPasses[mpIndex].saleIsOpen = true;
    }

    function turnSaleOff(uint256 mpIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
         mintPasses[mpIndex].saleIsOpen = false;
    }
    


    function makeLeaf(address _addr, uint amount) public view returns (string memory) {
        return string(abi.encodePacked(toAsciiString(_addr), "_", Strings.toString(amount)));
    }

    function verifyMerkleProof(bytes32[] calldata merkleProof, uint256 mpIndex, uint amount) public view returns (bool) {
        if(mintPasses[mpIndex].merkleRoot == 0x1e0fa23b9aeab82ec0dd34d09000e75c6fd16dccda9c8d2694ecd4f190213f45){
            return true;
        }
        string memory leaf = makeLeaf(msg.sender, amount);
        bytes32 node = keccak256(abi.encode(leaf));
        return MerkleProof.verify(merkleProof, mintPasses[mpIndex].merkleRoot, node);
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
        return mintPasses[poolId].claimedMPs[userAdress];
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), mintPasses[_id].ipfsMetadataHash));
    } 

     function setContractURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        _contractURI = uri;
    }

    //TODO: SET ROYALTIES HERE and in MetaData
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
