 
//                                ,----,                ,----,                               
//                    ,--.      ,/   .`|              ,/   .`|                               
//     ,---,.       ,--.'|    ,`   .'  :   ,---,    ,`   .'  :   ,---,    ,---,.  .--.--.    
//   ,'  .' |   ,--,:  : |  ;    ;     /,`--.' |  ;    ;     /,`--.' |  ,'  .' | /  /    '.  
// ,---.'   |,`--.'`|  ' :.'___,/    ,' |   :  :.'___,/    ,' |   :  :,---.'   ||  :  /`. /  
// |   |   .'|   :  :  | ||    :     |  :   |  '|    :     |  :   |  '|   |   .';  |  |--`   
// :   :  |-,:   |   \ | :;    |.';  ;  |   :  |;    |.';  ;  |   :  |:   :  |-,|  :  ;_     
// :   |  ;/||   : '  '; |`----'  |  |  '   '  ;`----'  |  |  '   '  ;:   |  ;/| \  \    `.  
// |   :   .''   ' ;.    ;    '   :  ;  |   |  |    '   :  ;  |   |  ||   :   .'  `----.   \ 
// |   |  |-,|   | | \   |    |   |  '  '   :  ;    |   |  '  '   :  ;|   |  |-,  __ \  \  | 
// '   :  ;/|'   : |  ; .'    '   :  |  |   |  '    '   :  |  |   |  ''   :  ;/| /  /`--'  / 
// |   |    \|   | '`--'      ;   |.'   '   :  |    ;   |.'   '   :  ||   |    \'--'.     /  
// |   :   .''   : |          '---'     ;   |.'     '---'     ;   |.' |   :   .'  `--'---'   
// |   | ,'  ;   |.'                    '---'                 '---'   |   | ,'               
// `----'    '---'                                                    `----'                 
// MetaGeckos Activate
// Artwork by Trent Kaniuga
// Built on entities.wtf
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./Library.sol";


