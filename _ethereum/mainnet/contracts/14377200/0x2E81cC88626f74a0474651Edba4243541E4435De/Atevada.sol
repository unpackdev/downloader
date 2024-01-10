// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./AtevadaTokenAccessControl.sol";

//
//                       .#?                       
//                       BBBB                       
//                      GGGGGG ~                    
//            #        GGGGGGG! ~                   
//           BB~ &       PPPPPP! ~                  
//           &GG :GGGGGG    PPPP! ~                 
//           P&PPPPPPPPPPPP   &5555                 
//            P&PPPPP&& PPP  G555555                
//              5&&&&&5~ 555 P &5555!               
//                      555  5 &YYYY!!              
//              Y&YYYYYYYY   P YYYYY~ Y             
//             YYYYYYY       YY &YYY   Y            
//            YYYY   ~         Y YYYY!Y             
//       Y   YYYY Y              Y YYYYYYY ~        
//       YYYYYY  Y                    YYYY! ~       
//       Y&YYYYY ~                       Y!Y        
//         ^  ~                                     
//                      Atevada Team

interface IATVD {
	function balanceOR(address _user) external view returns(uint256);
}

contract AtevadaToken is ERC20, AtevadaTokenAccessControl{
	using SafeMath for uint256;

	uint256 constant public BASE_RATE = 1 ether; 
	uint256 constant public INITIAL_ISSUANCE = 10 ether;
	// Saturday March 13 2032 6:00:00 GMT+0000 
	uint256 constant public END = 1962770400; 

	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;

	IATVD public atevadaContract;
    
	event RewardPaid(address indexed user, uint256 reward);

	constructor(address _atevada ) ERC20('Relics', 'RLX'){
		atevadaContract = IATVD(_atevada);
		_mint(msg.sender, 100 ether);
	}

	// For events
	function devMint(address _to, uint256 amount) requireContractOwner external {
	    _mint(_to, amount);
	}

    function authMint(address _to, uint256 amount) requireIsCallerAuthorized external {
	    _mint(_to, amount);
	}


	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	// called when minting many NFTs
	function updateRewardOnMint(address _user, uint256 _amount) requireIsOperational requireIsCallerAuthorized external {
		// require(msg.sender == address(atevadaContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];
		if (timerUser > 0)
			rewards[_user] = rewards[_user].add(atevadaContract.balanceOR(_user).mul(BASE_RATE.mul((time.sub(timerUser)))).div(86400)
				.add(_amount.mul(INITIAL_ISSUANCE)));
		else 
			rewards[_user] = rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));
		lastUpdate[_user] = time;
	}

	// called on transfers
	function updateReward(address _from, address _to) requireIsOperational requireIsCallerAuthorized external {
			uint256 time = min(block.timestamp, END);
			uint256 timerFrom = lastUpdate[_from];
			if (timerFrom > 0)
				rewards[_from] += atevadaContract.balanceOR(_from).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);
			if (timerFrom != END)
				lastUpdate[_from] = time;
			if (_to != address(0)) {
				uint256 timerTo = lastUpdate[_to];
				if (timerTo > 0)
					rewards[_to] += atevadaContract.balanceOR(_to).mul(BASE_RATE.mul((time.sub(timerTo)))).div(86400);
				if (timerTo != END)
					lastUpdate[_to] = time;
			}
	}

	function getReward(address _to) requireIsOperational requireIsCallerAuthorized external {
		uint256 reward = rewards[_to];
		if (reward > 0) {
			rewards[_to] = 0;
			_mint(_to, reward);
			emit RewardPaid(_to, reward);
		}
	}

	function burn(address _from, uint256 _amount) requireIsOperational requireIsCallerAuthorized external {
		_burn(_from, _amount);
	}

	function getTotalClaimable(address _user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
		uint256 pending = atevadaContract.balanceOR(_user).mul(BASE_RATE.mul((time.sub(lastUpdate[_user])))).div(86400);
		return rewards[_user] + pending;
	}

    function setAtevadaContract(address _atevada) requireContractOwner external {
	    atevadaContract = IATVD(_atevada);
	}
}

