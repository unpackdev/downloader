//   __  __                         _____ _          _     _                       
//  |  \/  |                       / ____| |        (_)   | |                      
//  | \  / | ___ _ __ _ __ _   _  | |    | |__  _ __ _ ___| |_ _ __ ___   __ _ ___ 
//  | |\/| |/ _ \ '__| '__| | | | | |    | '_ \| '__| / __| __| '_ ` _ \ / _` / __|
//  | |  | |  __/ |  | |  | |_| | | |____| | | | |  | \__ \ |_| | | | | | (_| \__ \
//  |_|  |_|\___|_|  |_|   \__, |  \_____|_| |_|_|  |_|___/\__|_| |_| |_|\__,_|___/
//   ______                 __/ |____                 _____      _                 
//  |  ____|               |___/  __ \               / ____|    (_)                
//  | |__ _ __ ___  _ __ ___   | |__) |__ _ __   ___| |     ___  _ _ __            
//  |  __| '__/ _ \| '_ ` _ \  |  ___/ _ \ '_ \ / _ \ |    / _ \| | '_ \           
//  | |  | | | (_) | | | | | | | |  |  __/ |_) |  __/ |___| (_) | | | | |          
//  |_|  |_|  \___/|_| |_| |_| |_|   \___| .__/ \___|\_____\___/|_|_| |_|          
//                                       | |                                       
//                                       |_|                                       

// A lump of pepe coal with red lips. Congrats.

// SPDX-License-Identifier: Frensware

pragma solidity ^0.8.20;

 import "./ERC1155.sol";
  import "./Ownable.sol";
   import "./Pausable.sol";
    import "./MerkleProof.sol";
     import "./Strings.sol";

contract MerryKekmas2023 is ERC1155, Ownable, Pausable {
    
    string private contractMetadataURI;
    string private _name;
     string private _symbol;
      string private baseURI;
       uint256 public constant tokenID = 2;
        uint256 public constant TOTAL_SUPPLY = 2000;
         uint256 public constant INITIAL_DEV_AMOUNT = 69;
          bytes32 public merkleRoot;

    mapping(uint256 => string) private tokenURIs;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalSupply;
    mapping(address => bool) private _hasClaimed;

    event CoalClaimed(address indexed account, uint256 indexed id, uint256 amount);
    event CoalBurned(address indexed account, uint256 indexed id, uint256 amount);


    constructor(string memory name_, string memory symbol_, address initialOwner)
        ERC1155()
        Ownable()
    {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, tokenID, INITIAL_DEV_AMOUNT, "");
        totalSupply[tokenID] += INITIAL_DEV_AMOUNT;
            transferOwnership(initialOwner); 
    }


    function claim(bytes32[] calldata merkleProof)
         external {
        require(!_hasClaimed[msg.sender], "NFT already claimed by this address");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");

        _hasClaimed[msg.sender] = true;
        _mint(msg.sender, tokenID, 1, "");
    }


    function setBaseURI(string memory newBaseURI)
        public onlyOwner {
    baseURI = newBaseURI;
    }


   function uri(uint256 id)
    public view virtual override returns (string memory) {
    require(id == tokenID, "Token ID does not exist");
    return string(abi.encodePacked(baseURI, Strings.toString(id), ".json"));
}

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        contractMetadataURI = newContractURI;
    }

    function isEligibleForClaim(address user, bytes32[] calldata merkleProof)
         external view returns (bool) {
        if (_hasClaimed[user]) {
            return false; //has already claimed
        }

        //compute leaf node and verify the proof
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }


    function setApprovalForAll(address operator, bool approved)
       public virtual override {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
    }
 

    function supportsInterface(bytes4 interfaceId)
         override public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }


    function burn(address account, uint256 id, uint256 amount)
          public {
        require(account == msg.sender || isApprovedForAll[account][msg.sender], "Caller is not owner nor approved");
        require(balanceOf[account][id] >= amount, "Burn amount exceeds balance");

        balanceOf[account][id] -= amount;
        totalSupply[id] -= amount;

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }
   
    function setMerkleRoot(bytes32 _merkleRoot)
         external onlyOwner {
    merkleRoot = _merkleRoot;
    }

    function circuitBreaker()
        public onlyOwner {
        _pause();
    }

    function name()
        public view returns (string memory) {
        return _name;
    }

    function symbol()
        public view returns (string memory) {
        return _symbol;
    }

}