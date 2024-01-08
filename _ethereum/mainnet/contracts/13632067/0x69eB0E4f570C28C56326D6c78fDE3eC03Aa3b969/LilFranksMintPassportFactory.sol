// SPDX-License-Identifier: MIT

/*
*
* Dev by @andrewjiang
* Thanks to @PixelVault_, @bitcoinski, @ultra_dao for driving forward the mint pass approach.
* This smart contract was heavily inspired by you guys. Way to lead the way.
*
* Thanks to the Lil Franks team members:
* Project Lead: @Frankie_Sutera
* Artist: @axlittlexjuice
* Community & Marketing: @JamesHalldon | @taylortresca
* Website & Web3: @andrewjiang | @Frankie_Sutera | @JamesHalldon
* Smart Contracts: @andrewjiang
*
*/

pragma solidity 0.8.0;

import "./AccessControl.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractMintPassportFactory.sol";
import "./console.sol";

/*  
     
                                                        ,sM""""%W,
                                                     ,#"          7m
                                          ,mAWmw,   #              ]p
                                        @"       "W#        ]p      #
                               s##WWmw @                    @       #
                            ,#        %b                            #%m,
                           ]b                                      j    `@,
                           @b                                             @
                            @p    %m              ,'                      ]b
                             "Wp    "=         ,,sMW""^````"5#            #
                              ]##W        ,e#"`             15b        ,#Q,,ssmmw,,
                      ,####ll5#b          #                  ^%#mw,e###bGl#f##Q##WGl##m
                    ;#@S#####p@b          @Q                      @#b GGGG ^'' GGGG@##f#
                    @#########"%m         ###m,                   ]b( ,;,,QJQ G,QQ"#`%W@b
                    #SG##@"\QkpQQ@###MMWW%%"""""7""""""""""""""^```               `"%##""@p
                   #5#Q# ,Q##"`         ,,s,,                      s######wssm   p     %Qp@
                 ##5#S5##W     p 'WW##############            "@@@###########       .p  @m#
                @###b#@#   ,       ]#########@###   .#MW55WM   @@############s          @b
                 %####@b       ,  7@#############        `^"%p  @############       .p .#
                  ] %###           ^############b           ,#  ^@####@#####    s     ;#
                 sM%M `%#Q G7bGGGG,G "@##@####M    "7WWWWWW"       '"%##W7         ,#"
                          "%mp GGG GGGGG  '   GGG  GGG.#7p                    ,,#M"
                              `"WmQQ, GGGGGGGGGGGG "We###" GG         ,,sm#M"`
                                      `"""%%W####mmmmmmm##m#MWW%""""`
                                             ######"^  GG@
                                            @#b^ GGGGGGGG^Q
                                           # "WQ         ,#b
                                         ,"      "%w,  s"  "m
                                     ,s#""#m         @@     #"W,
                                 ,s#"       "@W,      #  ,M      `""=m,,
                              ,#M`              ""@Wm,@#`             @#"m
                             @#p                   @#"                 #  @
                            @N ^p               ,#"    ##@             b   @
                            #    b           sM`       """             b   jb
                           @     ^p        @   ;##p      ,             #    b
                           #  @   ]         @p "WM     ]#l@            @    #
                           `  ``   `        ```          `             ``   `
*/

