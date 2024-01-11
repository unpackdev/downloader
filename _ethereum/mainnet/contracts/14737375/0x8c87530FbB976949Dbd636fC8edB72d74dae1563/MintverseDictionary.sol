// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IMintverseDictionary.sol";
import "./IMintverseWord.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

/*
 * ███╗   ███╗██╗███╗   ██╗████████╗██╗   ██╗███████╗██████╗ ███████╗███████╗    ██████╗ ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██████╗ ██╗   ██╗ 
 * ████╗ ████║██║████╗  ██║╚══██╔══╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    ██╔══██╗██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝ 
 * ██╔████╔██║██║██╔██╗ ██║   ██║   ██║   ██║█████╗  ██████╔╝███████╗█████╗      ██║  ██║██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████║██████╔╝ ╚████╔╝  
 * ██║╚██╔╝██║██║██║╚██╗██║   ██║   ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      ██║  ██║██║██║        ██║   ██║██║   ██║██║╚██╗██║██╔══██║██╔══██╗  ╚██╔╝  
 * ██║ ╚═╝ ██║██║██║ ╚████║   ██║    ╚████╔╝ ███████╗██║  ██║███████║███████╗    ██████╔╝██║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║██║  ██║   ██║   
 * ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝     ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═════╝ ╚═╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   
 *                                                                                                                                               @ryanycw            
 *                                                                                                                                                                                     
 *      第二宇宙辭典 鑄造宣言
 *   1. 即使舊世界的文明已經滅亡，我們仍相信文字保存了曾有的宇宙。
 *   2. 我們不排斥嶄新的當代文明，只是相信古老的符號裡，仍含有舊世界人類獨得之奧秘。
 *   3. 我們不相信新世界與舊世界之間，是毫無關聯的兩個文明。
 *   4. 我們相信在最簡單的線條裡，有最豐滿的形象、顏色與場景。
 *   5. 我們確知一切最複雜的思想，必以最單純的音節組成。
 *   6. 我們相信文字永不衰亡，只是沉睡。喚醒文字的方式，便是釋義、辨析、定義、區分⋯⋯。
 *   7. 我們不執著於「正確」，我們更信任「想像」。因為，從線條聯想物象，音節捕捉概念，正是人類文明的輝煌起點。
 *   8. 它是什麼意思；它不是什麼意思——這些都很重要。但最重要的是：它「還可以」是什麼意思？
 *   9. 我們熱愛衝突，擁抱矛盾，因為激烈碰撞所能引出的奧秘，遠勝於眾口一聲的意見。   
 *  10. 我們堅決相信：在我們降生群聚的第一宇宙之外、之間、之前、之後，還有一個值得我們窮盡想像力去探索的第二宇宙。
 */ 

contract IMintverseDictionaryStorage {
    // Mint Record Variables
    mapping(address => bool) public airdropCheck;
    mapping(address => uint256) public whitelistMintAmount;
    // Phase Limitation Variables
    bool public claimWhitelistEnable;
    bool public claimPublicEnable;
    bool public mintWhitelistEnable;
    bool public mintPublicEnable;
    uint256 public claimWhitelistTimestamp;
    uint256 public claimPublicTimestamp;
    uint256 public mintWhitelistTimestamp;
    uint256 public mintPublicTimestamp;
    // Mint Record Variables
    uint256 public totalAirdropDictionary; 
    uint256 public totalDictionary;
    // Mint Limitation Variables
    address public mintverseWordAddress;
    uint256 public DICT_ADDON_PRICE;
    uint256 public MAX_MINTVERSE_DICTIONARY;
    // Governance Variables
	address public treasury;
    string public baseTokenURI;
    // Mapping Off-Chain Storage
    string public novelDocumentURI;
    string public legalDocumentURI;
    string public animationCodeDocumentURI;
    string public visualRebuildDocumentURI;
    string public ERC721ATechinalDocumentURI;
    string public metadataMappingDocumentURI;
}

