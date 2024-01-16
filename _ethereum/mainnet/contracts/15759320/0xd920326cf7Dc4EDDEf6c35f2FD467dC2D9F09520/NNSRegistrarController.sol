pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "./Resolver.sol";
import "./OwnableUpgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./StablePriceOracle.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract NNSRegistrarController is Ownable {
    using StringUtils for *;

    struct TimeLimit{
        uint begin;
        uint end;
    }

    struct NftWlInfo{
        bytes32  wlMerkleRoot; 
        address  nftTo;
        address  passNFT;
    }

    struct  Vars{
        bytes32 leaf;
        bytes32 commitment;    
        uint cost;
        bytes32 label;
        uint256 tokenId;
        uint  expires;
        uint nftValue;
        address owner;
        address resolver;
        address addr;
        uint nameLen;
        IERC721 nft;
        bytes32 nodehash;
    }
 	

    uint public MIN_REGISTRATION_DURATION ;//= 28 days;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(string,uint256)") ^
        keccak256("available(string)") ^
        keccak256("makeCommitment(string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(string,address,uint256,bytes32)") ^
        keccak256("renew(string,uint256)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)")
    );
  
	BaseRegistrarImplementation public base;
    PriceOracle public  prices;
    uint256 public  minCommitmentAge; //60 s
    uint256 public  maxCommitmentAge; //24 hour
    uint public wlBegin;
    uint public wlEnd;
    uint public pubBegin;
    mapping(bytes32=>uint) public commitments;

    mapping(address=>mapping(uint=>uint)) public wlRegedNums; // address =>3 or 4chart =>reged
    NftWlInfo public nftWlInfo;

    mapping(string=>bool) public reserves;
    mapping(address=>bool) public reserveAdm;
    address gov;  //ethTo
    bytes32  public wlTwitterMerkleRoot; 
    mapping(uint=>TimeLimit) public roundTime;// round=> TimeLimit

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);

	function __NNSRegistrarController_i(
        BaseRegistrarImplementation _base,
        PriceOracle _prices,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        uint _wlBegin,
        uint _wlEnd,
        uint _pubBegin,
        NftWlInfo calldata _nftWlInfo,
        address _gov
        ) public initializer 
    {
        __NNSRegistrarController_init(_base,_prices,_minCommitmentAge,_maxCommitmentAge,_wlBegin,_wlEnd,_pubBegin,_nftWlInfo,_gov);
    }    

    function __NNSRegistrarController_init(
        BaseRegistrarImplementation _base,
        PriceOracle _prices,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        uint _wlBegin,
        uint _wlEnd,
        uint _pubBegin,
        NftWlInfo calldata _nftWlInfo,
        address _gov
        ) internal onlyInitializing 
    {
        __Ownable_init();
        __NNSRegistrarController_init_unchained(_base,_prices,_minCommitmentAge,_maxCommitmentAge,_wlBegin,_wlEnd,_pubBegin,_nftWlInfo,_gov);
    }

    function __NNSRegistrarController_init_unchained(
        BaseRegistrarImplementation _base,
        PriceOracle _prices,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        uint _wlBegin,
        uint _wlEnd,
        uint _pubBegin,
        NftWlInfo calldata _nftWlInfo,
        address _gov) internal onlyInitializing {
       
        require(_maxCommitmentAge > _minCommitmentAge);
		MIN_REGISTRATION_DURATION =365 days;
        base = _base;
        prices = _prices;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
        wlBegin = _wlBegin;
        wlEnd = _wlEnd;
        pubBegin = _pubBegin;
        nftWlInfo = _nftWlInfo;
        gov = _gov;
    }

	

    function costEth(string memory name, uint duration,uint nftNum) view public returns(uint) {
        uint cost = rentPrice(name, duration);
        uint nftValue = prices.attoUSDToWei(nftNum*1603*1e17);
        if (cost<=nftValue)
            return 0;
        return cost-nftValue;
    }

    function passToEth() view public returns(uint) {
        return prices.attoUSDToWei(1603*1e17);
    }



    function rentPrice(string memory name, uint duration) view public returns(uint) {
        bytes32 hash = keccak256(bytes(name));
        return prices.price(name, base.nameExpires(uint256(hash)), duration);
    }

	function check(string memory name,bool isNum) public pure returns (bool) {
        bytes memory namebytes = bytes(name);
        for (uint256 i; i < namebytes.length; i++) {
            if (!exists(bytes1(namebytes[i]),isNum)) return false;
        }
        return true;
    }
	
	function exists(bytes1 char,bool isNum) public pure returns (bool) {
        bytes memory charsets;
        if (isNum)
            charsets = bytes("0123456789");
        else
            charsets = bytes("abcdefghijklmnopqrstuvwxyz-0123456789");
        for (uint256 i = 0; i < charsets.length; i++) {
            if (bytes1(charsets[i]) == char) {
                return true;
            }
        }
        return false;
    }
	
    function valid(string memory name,bool isNum) public pure  returns(bool) {
        // check unicode rune count, if rune count is >=3, byte length must be >=3. <=63
        if (name.strlen() < 3 || name.strlen()>63) {
            return false;
        }
        /*if (block.timestamp<wlEnd){
            if(name.strlen()>4)
                return false;
            if (!check(name,true))
                return false;
        }else{
            if (!check(name,false))
                return false;
        }*/
        if (!check(name,isNum))
                return false;
        bytes memory nb = bytes(name);
        if (nb[0]==0x2d || nb[nb.length-1]==0x2d)
            return false;
        for (uint256 i; i < nb.length - 2; i++) {
           if( (bytes1(nb[i])==0x2d) && (bytes1(nb[i+1])==0x2d) ){ //--
                return false;
            }
        }    
        return true;
    }

    function setReserves(string [] calldata names,bool[] calldata isReserves) public onlyOwner {
        require(names.length == isReserves.length,"len not match");
        for (uint i=0;i<names.length;i++){
            reserves[names[i]] = isReserves[i];
        }
    }
    function setReserveAdm(address acct,bool isAdm) public onlyOwner {
        reserveAdm[acct] = isAdm;
    }

    function setGov(address _gov) public onlyOwner {
        gov = _gov;
    }

    function setDur(uint _day) public onlyOwner {
        MIN_REGISTRATION_DURATION = 86400*_day ;
    }

    function setTwitterRoot(bytes32 twitterRoot) public onlyOwner {
        wlTwitterMerkleRoot = twitterRoot;
    }

 /*   function setTime(uint _wlBegin,uint _wlEnd,uint _pubBegin) public onlyOwner {
        wlBegin = _wlBegin;
        wlEnd = _wlEnd;
        pubBegin = _pubBegin;
    }*/

    function setTime(uint _round,uint _begin,uint _end) public onlyOwner {
        roundTime[_round] = TimeLimit(_begin,_end);
    }

    function availableWithReserve(string memory name,bool isNum,address acct)public view returns(bool) {
        return (available(name,isNum) && (!isLimit(name,acct)));
    }

    function isLimit(string memory name,address acct) public view returns(bool) {
        if(reserveAdm[acct])
            return false;
        if (reserves[name])
            return true;
        return false;
    }

    function available(string memory name,bool isNum) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name,isNum) && base.available(uint256(label));
    }

    function makeCommitment(string memory name, address owner, bytes32 secret) pure public returns(bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function timeBegin(uint begin,uint end,bool onlyBegin) public view returns (bool){
        if (reserveAdm[msg.sender])
            return true;
        if (onlyBegin)    {
            if (block.timestamp >=begin)
                return true;
        }
        else{
            if ((block.timestamp >=begin)&&(block.timestamp <=end))
                return true;
        }
        return false;
    }



   /* function wlRegister(string calldata name, address owner, uint duration, bytes32 secret,uint wlNum,uint[] calldata tokenIds,bytes32[] calldata _merkleProof) external payable {
        Vars memory vars;
        vars.leaf = keccak256(abi.encodePacked(msg.sender,wlNum));
        require(MerkleProofUpgradeable.verify(_merkleProof, nftWlInfo.wlMerkleRoot, vars.leaf),"Invalid Proof." );
        uint nameLen = name.strlen();
        require(wlRegedNums[msg.sender][nameLen]<wlNum,"reached wlNum");
        wlRegedNums[msg.sender][nameLen]++;
        IERC721 nft = IERC721(nftWlInfo.passNFT);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId_ = tokenIds[i];
            require(msg.sender == nft.ownerOf(tokenId_), "Not owner");
            nft.transferFrom(msg.sender, nftWlInfo.nftTo, tokenId_);
        }
   
        vars.commitment = makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
        vars.cost = _consumeCommitment(name, duration, vars.commitment,tokenIds.length);

        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        vars.expires = base.register(vars.tokenId, owner, duration);

        emit NameRegistered(name, vars.label, owner, vars.cost, vars.expires);

        vars.nftValue = passToEth()*tokenIds.length; 
        if(vars.nftValue >= vars.cost)
           return;

        // Refund any extra payment
        if((msg.value+vars.nftValue) > vars.cost) {
            payable(msg.sender).transfer(msg.value+vars.nftValue - vars.cost);
        }
        payable(gov).transfer( vars.cost-vars.nftValue);
    }*/

    /*function register(string calldata name, address owner, uint duration, bytes32 secret) external payable {
        registerWithConfig(name, owner, duration, secret, address(0), address(0));
    }*/
    //roundTime 1   16-20
    function wlTwitRegisterWithConfig(string calldata name, uint duration, bytes32 secret,uint[] calldata tokenIds,bytes32[] calldata _merkleProof, address[] calldata  ora /*address owner,address resolver, address addr*/) external payable {
        
        require(timeBegin(roundTime[1].begin,roundTime[1].end,false),"time limit");
        require(available(name,false),"name unavailable");
        require(!isLimit(name,msg.sender),"limit"); //reserve

        Vars memory vars;
        vars.leaf = keccak256(abi.encodePacked(msg.sender,name,duration));
        require(MerkleProofUpgradeable.verify(_merkleProof, wlTwitterMerkleRoot, vars.leaf),"Invalid Proof." );
        /*vars.nft = IERC721(nftWlInfo.passNFT);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId_ = tokenIds[i];
            require(msg.sender == vars.nft.ownerOf(tokenId_), "Not owner");
            vars.nft.transferFrom(msg.sender, nftWlInfo.nftTo, tokenId_);
        }*/
        vars.owner = ora[0];
        vars.resolver = ora[1];
        vars.addr = ora[2];
        vars.commitment = makeCommitmentWithConfig(name, vars.owner, secret, vars.resolver, vars.addr);
        vars.cost = _consumeCommitment(name, duration, vars.commitment,tokenIds.length,0);

        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        if(vars.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            vars.expires = base.register(vars.tokenId, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), vars.label));

            // Set the resolver
            base.nns().setResolver(nodehash, vars.resolver);

            // Configure the resolver
            if (vars.addr != address(0)) {
                Resolver(vars.resolver).setAddr(nodehash, vars.addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(vars.tokenId, vars.owner);
            base.transferFrom(address(this), vars.owner, vars.tokenId);
        } else {
            require(vars.addr == address(0));
            vars.expires = base.register(vars.tokenId, vars.owner, duration);
        }


        emit NameRegistered(name, vars.label, vars.owner, 0/*vars.cost*/, vars.expires);

/*        vars.nftValue = passToEth()*tokenIds.length; 
        if(vars.nftValue >= vars.cost)
           return;

        // Refund any extra payment
        if((msg.value+vars.nftValue) > vars.cost) {
            payable(msg.sender).transfer(msg.value+vars.nftValue - vars.cost);
        }
        //payable(gov).transfer( vars.cost-vars.nftValue);
        (bool success,) = payable(gov).call{value:(vars.cost-vars.nftValue)}("");
        require(success,"send eth faild");*/

    }

    //roundTime 2  13-16
    function wlRegisterWithConfig(string calldata name, uint duration, bytes32 secret,uint wlNum,uint[] calldata tokenIds,bytes32[] calldata _merkleProof, address[] calldata  ora ) external payable { // ora:address owner,address resolver, address addr
        require(timeBegin(roundTime[2].begin,roundTime[2].end,false),"time limit");
        //require(timeBegin(wlBegin,wlEnd,true),"time limit");
        require(available(name,true),"name unavailable");
        require(!isLimit(name,msg.sender),"limit"); //reserve
        uint nameLen = name.strlen();
        require(nameLen==3||nameLen==4,"name len 3-4");

        Vars memory vars;
        vars.leaf = keccak256(abi.encodePacked(msg.sender,wlNum));
        require(MerkleProofUpgradeable.verify(_merkleProof, nftWlInfo.wlMerkleRoot, vars.leaf),"Invalid Proof." );
        //uint nameLen = name.strlen();
        require(wlRegedNums[msg.sender][nameLen]<wlNum,"reached wlNum");
        wlRegedNums[msg.sender][nameLen]++;
        vars.nft = IERC721(nftWlInfo.passNFT);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId_ = tokenIds[i];
            require(msg.sender == vars.nft.ownerOf(tokenId_), "Not owner");
            vars.nft.transferFrom(msg.sender, nftWlInfo.nftTo, tokenId_);
        }
        vars.owner = ora[0];
        vars.resolver = ora[1];
        vars.addr = ora[2];
        vars.commitment = makeCommitmentWithConfig(name, vars.owner, secret, vars.resolver, vars.addr);
        vars.cost = _consumeCommitment(name, duration, vars.commitment,tokenIds.length,1e18);

        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        if(vars.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            vars.expires = base.register(vars.tokenId, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), vars.label));

            // Set the resolver
            base.nns().setResolver(nodehash, vars.resolver);

            // Configure the resolver
            if (vars.addr != address(0)) {
                Resolver(vars.resolver).setAddr(nodehash, vars.addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(vars.tokenId, vars.owner);
            base.transferFrom(address(this), vars.owner, vars.tokenId);
        } else {
            require(vars.addr == address(0));
            vars.expires = base.register(vars.tokenId, vars.owner, duration);
        }


        emit NameRegistered(name, vars.label, vars.owner, vars.cost, vars.expires);

        vars.nftValue = passToEth()*tokenIds.length; 
        if(vars.nftValue >= vars.cost)
           return;

        // Refund any extra payment
        if((msg.value+vars.nftValue) > vars.cost) {
            payable(msg.sender).transfer(msg.value+vars.nftValue - vars.cost);
        }
        //payable(gov).transfer( vars.cost-vars.nftValue);
        (bool success,) = payable(gov).call{value:(vars.cost-vars.nftValue)}("");
        require(success,"send eth faild");

    }

   
    //roundTime 3  2022.10.16-2099.10.16
    function registerWithConfig_34Num(string calldata name, uint duration, bytes32 secret, uint[] calldata tokenIds,address[] calldata  ora /*address owner,address resolver, address addr*/) external payable {
        //require(timeBegin(pubBegin,0,true),"time limit");
        require(timeBegin(roundTime[3].begin,roundTime[3].end,false),"time limit");
        require(available(name,true),"name unavailable");
        require(!isLimit(name,msg.sender),"limit"); //reserve
        uint nameLen = name.strlen();
        require(nameLen==3||nameLen==4,"name len 3-4");

        Vars memory vars;
        vars.nft = IERC721(nftWlInfo.passNFT);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId_ = tokenIds[i];
            require(msg.sender == vars.nft.ownerOf(tokenId_), "Not owner");
            vars.nft.transferFrom(msg.sender, nftWlInfo.nftTo, tokenId_);
        }
        vars.owner = ora[0];
        vars.resolver = ora[1];
        vars.addr = ora[2];
        vars.commitment = makeCommitmentWithConfig(name, vars.owner, secret, vars.resolver, vars.addr);
        vars.cost = _consumeCommitment(name, duration, vars.commitment,tokenIds.length,1e18);
        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        if(vars.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            vars.expires = base.register(vars.tokenId, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), vars.label));

            // Set the resolver
            base.nns().setResolver(nodehash, vars.resolver);

            // Configure the resolver
            if (vars.addr != address(0)) {
                Resolver(vars.resolver).setAddr(nodehash, vars.addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(vars.tokenId, vars.owner);
            base.transferFrom(address(this), vars.owner, vars.tokenId);
        } else {
            require(vars.addr == address(0));
            vars.expires = base.register(vars.tokenId, vars.owner, duration);
        }


        emit NameRegistered(name, vars.label, vars.owner, vars.cost, vars.expires);

        vars.nftValue = passToEth()*tokenIds.length; 
        if(vars.nftValue >= vars.cost)
           return;

        // Refund any extra payment
        if((msg.value+vars.nftValue) > vars.cost) {
            payable(msg.sender).transfer(msg.value+vars.nftValue - vars.cost);
        }
        //payable(gov).transfer( vars.cost-vars.nftValue);
        (bool success,) = payable(gov).call{value:(vars.cost-vars.nftValue)}("");
        require(success,"send eth faild");

    }


    function renew(string calldata name, uint duration) external payable {
        uint cost = rentPrice(name, duration);
        require(msg.value >= cost);

        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(uint256(label), duration);

        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(name, label, cost, expires);
        //payable(gov).transfer(cost);
        (bool success,) = payable(gov).call{value:cost}("");
        require(success,"send eth faild");
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setBase(BaseRegistrarImplementation _base) public onlyOwner {
        base = _base;
    }


    function setConf(uint _minCommitmentAge, uint _maxCommitmentAge,uint _wlBegin,uint _wlEnd,uint _pubBegin,NftWlInfo calldata _nftWlInfo) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
        wlBegin = _wlBegin;
        wlEnd = _wlEnd;
        pubBegin = _pubBegin;
        nftWlInfo =_nftWlInfo;
    }
    

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);        
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == COMMITMENT_CONTROLLER_ID ||
               interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(string memory name, uint duration, bytes32 commitment,uint nftNum,uint rate) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);

        delete(commitments[commitment]);

        uint cost = costEth(name,duration,nftNum)*rate/1e18;
        //uint cost = rentPrice(name, duration);
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);

        return cost;
    }
}