contract ENTITIES_1 is ERC721, ReentrancyGuard {
    using Library for uint8;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;


    struct Claims {
        uint256 tokenId;
        bool claimed;
    }

    // Sale states
    bool public mintActive;
    bool public mintMintPassActive;
    bool public mintIncludeReserveActive;
    bool public mintWhiteListActive;
    bool public salePaused = true;
    

    //API for Generation
    string private baseTokenURI;

    //strings
    string public PROVENANCE = "";

    // -- Opensea royalty URI
    string private baseContractURI;


    //Mappings
    mapping(uint256 => bool) private _tokenClaimed;
    mapping(uint256 => Claims) public mintpassclaimlist;
    mapping(address => uint256) public whitelistMintsPerWal;


    //uint256s
    uint256 public MAX_MINTPASS_SUPPLY;
    uint256 public MAX_PUBLIC_SUPPLY;
    uint256 public MAX_TEAM_MINT;
    uint256 public MAX_MINT;
    uint256 public totalMintPassSupply;
    uint256 public totalPublicSupply;
    uint256 public totalTeamMinted;
    uint256 public price;

    //whitelist
    bytes32 public ogMerkleRoot;

    //addresses
    address public owner;
    address private t1;
    address private t2;
    address private t3;


    //interfaces
    MintPassContract public mintPassContract;

    constructor(
        string memory COLLECTION_NAME,
        string memory COLLECTION_SYMBOL,
        uint256 _MAX_MINTPASS_SUPPLY,
        uint256 _MAX_PUBLIC_SUPPLY,
        uint256 _MAX_TEAM_MINT,
        uint256 _MAX_MINT,
        uint256 _price,
        address _mintPassToken,
        bytes32 _ogMerkleRoot,
        string memory _baseContractURI,
        string memory _baseTokenURI

 
    ) ERC721(COLLECTION_NAME, COLLECTION_SYMBOL) {
        owner = msg.sender;
        t1 = msg.sender;
        MAX_MINTPASS_SUPPLY = _MAX_MINTPASS_SUPPLY;
        MAX_PUBLIC_SUPPLY = _MAX_PUBLIC_SUPPLY;
        MAX_TEAM_MINT = _MAX_TEAM_MINT;
        MAX_MINT = _MAX_MINT;
        price = _price;
        mintPassContract = MintPassContract(_mintPassToken);
        ogMerkleRoot = _ogMerkleRoot;
        baseContractURI = _baseContractURI;
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev Internal mint to keep things neat.
     */
    function mintInternal() internal nonReentrant {
        uint256 mintIndex = _tokenSupply.current() + 1;
        _tokenSupply.increment();
        _mint(msg.sender, mintIndex);
    }

    /**
     * @dev Mints new tokens
     */
    function teamMint(uint256 amount) public onlyOwner {
        require(
            totalTeamMinted + amount < MAX_TEAM_MINT + 1,
            "Max dev tokens minted"
        );
        for (uint256 i = 0; i < amount; i++) {
            if (totalTeamMinted < MAX_TEAM_MINT) {
                totalTeamMinted += 1;
                mintInternal();
            }
        }
    }

    /**
     * @dev Public mint
     */
    function mint(uint256 amount) public payable {
        require(mintActive, "Sale has not started yet.");
        require(amount < MAX_MINT + 1, "Can't claim this many tokens at once.");
        require(
            totalPublicSupply + amount < MAX_PUBLIC_SUPPLY + 1,
            "Over max public limit"
        );
        require(msg.value >= price * amount, "ETH sent is not correct");

        for (uint256 i = 0; i < amount; i++) {
            if (totalPublicSupply < MAX_PUBLIC_SUPPLY) {
                totalPublicSupply += 1;
                mintInternal();
            }
        }
    }

    /**
     * @dev MintPass mint
     */
    function mintpassMint(uint256[] memory tokenIds) public {
        require(mintMintPassActive, "Sale has not started yet.");
        require(
            tokenIds.length < MAX_MINT + 1,
            "Can't claim this many tokens at once."
        );
        require(msg.sender == tx.origin, "Cannot use a contract for this");
        require(
            totalMintPassSupply + (tokenIds.length) < MAX_MINTPASS_SUPPLY + 1,
            "Exceeds private supply"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                mintPassContract.ownerOf(tokenIds[i]) == msg.sender,
                "You do not own this token."
            );
            require(
                !isMintPassClaimed(tokenIds[i]),
                "MintPass has already been claimed for this token."
            );
            mintpassclaimlist[tokenIds[i]].tokenId = tokenIds[i];
            mintpassclaimlist[tokenIds[i]].claimed = true;
            totalMintPassSupply += 1;
            mintInternal();
        }
    }

    /**
     * @dev Whitelist mint - API controlled
     */
    function mintWhiteList(uint256 amount, bytes32[] calldata merkleProof)
        public
        payable
    {
        require(mintWhiteListActive, "Sale has not started yet.");
        require(msg.sender == tx.origin, "Cannot use a contract to mint");
        require(
            amount < MAX_MINT + 1,
            "Can't claim this many tokens at once."
        );

        require(
            totalPublicSupply + amount < MAX_PUBLIC_SUPPLY + 1,
            "Over max public limit"
        );
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
		    bool isOGVerified = MerkleProof.verify(merkleProof, ogMerkleRoot, node);
			require(isOGVerified, "You are not whitelisted, please wait for public mint");
			require(
				whitelistMintsPerWal[msg.sender] + amount < MAX_MINT + 1,
				"Already claimed, please wait for public mint"
			);
        require(msg.value >= price * amount, "ETH sent is not correct");

        for (uint256 i; i < 1; i++) {
            if (totalPublicSupply < MAX_PUBLIC_SUPPLY) {
                totalPublicSupply += 1;
                whitelistMintsPerWal[msg.sender] += 1;
                mintInternal();            
            }
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }
    
    function setContractURI(string memory _contractURI) public onlyOwner {
        baseContractURI = _contractURI;    
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }


    /**
     * @dev A check to see if a MintPass token has been used to mint
     */
    function isMintPassClaimed(uint256 tokenId) public view returns (bool claimed) {
        return mintpassclaimlist[tokenId].tokenId == tokenId;
    }


    /**
     * @dev Sets a new mint pass address
     */
    function setMintPassAddress(address _mintPassToken) external onlyOwner {
        mintPassContract = MintPassContract(_mintPassToken);
    }

    /**
     * @dev Sets a new mint price
     */
    function setMintPrice(uint256 val) external onlyOwner {
        price = val;
    }

    /**
     * @dev Toggles the state of the public sale
     */
    function toggleMintState() public onlyOwner {
        mintActive = !mintActive;
    }

    /**
     * @dev Begins the MintPass mint
     */
    function enableMintMintPass() public onlyOwner {
        mintMintPassActive = !mintMintPassActive;
    }

    /**
     * @dev Toggles the state of the whitelist sale
     */
    function toggleMintWhiteListState() public onlyOwner {
        mintWhiteListActive = !mintWhiteListActive;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function setOgMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
            ogMerkleRoot = _ogMerkleRoot;
        }

    function totalSupply() public view returns (uint256) {
    return _tokenSupply.current();
    }   

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    /**
     * @dev Payouts
     */
    function setT1Address(address t1Address) public onlyOwner {
        t1 = t1Address;
    }
    function setT2Address(address t2Address) public onlyOwner {
        t2 = t2Address;
    }
    function setT3Address(address t3Address) public onlyOwner {
        t3 = t3Address;
    }

    function maxSupply() public view returns (uint256) {
        return MAX_MINTPASS_SUPPLY + MAX_PUBLIC_SUPPLY + MAX_TEAM_MINT;
    }

    /**
     * @dev Withdraws the balance of ETH on the contract
     * @dev to all of the recipients at the same time
     */
    function withdraw() public payable onlyOwner {
        uint256 sale1 = (address(this).balance * 100) / 1000;
        uint256 sale2 = (address(this).balance * 250) / 1000;
        uint256 sale3 = (address(this).balance * 650) / 1000;

        require(payable(t1).send(sale1));
        require(payable(t2).send(sale2));
        require(payable(t3).send(sale3));

    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
}

/**
 * @dev The interface that the MintPass mint requires
 */
interface MintPassContract {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}