contract MintverseDictionary is IMintverseDictionary, IMintverseDictionaryStorage, Ownable, EIP712, ERC721A {

    using SafeMath for uint16;
    using SafeMath for uint256;

    constructor()
    EIP712("MintverseDictionary", "1.0.0")
    ERC721A("MintverseDictionary", "MVD")     
    {
        claimWhitelistEnable = false;
        claimPublicEnable = false;
        mintWhitelistEnable = false;
        mintPublicEnable = false;
        MAX_MINTVERSE_DICTIONARY = 210;
        DICT_ADDON_PRICE = 0.15 ether;

        mintverseWordAddress = 0x895e34343e2cDAa58BD393EC416b446Ba4781c1c;
        treasury = 0xbE006d0219aF52A7Bbc793D01B2B72AbF45499D0;

        baseTokenURI = "https://api.mintverse.world/dictionary/metadata/";
        novelDocumentURI = "";
        legalDocumentURI = "";
        animationCodeDocumentURI = "";
        visualRebuildDocumentURI = "";
        ERC721ATechinalDocumentURI = "";
        metadataMappingDocumentURI = "";
    }

    /**
     * Modifiers
     */
    modifier claimWhitelistActive() {
		require(claimWhitelistEnable == true, "Can't claim - WL claim phase hasn't enable");
        require(block.timestamp >= claimWhitelistTimestamp, "Can't claim - WL claim phase hasn't started");
        _;
    }

    modifier claimPublicActive() {
		require(claimPublicEnable == true, "Can't claim - Public claim phase hasn't enable");
        require(block.timestamp >= claimPublicTimestamp, "Can't claim - Public claim phase hasn't started");
        _;
    }

    modifier mintWhitelistActive() {
		require(mintWhitelistEnable == true, "Can't mint - WL mint phase hasn't enable");
        require(block.timestamp >= mintWhitelistTimestamp, "Can't mint - WL mint phase hasn't started");
        _;
    }

    modifier mintPublicActive() {
		require(mintPublicEnable == true, "Can't mint - Public mint phase hasn't enable");
        require(block.timestamp >= mintPublicTimestamp, "Can't mint - Public mint phase hasn't started");
        _;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Invalid caller - Caller is a Contract");
        _;
    }

    /**
     * Verify Functions
     */
    /** @dev Verify if a address is eligible to mint a specific amount
     * @param SIGNATURE Signature used to verify the minter address and amount of minter tokens
     */
    function verifyMint(
        uint256 maxQuantity,
        bytes calldata SIGNATURE
    ) 
        public 
        override
        view 
        returns(bool)
    {
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("MINT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);
        return owner() == recoveredAddr;
    }

    /** @dev Verify if a address is eligible to claim a specific amount
     * @param SIGNATURE Signature used to verify the claimer address and amount of claimable tokens
     */
    function verifyClaim(
        uint256 maxQuantity,
        bytes calldata SIGNATURE
    ) 
        public 
        override
        view 
        returns(bool)
    {
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("CLAIM(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);
        return owner() == recoveredAddr;
    }
    
    /**
     * Mint Functions
     */
    /** @dev Airdrop dictionary token to address that have purchased addon
     * @param to Address to airdrop the dictionary token
     */
    function airdropDictionary(address to) 
        external
        override
        onlyOwner
    {
        require(airdropCheck[to] == false, "Already airdropped");
        require(totalAirdropDictionary.add(1) <= IMintverseWord(mintverseWordAddress).getTotalDictionary(), "Exceed maximum dictionary addon amount");
        require(IMintverseWord(mintverseWordAddress).getAddonStatusByOwner(to) == true, "Invalid airdrop - Didn't purchase addon");
        
        airdropCheck[to] = true;
        totalAirdropDictionary = totalAirdropDictionary.add(1);
        
        _safeMint(to, 1);
        emit mintDictionaryEvent(to, 1, totalSupply());
    }
    
    /** @dev Mint giveaway dictionary tokens to an address as owner
     * @param to Address to transfer the dictionary tokens to
     * @param quantity Amount of giveaway tokens to mint
     */
    function mintGiveawayDictionary(
        address to,
        uint256 quantity
    ) 
        external
        override
        onlyOwner
    {   
        require(totalDictionary.add(IMintverseWord(mintverseWordAddress).getTotalDictionary()).add(quantity) <= MAX_MINTVERSE_DICTIONARY, "Exceed maximum dictionary amount");
        totalDictionary = totalDictionary.add(quantity);

        _safeMint(to, quantity);
        emit mintDictionaryEvent(to, quantity, totalSupply());
    }

    /** @dev Mint dictionary token as Whitelisted Address
     * @param quantity Amount of whitelistes tokens to mint
     * @param maxClaimNum Maximum amount of mintable tokens
     * @param SIGNATURE Signature used to verify the minter address and amount of mintable tokens
     */
    function mintWhitelistDictionary(
        uint256 quantity,
        uint256 maxClaimNum, 
        bytes calldata SIGNATURE
    ) 
        external 
        payable
        override
        mintWhitelistActive
        callerIsUser
    {
        require(verifyMint(maxClaimNum, SIGNATURE), "Can't claim - Not eligible");
        require(totalDictionary.add(IMintverseWord(mintverseWordAddress).getTotalDictionary()).add(quantity) <= MAX_MINTVERSE_DICTIONARY, "Exceed maximum dictionary amount");
        require(quantity > 0 && whitelistMintAmount[msg.sender].add(quantity) <= maxClaimNum, "Exceed maximum mintable whitelist amount");
        require(msg.value == DICT_ADDON_PRICE.mul(quantity), "Not the right amount of ether");
        
        whitelistMintAmount[msg.sender] = whitelistMintAmount[msg.sender].add(quantity);
        totalDictionary = totalDictionary.add(quantity);
        
        _safeMint(msg.sender, quantity);
        emit mintDictionaryEvent(msg.sender, quantity, totalSupply());
    }

    /** @dev Claim dictionary token as Whitelisted Address
     * @param quantity Amount of whitelistes tokens to claim
     * @param maxClaimNum Maximum amount of claimable tokens
     * @param SIGNATURE Signature used to verify the claimer address and amount of claimable tokens
     */
    function claimWhitelistDictionary(
        uint256 quantity,
        uint256 maxClaimNum, 
        bytes calldata SIGNATURE
    ) 
        external 
        payable
        override
        claimWhitelistActive
        callerIsUser
    {
        require(verifyClaim(maxClaimNum, SIGNATURE), "Can't claim - Not eligible");
        require(totalDictionary.add(IMintverseWord(mintverseWordAddress).getTotalDictionary()).add(quantity) <= MAX_MINTVERSE_DICTIONARY, "Exceed maximum dictionary amount");
        require(quantity > 0 && whitelistMintAmount[msg.sender].add(quantity) <= maxClaimNum, "Exceed maximum mintable whitelist amount");
        
        whitelistMintAmount[msg.sender] = whitelistMintAmount[msg.sender].add(quantity);
        totalDictionary = totalDictionary.add(quantity);
        
        _safeMint(msg.sender, quantity);
        emit mintDictionaryEvent(msg.sender, quantity, totalSupply());
    }

    /** @dev Mint dictionary token as Public Address
     * @param quantity Amount of public tokens to mint
     */
    function mintPublicDictionary(
        uint256 quantity
    )
        external
        payable 
        override
        mintPublicActive
        callerIsUser
    {
        require(totalDictionary.add(IMintverseWord(mintverseWordAddress).getTotalDictionary()).add(quantity) <= MAX_MINTVERSE_DICTIONARY, "Exceed maximum dictionary amount");
        require(msg.value == DICT_ADDON_PRICE.mul(quantity), "Not the right amount of ether");
            
        totalDictionary = totalDictionary.add(quantity);
        
        _safeMint(msg.sender, quantity);
        emit mintDictionaryEvent(msg.sender, quantity, totalSupply());
    }

    /** @dev Claim dictionary token as Public Address
     * @param quantity Amount of public tokens to claim
     */
    function claimPublicDictionary(
        uint256 quantity
    )
        external
        payable 
        override
        claimPublicActive
        callerIsUser
    {
        require(totalDictionary.add(IMintverseWord(mintverseWordAddress).getTotalDictionary()).add(quantity) <= MAX_MINTVERSE_DICTIONARY, "Exceed maximum dictionary amount");
            
        totalDictionary = totalDictionary.add(quantity);
        
        _safeMint(msg.sender, quantity);
        emit mintDictionaryEvent(msg.sender, quantity, totalSupply());
    }

    function getTotalDictionary()
        external
        view
        returns(uint256 amount)
    {
        uint256 prev = IMintverseWord(mintverseWordAddress).getTotalDictionary();
        uint256 cur = totalDictionary;
        uint256 total = prev.add(cur);
        return total;
    }

    /** @dev Retrieve all tokenIds of a given address
     * @param owner Address which caller wants to get all of its tokenIds
     */
    function tokensOfOwner(address owner) 
        external 
        view 
        override
        returns(uint256[] memory) 
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    /** @dev Set the status of whitelist mint phase and its starting time
     * @param _hasWLMintStarted True if the whitelist mint phase have started, otherwise false
     * @param _wlMintTimestamp After this timestamp the whitelist mint phase will be enabled
     */
    function setWLMintPhase(
        bool _hasWLMintStarted, 
        uint256 _wlMintTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        mintWhitelistEnable = _hasWLMintStarted;
        mintWhitelistTimestamp = _wlMintTimestamp;
    }

    /** @dev Set the status of public mint phase and its starting time
     * @param _hasPublicMintStarted True if the public mint phase have started, otherwise false
     * @param _publicMintTimestamp After this timestamp the public mint phase will be enabled
     */
    function setPublicMintPhase(
        bool _hasPublicMintStarted, 
        uint256 _publicMintTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        mintPublicEnable = _hasPublicMintStarted;
        mintPublicTimestamp = _publicMintTimestamp;
    }

    /** @dev Set the status of whitelist claim phase and its starting time
     * @param _hasWLClaimStarted True if the whitelist claim phase have started, otherwise false
     * @param _wlClaimTimestamp After this timestamp the whitelist claim phase will be enabled
     */
    function setWLClaimPhase(
        bool _hasWLClaimStarted, 
        uint256 _wlClaimTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        claimWhitelistEnable = _hasWLClaimStarted;
        claimWhitelistTimestamp = _wlClaimTimestamp;
    }

    /** @dev Set the status of public claim phase and its starting time
     * @param _hasPublicClaimStarted True if the public claim phase have started, otherwise false
     * @param _publicClaimTimestamp After this timestamp the public claim phase will be enabled
     */
    function setPublicClaimPhase(
        bool _hasPublicClaimStarted, 
        uint256 _publicClaimTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        claimPublicEnable = _hasPublicClaimStarted;
        claimPublicTimestamp = _publicClaimTimestamp;
    }

    /** @dev Set the price to purchase dictionary tokens.
     * @param price New price that caller wants to set as the price of dictionary tokens
     */
    function setDictPrice(uint256 price) 
        override 
        external 
        onlyOwner 
    {
        DICT_ADDON_PRICE = price;
    }

    /** @dev Set the maximum supply of dictionary tokens.
     * @param amount Maximum amount of dictionary tokens
     */
    function setMaxDictAmt(uint256 amount) 
        override 
        external 
        onlyOwner 
    {
        MAX_MINTVERSE_DICTIONARY = amount;
    }

    /** @dev Set the maximum supply of dictionary tokens.
     * @param newTokenAddress Maximum amount of dictionary tokens
     */
    function setMintverseWordTokenAddress(address newTokenAddress) 
        override 
        external 
        onlyOwner 
    {
        mintverseWordAddress = newTokenAddress;
    }

    /** @dev Set the URI for novelDocumentURI, which returns URI of the novel document.
     * @param newNovelDocumentURI New URI that caller wants to set as novelDocumentURI
     */
    function setNovelDocumentURI(string calldata newNovelDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		novelDocumentURI = newNovelDocumentURI;
	}

    /** @dev Set the URI for legalDocumentURI, which returns the URI of legal document.
     * @param newLegalDocumentURI New URI that caller wants to set as legalDocumentURI
     */
    function setLegalDocumentURI(string calldata newLegalDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		legalDocumentURI = newLegalDocumentURI;
	}

    /** @dev Set the URI for animationCodeDocumentURI, which returns the URI of animation code.
     * @param newAnimationCodeDocumentURI New URI that caller wants to set as animationCodeDocumentURI
     */
    function setAnimationCodeDocumentURI(string calldata newAnimationCodeDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		animationCodeDocumentURI = newAnimationCodeDocumentURI;
	}

    /** @dev Set the URI for visualRebuildDocumentURI, which returns the URI of visual rebuild document.
     * @param newVisualRebuildDocumentURI New URI that caller wants to set as visualRebuildDocumentURI
     */
    function setVisualRebuildDocumentURI(string calldata newVisualRebuildDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		visualRebuildDocumentURI = newVisualRebuildDocumentURI;
	}

    /** @dev Set the URI for ERC721ATechinalDocumentURI, which returns the URI of ERC721A technical document.
     * @param newERC721ATechinalDocumentURI New URI that caller wants to set as ERC721ATechinalDocumentURI
     */
    function setERC721ATechinalDocumentURI(string calldata newERC721ATechinalDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		ERC721ATechinalDocumentURI = newERC721ATechinalDocumentURI;
	}

    /** @dev Set the URI for metadataMappingDocumentURI, which returns the URI of metadata mapping document.
     * @param newMetadataMappingDocumentURI New URI that caller wants to set as metadataMappingDocumentURI
     */
    function setMetadataMappingDocumentURI(string calldata newMetadataMappingDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		metadataMappingDocumentURI = newMetadataMappingDocumentURI;
	}

    /** @dev Set the address that act as treasury and recieve all the fund from token contract.
     * @param _treasury New address that caller wants to set as the treasury address
     */
    function setTreasury(address _treasury) 
        override 
        external 
        onlyOwner 
    {
        require(_treasury != address(0), "Invalid address - Zero address");
        treasury = _treasury;
    }

    /**
     * Withdrawal Functions
     */
    /** @dev Withdraw all the funds in the contract
     */
	function withdrawAll() 
        override 
        external 
        payable 
        onlyOwner 
    {
		payable(treasury).transfer(address(this).balance);
	}
}