contract LilFranksMintPassportFactory is AbstractMintPassportFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private mpCounter;

    bytes32 public constant LIL_FRANKS_OPERATOR_ROLE = keccak256("LIL_FRANKS_OPERATOR_ROLE");
  
    mapping(uint256 => MintPass) public mintPasses;
    
    event Claimed(uint index, address indexed account, uint amount);
    event ClaimedMultiple(uint[] index, address indexed account, uint[] amount);
    event Node(bytes32 node);

    struct MintPass {
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
    }
   
    constructor() public ERC1155("ipfs://ipfs/") {
        name_ = "Lil Franks Mint Passport";
        symbol_ = "PASS";
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x760e7B42c920c2a0FeB58DDD610c14A6Bdd2Ebea); //@andrewjiang
        _setupRole(DEFAULT_ADMIN_ROLE, 0xbEC0ddF1ce342BC00aD090c79c351941eE1303C6); //@Frankie_Sutera
        grantRole(LIL_FRANKS_OPERATOR_ROLE, msg.sender);
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
    ) external onlyOwner {
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
    ) external onlyOwner {
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
        uint256 mpIndex,
        bytes32[] calldata merkleProof
    ) external payable {
        require(isValidClaim(numPasses,mpIndex,merkleProof));
        
        //return any excess funds to sender if overpaid
        uint256 excessPayment = msg.value.sub(numPasses.mul(mintPasses[mpIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        
        mintPasses[mpIndex].claimedMPs[msg.sender] = mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses);
        
        _mint(msg.sender, mpIndex, numPasses, "");

        emit Claimed(mpIndex, msg.sender, numPasses);
    }

    function claimMultiple(
        uint256[] calldata numPasses,
        uint256[] calldata mpIndexs,
        bytes32[][] calldata merkleProofs
    ) external payable {
        require(!paused(), "Claim: claiming is paused");
       
        for (uint i=0; i< mpIndexs.length; i++) {
           require(isValidClaim(numPasses[i],mpIndexs[i],merkleProofs[i]), "One or more claims are invalid");
        }

        for (uint i=0; i< mpIndexs.length; i++) {
            mintPasses[mpIndexs[i]].claimedMPs[msg.sender] = mintPasses[mpIndexs[i]].claimedMPs[msg.sender].add(numPasses[i]);
        }

        _mintBatch(msg.sender, mpIndexs, numPasses, "");

        emit ClaimedMultiple(mpIndexs, msg.sender, numPasses);
    }

    function mint(
        address to,
        uint256 numPasses,
        uint256 mpIndex) public
    {
        require(isLilFranksTeamMember(msg.sender), "Caller does not have required role");
        _mint(to, mpIndex, numPasses, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata numPasses,
        uint256[] calldata mpIndexs) public
    {
        require(isLilFranksTeamMember(msg.sender), "Caller does not have required role");
        _mintBatch(to, mpIndexs, numPasses, "");
    }

    function isValidClaim( uint256 numPasses,
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
        // require(mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses) <= amount, "Claim: Not allowed to claim given amount");
        require(mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses) <= mintPasses[mpIndex].maxPerWallet, "Claim: Not allowed to claim that many from one wallet");
        require(numPasses <= mintPasses[mpIndex].maxMintPerTxn, "Max quantity per transaction exceeded");

        console.log('total supply left', totalSupply(mpIndex));
        require(totalSupply(mpIndex) + numPasses <= mintPasses[mpIndex].maxSupply, "Purchase would exceed max supply");
        
        console.log('isValidClaim leaf sender', msg.sender);
        bool isValid = verifyMerkleProof(merkleProof, mpIndex);
        console.log('ISVALIDMERKLEPROOF', isValid);
       require(
            isValid,
            "MerkleDistributor: Invalid proof." 
        );  
       return isValid;
    }

    function isSaleOpen(uint256 mpIndex) public view returns (bool) {
        return mintPasses[mpIndex].saleIsOpen;
    }

    function turnSaleOn(uint256 mpIndex) external{
        require(isLilFranksTeamMember(msg.sender), "Caller does not have required role");
         mintPasses[mpIndex].saleIsOpen = true;
    }

    function turnSaleOff(uint256 mpIndex) external{
        require(isLilFranksTeamMember(msg.sender), "Caller does not have required role");
         mintPasses[mpIndex].saleIsOpen = false;
    }
    
    function promoteTeamMember(address _addr) public{
        console.log('promoteTeamMember', _addr);
         grantRole(LIL_FRANKS_OPERATOR_ROLE, _addr);
    }

    function demoteTeamMember(address _addr) public {
         revokeRole(LIL_FRANKS_OPERATOR_ROLE, _addr);
    }

    function isLilFranksTeamMember(address _addr) internal view returns (bool){
        return hasRole(LIL_FRANKS_OPERATOR_ROLE, _addr) || hasRole(DEFAULT_ADMIN_ROLE, _addr);
    }

    function makeLeaf(address _addr) public view returns (bytes32) {
        bytes32 node = keccak256(abi.encodePacked(_addr));
        return node;
    }

    function verifyMerkleProof(bytes32[] calldata merkleProof, uint256 mpIndex) public view returns (bool) {
        if(mintPasses[mpIndex].merkleRoot == 0x000000000000000000000000000000000000000000007075626c696373616c65){
            return true;
        }
        bytes32 node = makeLeaf(msg.sender);
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

    function getClaimedMps(uint256 poolId, address userAddress) public view returns (uint256) {
        return mintPasses[poolId].claimedMPs[userAddress];
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), mintPasses[_id].ipfsMetadataHash));
    } 
}