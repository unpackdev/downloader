// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./PFP.sol";

contract Sell is AccessControl {
    uint256 public totalSupply;
    uint256 public totalSell;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    PFP public nft;
    address public freeAddr=0x13eA36a7f993229d99936927a86eEA985d71cAfF;
    Activity public ogList=Activity(0x0,1150,0,0.025*10**18,1698814800,1698836400);
    Activity public whiteList=Activity(0x0,2800,0,0.035*10**18,1698836400,1698858000);
    Activity public waitList=Activity(0x0,3950,0,0.045*10**18,1698847200,1698858000);
    Activity public publicList=Activity(0x0,3950,0,0.05*10**18,1698858000,1698908400);
    uint256 public mintLimit;
    uint256 public vipLimit;
    bool public vipIsMint;
    mapping(address=>mapping(uint256=>uint256)) public senderMint; // mintTotal = sender[address][type] Total Mint count for each type of sender ;type 0 =og,1=witlist,2=waitlist,3=public
    event  SetSellNum(address sender,uint256 number);
    event  Mint(address sender,address to,uint256[] tokenIds);
    constructor()  {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x8b8092a331e0d7341B76bd89BAbDEEEA3daD67dA);
        _grantRole(MANAGER_ROLE, 0x79Ff01B87417f97F4dfc5a55f1cA969564CC5DC7);
        totalSell = 3950;
        mintLimit = 2;
        vipLimit = 1000;
    }
    struct Activity{
        bytes32 merkleRoot;
        uint256 total;
        uint256 supply;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

   modifier whenVipMint() {
         require(vipIsMint, "not start");
         _;
      }

    function setNFT(address  nftAddress) public onlyRole(MANAGER_ROLE){
        require(nftAddress !=address(0) && nftAddress != address(nft),"invalid address");
        nft = PFP(nftAddress);
    }

    function setTotalSell(uint256 num) public onlyRole(MANAGER_ROLE){
        totalSell = num;
        emit SetSellNum(_msgSender(),num);
    }
    /**
     * public mint pfp
     * num  mint number
     */ 
    function mint(uint256 num) public payable whenVipMint{
        require(block.timestamp>=publicList.startTime&&block.timestamp<=publicList.endTime,"not start sale or end sale");
        require(totalSupply+num<=totalSell&&totalSell!=0,"mint limit");
        require(senderMint[_msgSender()][3]+num<=mintLimit,"address mint limit");
        require(msg.value>=publicList.price*num,"insufficient amount");
        
        totalSupply = totalSupply+ num;
        publicList.supply = publicList.supply+ num;
        senderMint[_msgSender()][3] +=num;
        payable(freeAddr).transfer(msg.value);
        nft.safeMint(_msgSender(),num);
    }
   
   /**
    * vipMint before mint the vip nft
    * sender is the receive address 
    * num is the mint number
    */
   function vipMint(address sender) public onlyRole(MANAGER_ROLE){
        require(!vipIsMint,"not repeat mint");
        require(ogList.supply+vipLimit<=ogList.total&&totalSupply+vipLimit<=totalSell&&totalSell!=0,"mint limit");
        ogList.supply = ogList.supply+ vipLimit;
        totalSupply = totalSupply+ vipLimit;
        vipIsMint = true;
      //   senderMint[sender] +=num;
        nft.safeMint(sender,vipLimit);
   }
    /**
     * og mint pfp
     * num  mint number
     */ 
    function ogMint(bytes32[] calldata proof,uint256 num) public payable whenVipMint{
        require(block.timestamp>=ogList.startTime&&block.timestamp<=ogList.endTime,"not start sale or end sale");
        require(ogList.merkleRoot!="","merkle tree not set");
        require(num<=mintLimit&& num>0,"mint num invalid");
        require(ogList.supply+num<=ogList.total&&totalSupply+num<=totalSell&&totalSell!=0,"mint limit");
        require(senderMint[_msgSender()][0]+num<=mintLimit,"address mint limit");
        require(verify(_msgSender(),ogList.merkleRoot,proof),"validation sender failed");
        require(msg.value>=ogList.price*num,"insufficient amount");
        
        ogList.supply = ogList.supply+ num;
        totalSupply = totalSupply+ num;
        senderMint[_msgSender()][0] +=num;
        payable(freeAddr).transfer(msg.value);
        nft.safeMint(_msgSender(),num);
    }

    /**
     * whitelist mint pfp
     * num  mint number
     */ 
    function whiteListMint(bytes32[] calldata proof,uint256 num) public payable whenVipMint{
        require(block.timestamp>=whiteList.startTime&&block.timestamp<=whiteList.endTime,"not start sale or end sale");
        require(whiteList.merkleRoot!="","merkle tree not set");
        require(num<=mintLimit&& num>0,"mint num invalid");
        require(whiteList.supply+num<=whiteList.total&&totalSupply+num<=totalSell&&totalSell!=0,"mint limit");
        require(senderMint[_msgSender()][1]+num<=mintLimit,"address mint limit");
        require(verify(_msgSender(),whiteList.merkleRoot,proof),"validation sender failed");
        require(msg.value>=whiteList.price*num,"insufficient amount");
        
        whiteList.supply = whiteList.supply+ num;
        totalSupply = totalSupply+ num;
        senderMint[_msgSender()][1] +=num;
        payable(freeAddr).transfer(msg.value);
        nft.safeMint(_msgSender(),num);
    }

    /**
     * wait mint pfp
     * num  mint number
     */ 
    function waitListMint(bytes32[] calldata proof,uint256 num) public payable whenVipMint{
        require(block.timestamp>=waitList.startTime&&block.timestamp<=waitList.endTime,"not start sale or end sale");
        require(waitList.merkleRoot!="","merkle tree not set");
        require(num<=mintLimit&& num>0,"mint num invalid");
        require(waitList.supply+num<=waitList.total&&totalSupply+num<=totalSell&&totalSell!=0,"mint limit");
        require(senderMint[_msgSender()][2]+num<=mintLimit,"address mint limit");
        require(verify(_msgSender(),waitList.merkleRoot,proof),"validation sender failed");
        require(msg.value>=waitList.price*num,"insufficient amount");
        
        waitList.supply = waitList.supply+ num;
        totalSupply = totalSupply+ num;
        senderMint[_msgSender()][2] +=num;
        payable(freeAddr).transfer(msg.value);
        nft.safeMint(_msgSender(),num);
    }

   
    /**
     * setOgRoot set the ogList merkle tree root bytes
     * treeRoot is the merkle tree root bytes    
     */
     function setOgRoot(bytes32  treeRoot)public onlyRole(MANAGER_ROLE){
        require(treeRoot!=ogList.merkleRoot,"repeat setting");
        ogList.merkleRoot = treeRoot;
     }

    /**
     * setWhiteRoot set the whitelist merkle tree root bytes
     * treeRoot is the merkle tree root bytes    
     */
     function setWhiteRoot(bytes32  treeRoot)public onlyRole(MANAGER_ROLE){
        require(treeRoot!=whiteList.merkleRoot,"repeat setting");
        whiteList.merkleRoot = treeRoot;
     }

     /**
     * setWaitRoot set the waitlist merkle tree root bytes
     * treeRoot is the merkle tree root bytes    
     */
     function setWaitRoot(bytes32  treeRoot)public onlyRole(MANAGER_ROLE){
        require(treeRoot!=waitList.merkleRoot,"repeat setting");
        waitList.merkleRoot = treeRoot;
     }

     /**
     * setPublicPrice set the public sale price
     * amount is the sale price  
     */
     function setPublicPrice(uint256  amount)public onlyRole(MANAGER_ROLE){
        require(amount!=0,"invalid price");
        publicList.price = amount;
     }

     /**
     * setOglistPrice set the oglist sale price
     * amount is the sale price  
     */
     function setOglistPrice(uint256  amount)public onlyRole(MANAGER_ROLE){
       require(amount!=0,"invalid price");
       ogList.price = amount;
     }
    
    /**
     * setWhitelistPrice set the whitelist sale price
     * amount is the sale price  
     */
     function setWhitelistPrice(uint256  amount)public onlyRole(MANAGER_ROLE){
       require(amount!=0,"invalid price");
       whiteList.price = amount;
     }

     /**
     * setWaitPrice set the waitlist sale price
     * amount is the sale price  
     */
     function setWaitPrice(uint256  amount)public onlyRole(MANAGER_ROLE){
        require(amount!=0,"invalid price");
        waitList.price = amount;
     }

     /**
     * setPublicStartTime set the public start time for sale
     * time is the start time for sale  timestamp 
     */
     function setPublicStartTime(uint256  time)public onlyRole(MANAGER_ROLE){
        publicList.startTime = time;
     }

     /**
     * setOgStartTime set the oglist start time for sale
     * time is the start time for sale  timestamp 
     */
     function setOgStartTime(uint256  time)public onlyRole(MANAGER_ROLE){
        ogList.startTime = time;
     }

     /**
     * setWhiteStartTime set the whiteList start time for sale
     * time is the start time for sale  timestamp 
     */
     function setWhiteStartTime(uint256  time)public onlyRole(MANAGER_ROLE){
        whiteList.startTime = time;
     }

     /**
     * setWaitStartTime set the waitList start time for sale
     * time is the start time for sale  timestamp 
     */
     function setWaitStartTime(uint256  time)public onlyRole(MANAGER_ROLE){
        waitList.startTime = time;
     }
    
    /**
     * setPublicEndTime set the publicList end time for sale
     * time is the end time for sale  timestamp 
     */
     function setPublicEndTime(uint256  time)public onlyRole(MANAGER_ROLE){
        publicList.endTime = time;
     }

     /**
     * setOgListEndTime set the ogList end time for sale
     * time is the end time for sale  timestamp 
     */
     function setOgListEndTime(uint256  time)public onlyRole(MANAGER_ROLE){
        ogList.endTime = time;
     }

     /**
     * setWhiteListEndTime set the whiteList end time for sale
     * time is the end time for sale  timestamp 
     */
     function setWhiteListEndTime(uint256  time)public onlyRole(MANAGER_ROLE){
        whiteList.endTime = time;
     }

     /**
     * setWaitListEndTime set the waitList end time for sale
     * time is the end time for sale  timestamp 
     */
     function setWaitListEndTime(uint256  time)public onlyRole(MANAGER_ROLE){
        waitList.endTime = time;
     }

     /**
     * setFreeAddr set the receive eth address 
     * time is the start time for sale  timestamp 
     */
     function setFreeAddr(address  addr)public onlyRole(MANAGER_ROLE){
        require(addr!=address(0),"free  cannot be zero address");
        freeAddr = addr;
     }

     /**
     * setMintLimit set the sender  max mint number 
     * num is max buy number
     */
     function setMintLimit(uint256  num)public onlyRole(MANAGER_ROLE){
        require(num!=mintLimit,"repeat setting");
        mintLimit = num;
     }

     /**
      * verify is check this proofs is invalid
      * sender check address
      * _proofs the left proof
      */
      function verify( address sender,bytes32 root, bytes32[] calldata _proofs) public pure returns(bool){
        bytes32 _node = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(_proofs, root, _node);
    }

     

}