// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./EvolveToken.sol";
import "./IERC1155.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";


contract RexV2 is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    
	using SafeMathUpgradeable for uint256;
	using SafeMathUpgradeable for uint128;
	using SafeMathUpgradeable for uint16;

    uint16 public MAX_TOKENS_MINTABLE;
    uint16 public MAX_BABY_TOKENS;
    uint16 public MAX_UNCOMMON_TOKENS;
    uint16 public MAX_RARE_TOKENS;
    uint16 public MAX_LEGENDARY_TOKENS;
    uint16 public MAX_MYTHICAL_TOKENS;
    uint16 public NUM_BABY_TOKENS;
    uint16 public NUM_UNCOMMON_TOKENS;
    uint16 public NUM_RARE_TOKENS;
    uint16 public NUM_LEGENDARY_TOKENS;
    uint16 public NUM_MYTHICAL_TOKENS;
    uint16 public REX_FOR_UNCOMMON;
    uint16 public REX_FOR_RARE;
    uint16 public REX_FOR_LEGENDARY;
    uint16 public REX_FOR_MYTHICAL;

    bool public EVOLVE_OPEN;
    bool public ON_SALE;    
    bool public ON_PRESALE;

    uint128 public TOKEN_PRICE;

    string private BASE_URI;

    IERC1155 public OPENSEA_STORE;
    EvolveToken public EVOLVE_TOKEN;

    mapping(address => uint256) public balanceGenesis;
    mapping(address => uint256) public balanceUncommon;
    mapping(address => uint256) public balanceRare;
    mapping(address => uint256) public balanceLegendary;
    mapping(address => uint256) public balanceMythical;
    mapping(uint256 => bool) public availableMythicals;
    mapping(uint256 => bool) public mintedMythicals;
    
    address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);

    mapping(address => bool) public presaleWhitelist;            
    mapping(address => uint256) public addressTokensMinted;   
    
    function mintRex(uint16 numberOfTokens, address userAddress, uint16 tier) internal {
        uint16 nextToken;
        if(tier == 1){
            nextToken = 101 + NUM_BABY_TOKENS;
            NUM_BABY_TOKENS += numberOfTokens;
        }else if(tier == 2){
            nextToken = 10000 + NUM_UNCOMMON_TOKENS;
            NUM_UNCOMMON_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceUncommon[userAddress] += numberOfTokens;
        }else if(tier == 3){
            nextToken = 20000 + NUM_RARE_TOKENS;
            NUM_RARE_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceRare[userAddress] += numberOfTokens;
        }else if(tier == 4){
            nextToken = 30000 + NUM_LEGENDARY_TOKENS;
            NUM_LEGENDARY_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceLegendary[userAddress] += numberOfTokens;
        }else if(tier == 5){
            nextToken = 40000 + NUM_MYTHICAL_TOKENS;
            NUM_MYTHICAL_TOKENS += numberOfTokens;
		    EVOLVE_TOKEN.updateClaimable(userAddress, address(0));
            balanceMythical[userAddress] += numberOfTokens;
        }
        for(uint256 i = 0; i < numberOfTokens; i+=1) {
            _safeMint(userAddress, nextToken+i);
        }
        delete nextToken;
    }

    function mint(uint16 numberOfTokens) external payable  {
        require(ON_SALE, "not on sale");
        require(NUM_BABY_TOKENS + numberOfTokens <= MAX_BABY_TOKENS, "Not enough");
        require(addressTokensMinted[msg.sender] + numberOfTokens <= MAX_TOKENS_MINTABLE, "mint limit");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');
        mintRex(numberOfTokens,msg.sender,1);
        addressTokensMinted[msg.sender] += numberOfTokens;
    }

    function mintPresale(uint16 numberOfTokens) external payable  {
        require(ON_PRESALE, "not presale");
        require(presaleWhitelist[msg.sender], "Not whitelist");
        require(NUM_BABY_TOKENS * numberOfTokens <= MAX_BABY_TOKENS, "Not enough left");
        require(addressTokensMinted[msg.sender] + numberOfTokens <= MAX_TOKENS_MINTABLE, "mint limit");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');
        mintRex(numberOfTokens,msg.sender,1);
        addressTokensMinted[msg.sender] += numberOfTokens;
    }
    
	function convertGenesis(uint256 _tokenId) external {
        require(isValidRex(_tokenId),"not valid rex");
		uint256 id = returnCorrectId(_tokenId);
		OPENSEA_STORE.safeTransferFrom(msg.sender, burnAddress, _tokenId, 1, "");
		EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
		_safeMint(msg.sender, id);
		balanceGenesis[msg.sender]++;
	} 

    function evolve(uint256[] calldata _rexs, uint256 _mythicalToken) external {
        require(EVOLVE_OPEN, "evolve not open");
        uint256 rexEaten = _rexs.length;

        for(uint256 i = 0; i < rexEaten; i+=1) {
            require(ownerOf(_rexs[i]) == msg.sender, "not own rex");
            require(isEdible(_rexs[i]), "cannot eat this");
        }

        if(rexEaten == REX_FOR_UNCOMMON){
            require(NUM_UNCOMMON_TOKENS < MAX_UNCOMMON_TOKENS, "No UNCOMMON left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,2);
        }
        else if(rexEaten == REX_FOR_RARE){
            require(NUM_RARE_TOKENS < MAX_RARE_TOKENS, "No RARE left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,3);
        }
        else if(rexEaten == REX_FOR_LEGENDARY){
            require(NUM_LEGENDARY_TOKENS < MAX_LEGENDARY_TOKENS, "No LEGENDARY left");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            mintRex(1,msg.sender,4);
        }
        else if(rexEaten == REX_FOR_MYTHICAL){
            require(NUM_MYTHICAL_TOKENS < MAX_MYTHICAL_TOKENS, "No MYTHICAL left");
            require(_mythicalToken >= 40000, "Not a MYTHICAL");
            require(availableMythicals[_mythicalToken], "Mythical not available");
            for(uint256 i = 0; i < rexEaten; i+=1) {
                burnRex(_rexs[i]);
            }
            NUM_MYTHICAL_TOKENS += 1;
            EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
            _safeMint(msg.sender, _mythicalToken);
            balanceMythical[msg.sender] += 1;
            availableMythicals[_mythicalToken] = false;
        }
        
        delete rexEaten;
    }

    function isEdible(uint256 _tokenId) internal view returns(bool){
        if(_tokenId <= 100){ //101 Genesis Rex
            return false;
        }else if(mintedMythicals[_tokenId]){ //Minted Mythical
            return false;
        }else if(_tokenId >= 5000 && _tokenId <= 5010){ //Mythical Babies
            return false;
        }else if(_tokenId >= 40000){ //Mythical Rex
            return false;
        }
        return true;
    }

    function claimTokens() external {
		EVOLVE_TOKEN.updateClaimable(msg.sender, address(0));
		EVOLVE_TOKEN.claimTokens(msg.sender);
	}
    
    function burnRex(uint256 _tokenId) internal {
        _burn(_tokenId);
        decreaseBalance(_tokenId, msg.sender);
    }


    function increaseBalance(uint256 _tokenId, address _owner) internal {
        if(_tokenId <= 100){ //Genesis
            balanceGenesis[_owner]++;
        }else if(_tokenId < 5000 && !mintedMythicals[_tokenId]){ //babies
            //do not earn
        }else if(_tokenId < 10000 || mintedMythicals[_tokenId]){ //mythical babies
            balanceMythical[_owner]++;
        }else if(_tokenId < 20000){ //uncommon
            balanceUncommon[_owner]++;
        }else if(_tokenId < 30000){ //rare
            balanceRare[_owner]++;
        }else if(_tokenId < 40000){ //legendary
            balanceLegendary[_owner]++;
        }else if(_tokenId < 50000){ //mythical
            balanceMythical[_owner]++;
        }
    }

    function decreaseBalance(uint256 _tokenId, address _owner) internal {
        if(_tokenId <= 100){ //Genesis
            balanceGenesis[_owner]--;
        }else if(_tokenId < 5000 && !mintedMythicals[_tokenId]){ //babies
            //do not earn
        }else if(_tokenId < 10000 || mintedMythicals[_tokenId]){ //mythical babies
            balanceMythical[_owner]--;
        }else if(_tokenId < 20000){ //uncommon
            balanceUncommon[_owner]--;
        }else if(_tokenId < 30000){ //rare
            balanceRare[_owner]--;
        }else if(_tokenId < 40000){ //legendary
            balanceLegendary[_owner]--;
        }else if(_tokenId < 50000){ //mythical
            balanceMythical[_owner]--;
        }
    }

    
    function airdrop(uint16 numberOfTokens, address userAddress, uint16 tier) external onlyOwner {
        if(tier > 1){
            require(numberOfTokens == 1,"multiple airdrop not allowed");
        }
        mintRex(numberOfTokens,userAddress,tier);
    }

    function addToWhitelist(address[] calldata whitelist) external onlyOwner {
        for(uint256 i = 0; i < whitelist.length; i+=1) {
            presaleWhitelist[whitelist[i]] = true;
        }
    }

    function startPreSale() external onlyOwner {
        ON_PRESALE = true;
    }
    function stopPreSale() external onlyOwner {
        ON_PRESALE = false;
    }
    function startSale() external onlyOwner {
        ON_SALE = true;
    }
    function stopSale() external onlyOwner {
        ON_SALE = false;
    }
    function openEvolve() external onlyOwner {
        EVOLVE_OPEN = true;
    }
    function closeEvolve() external onlyOwner {
        EVOLVE_OPEN = false;
    }

    function setTokenPrice(uint128 price) external onlyOwner {
        TOKEN_PRICE = price;
    }
    function setMaxMintable(uint16 quantity) external onlyOwner {
        MAX_TOKENS_MINTABLE = quantity;
    }

    function setRexForUncommon(uint16 quantity) external onlyOwner {
        REX_FOR_UNCOMMON = quantity;
    }
    function setRexForRare(uint16 quantity) external onlyOwner {
        REX_FOR_RARE = quantity;
    }
    function setRexForLegendary(uint16 quantity) external onlyOwner {
        REX_FOR_LEGENDARY = quantity;
    }
    function setRexForMythical(uint16 quantity) external onlyOwner {
        REX_FOR_MYTHICAL = quantity;
    }

    function setMaxBabyTokens(uint16 quantity) external onlyOwner {
        MAX_BABY_TOKENS = quantity;
    }
    function setMaxUncommonTokens(uint16 quantity) external onlyOwner {
        MAX_UNCOMMON_TOKENS = quantity;
    }
    function setMaxRareTokens(uint16 quantity) external onlyOwner {
        MAX_RARE_TOKENS = quantity;
    }
    function setMaxLegendaryTokens(uint16 quantity) external onlyOwner {
        MAX_LEGENDARY_TOKENS = quantity;
    }
    function setMaxMythicalTokens(uint16 quantity) external onlyOwner {
        MAX_MYTHICAL_TOKENS = quantity;
    }
    
    function setOS(address _address) external onlyOwner{
        OPENSEA_STORE = IERC1155(_address);
    }
    
    function setEvolveToken(address _address) external onlyOwner {
        EVOLVE_TOKEN = EvolveToken(_address);
    }

    function setMintedMythical(uint16 _tokenId) external onlyOwner {
        mintedMythicals[_tokenId] = true;
        address mmowner = ownerOf(_tokenId);
        increaseBalance(_tokenId, mmowner);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x212F952aDfEA0d424cB0B2A314DC1Cb960FE37B6).call{value: balance}("");
        delete balance;
    }

    function createBabyMythicals() external onlyOwner {
        _safeMint(msg.sender, 5000);
        _safeMint(msg.sender, 5001);
        _safeMint(msg.sender, 5002);
        _safeMint(msg.sender, 5003);
        _safeMint(msg.sender, 5004);
        _safeMint(msg.sender, 5005);
        _safeMint(msg.sender, 5006);
        balanceMythical[msg.sender]+=7;
    }

    function isValidRex(uint256 _id) pure internal returns(bool) {

		if (_id >> 96 != 0x0000000000000000000000008d7aeb636db83bd1b1c58eff56a40321584ea18c)
			return false;

		if (_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;

		uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		if (id-124 > 100)
			return false;
		return true;
	}

	function returnCorrectId(uint256 _id) pure internal returns(uint256) {
		_id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		return _id-124;
	}    
    
	function transferFrom(address from, address to, uint256 tokenId) public override {
        EVOLVE_TOKEN.updateClaimable(from, to);
        increaseBalance(tokenId, to);
        decreaseBalance(tokenId, from);
		ERC721Upgradeable.transferFrom(from, to, tokenId);
	}
    
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        EVOLVE_TOKEN.updateClaimable(from, to);
        increaseBalance(tokenId, to);
        decreaseBalance(tokenId, from);
		ERC721Upgradeable.safeTransferFrom(from, to, tokenId, _data);
	}

    function initialize(string memory name_, string memory symbol_) public initializer {
        __Ownable_init_unchained();        
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);

        TOKEN_PRICE = 65000000000000000;
        MAX_TOKENS_MINTABLE = 3;        
        MAX_BABY_TOKENS = 3898;
        MAX_UNCOMMON_TOKENS = 1300;
        MAX_RARE_TOKENS = 500;
        MAX_LEGENDARY_TOKENS = 126;
        MAX_MYTHICAL_TOKENS = 12;
        availableMythicals[40000] = true;
        availableMythicals[40001] = true;
        availableMythicals[40002] = true;
        availableMythicals[40003] = true;
        availableMythicals[40004] = true;
        availableMythicals[40005] = true;
        availableMythicals[40006] = true;
        availableMythicals[40007] = true;
        availableMythicals[40008] = true;
        availableMythicals[40009] = true;
        availableMythicals[40010] = true;
        availableMythicals[40011] = true;
        REX_FOR_UNCOMMON = 2;
        REX_FOR_RARE = 5;
        REX_FOR_LEGENDARY = 10;
        REX_FOR_MYTHICAL = 25;
        BASE_URI = "http://phpstack-636608-2278840.cloudwaysapps.com/rex/api/?token_id=";
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            delete index;
            return result;
        }
    }
    
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external view returns(bytes4) {
		require(msg.sender == address(OPENSEA_STORE), "not opensea asset");
		return Rex.onERC1155Received.selector;
	}

}