contract Atevada is ERC721A, ReentrancyGuard, Ownable {
    
	mapping(address => uint256) public balanceOR;
	AtevadaToken public atevadaToken;

	string public ATEVADA_PROVENANCE = "";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
	

    uint256 public immutable maxPerAddressDuringMint;
    uint256 public constant AMOUNT_FOR_DEVS = 15; // 5 for the team and 10 for events and marketing
    uint256 public constant FREE_MINT_SUPPLY = 56; // For DawnBreakers
    uint256 public constant TOTAL_RESERVED = AMOUNT_FOR_DEVS + FREE_MINT_SUPPLY; 
    uint256 public freeMintCount;

    mapping(address => uint256) public whitelistedClaim;
    mapping(address => bool ) public freeMintClaimed;

    bytes32 public WhiteListRoot = 0x71885696576cd9a50c7835cfff10873ee62b2ab8421795dde31ce0a9efe525b7;
    bytes32 public FreeMintRoot = 0x905372df4a5ca5ee678ab422a5873ca3049f484e040d7b34fa1c2d2af0bdac07;
    bytes32 public DiscountRoot = 0x076bf24fc8f002f11bc0cfe61c07c6c4e3c985b2da8b665214816caeb7d25174;

    bool public isPause = false;
    bool public isPublicSale = false;
    bool public isWhiteListSale = true;
    bool public isDevMint = false; 
	
    constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
    ) ERC721A("AtevadaRelicOfLoka", "ATVDRoL", maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
    }

	modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier requireIsOperational() 
    {
        require(!isPause, "Contract is currently not operational");
        _;  
    }

    modifier requireIsPublicSale() 
    {
        require(isPublicSale, "Public Sale is not operational");
        _;  
    }

    modifier requireIsWhiteListSale() 
    {
        require(isWhiteListSale, "WhiteList Sale is not operational");
        _;  
    }

    function setPauseStatus(bool _status) external onlyOwner {
        isPause = _status;
    }

    function setPublicSale(bool _status) external onlyOwner {
        isPublicSale = _status;
    }

    function setWhiteListSale(bool _status) external onlyOwner {
        isWhiteListSale = _status;
    }

    // MerkleProof Fail-safe
    function setWhiteListRoot(bytes32 _newRoot) external onlyOwner {
		WhiteListRoot = _newRoot;
	}

    function setFreeMintRoot(bytes32 _newRoot) external onlyOwner {
		FreeMintRoot = _newRoot;
	}

    function setDiscountRoot(bytes32 _newRoot) external onlyOwner {
		DiscountRoot = _newRoot;
	}

    function whitelistSaleMint(uint256 _quantity, bytes32[] calldata _merkleProof, bytes32[] calldata _discountMerkleProof) 
    callerIsUser 
    requireIsWhiteListSale
    requireIsOperational 
    external payable {
        require(whitelistedClaim[msg.sender] == 0, "Error: user has minted");
        require(_quantity > 0, "Minimum mint amount is 1");
        require(_quantity == 1 || _quantity == 3 || _quantity == 5, "Can only mint using the provided options");
        require(totalSupply() + _quantity <= collectionSize - TOTAL_RESERVED, "Purchase would reached max supply");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, WhiteListRoot, leaf), "Invalid proof.");

        uint256 price;
        
        if(MerkleProof.verify(_discountMerkleProof, DiscountRoot, leaf)){
            if(_quantity == 1){
                price = 0.027 ether;
            }else if(_quantity == 3){
                price = 0.065 ether;
            }else if(_quantity == 5){
                price = 0.1 ether;
            }
            require(msg.value >= price, "insufficient funds");
            _safeMint(msg.sender, _quantity);
            refundIfOver(price);
        }else {
            if(_quantity == 1){
                price = 0.03 ether;
            }else if(_quantity == 3){
                price = 0.08 ether;
            }else if(_quantity == 5){
                price = 0.12 ether;
            }
            require(msg.value >= price, "insufficient funds");
            _safeMint(msg.sender, _quantity);
            refundIfOver(price);
        }
        whitelistedClaim[msg.sender] = 1;
        balanceOR[msg.sender] = balanceOR[msg.sender] + _quantity;
        atevadaToken.updateRewardOnMint(msg.sender, _quantity);

		// If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == collectionSize)) {
            startingIndexBlock = block.number;
        } 
      }
    
    function publicSaleMint(uint256 _quantity, bytes32[] calldata _discountMerkleProof) 
    callerIsUser 
    requireIsPublicSale 
    requireIsOperational  
    external payable {
        require(_quantity > 0, "Minimum mint amount is 1");
        require(_quantity == 1 || _quantity == 3 || _quantity == 5, "Can only mint using the provided options");
        require(totalSupply() + _quantity <= collectionSize - TOTAL_RESERVED, "Purchase would reached max supply");

        uint256 price;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        
        if(MerkleProof.verify(_discountMerkleProof, DiscountRoot, leaf)){
            if(_quantity == 1){
                price = 0.037 ether;
            }else if(_quantity == 3){
                price = 0.075 ether;
            }else if(_quantity == 5){
                price = 0.11 ether;
            }
            require(msg.value >= price, "insufficient funds");
            _safeMint(msg.sender, _quantity);
            refundIfOver(price);
        }else {
            if(_quantity == 1){
                price = 0.04 ether;
            }else if(_quantity == 3){
                price = 0.09 ether;
            }else if(_quantity == 5){
                price = 0.13 ether;
            }
            require(msg.value >= price, "insufficient funds");
            _safeMint(msg.sender, _quantity);
            refundIfOver(price);
        }

        balanceOR[msg.sender] = balanceOR[msg.sender] + _quantity;
        atevadaToken.updateRewardOnMint(msg.sender, _quantity);

		// If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == collectionSize)) {
            startingIndexBlock = block.number;
        } 

    }

     // For Dawn Breakers
    function freeMint(bytes32[] calldata _merkleProof) 
    callerIsUser 
    requireIsOperational 
    external {
        require(!freeMintClaimed[msg.sender], "Address has already claimed.");
        require(totalSupply() + 1 <= collectionSize, "Purchase would reached max supply");
        require(freeMintCount + 1 <= FREE_MINT_SUPPLY, "Purchase exceed allocated Free mint supply");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, FreeMintRoot, leaf), "Invalid proof.");

        freeMintClaimed[msg.sender] = true;
        freeMintCount++;
        _safeMint(msg.sender, 1);

        balanceOR[msg.sender] = balanceOR[msg.sender] + 1;
        atevadaToken.updateRewardOnMint(msg.sender, 1);

		// If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == collectionSize)) {
            startingIndexBlock = block.number;
        } 
    }

    // For Devs, Events & Marketing
    function devMint() external onlyOwner {
        require(isDevMint == false, "Dev Has already minted!");
        require(totalSupply() + AMOUNT_FOR_DEVS <= collectionSize, "Dev Mint would reached max supply");
        isDevMint = true;
        _safeMint(msg.sender, AMOUNT_FOR_DEVS);

        balanceOR[msg.sender] = balanceOR[msg.sender] + AMOUNT_FOR_DEVS;
        atevadaToken.updateRewardOnMint(msg.sender, AMOUNT_FOR_DEVS);

		// If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == collectionSize)) {
            startingIndexBlock = block.number;
        } 
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
        payable(msg.sender).transfer(msg.value - price);
        }
    }
    
    function setYieldToken(address _atevadaYield) external onlyOwner {
		atevadaToken = AtevadaToken(_atevadaYield);
	}
	
	function getReward() external {
		atevadaToken.updateReward(msg.sender, address(0));
		atevadaToken.getReward(msg.sender);
	}
	
	function transferFrom(address from, address to, uint256 tokenId) public override {
		atevadaToken.updateReward(from, to);
		balanceOR[from]--;
		balanceOR[to]++;
		ERC721A.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		atevadaToken.updateReward(from, to);
		balanceOR[from]--;
		balanceOR[to]++;
		ERC721A.safeTransferFrom(from, to, tokenId, _data);
	}

	 // ProvenanceHash functions and startingIndex
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        ATEVADA_PROVENANCE = provenanceHash;
    }
    
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % collectionSize;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % collectionSize;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex += 1;
        }
    }

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

     //  metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

}

