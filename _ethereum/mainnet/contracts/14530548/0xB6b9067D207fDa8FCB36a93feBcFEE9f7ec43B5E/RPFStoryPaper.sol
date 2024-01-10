// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IRPFStoryPaper.sol";
import "./IRPF.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract RPFStoryPaperStorage {
    mapping(uint256 => bool) public writtenRPFStoryPaper;
    mapping(uint256 => string) public RPFName;
    mapping(uint256 => string) public tokenStory;
    mapping(address => uint256) public claimedAmt;

    bool public writeEnable;
    uint256 public writeTimestamp;
    address public RPFAddr;

    uint256 public MAX_RPFSTORYPAPER;

	uint256 public totalGiveaway;
    uint256 public totalClaim;
    
    uint256 public claimTimestamp;
	bool public claimEnable;

	string public _baseTokenURI;
    address public treasury;
}

contract RPFStoryPaper is IRPFStoryPaper, RPFStoryPaperStorage, Ownable, EIP712, ERC721A {

    using SafeMath for uint256;
	using Strings for uint256;

    constructor()
    EIP712("RPFStoryPaper", "1.0.0")
    ERC721A("RPFStoryPaper", "RPFP")
    {
        writeEnable = false;
        RPFAddr = 0xc9E3Ca32CAaA6ee67476C5d35d4B8ec64F58D4Ad;

        MAX_RPFSTORYPAPER = 3333;
        claimEnable = false;

        _baseTokenURI = "https://api.rugpullfrens.art/paper/metadata/";
    }

    /**
     * Modifiers
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownershipOf(tokenId).addr == msg.sender, "NOT_PP_OWNER");
        _;
    }

    modifier paperWritten(uint256 tokenId) {
        require(writtenRPFStoryPaper[tokenId] == false, "PP_WRITTEN");
        _;
    }

    modifier writeActive() {
        require(writeEnable, "CANT_WRITE");
        require(block.timestamp >= writeTimestamp, "NOT_IN_WRITE_TIME");
        _;
    }

    modifier claimActive() {
		require(claimEnable == true, "CLAIM_NOT_ACTIVE");
        require(block.timestamp >= claimTimestamp, "NOT_IN_CLAIM_TIME");
        _;
    }
    
    /**
     * Verify Functions
     */
    function verify(
        uint256 maxQuantity, 
        bytes memory SIGNATURE
    ) 
        public 
        override 
        view 
        returns(bool)
    {
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);
        return owner() == recoveredAddr;
    }

    /**
     * Mint Functions
     */
    function mintGiveawayPaper(
        address _to, 
        uint256 quantity
    ) 
        external
        override
        onlyOwner
    {   
        require(totalSupply().add(quantity) <= MAX_RPFSTORYPAPER, "EXCEED_MAX_RPFSTORYPAPER");

		_safeMint(_to, quantity);

		totalGiveaway = totalGiveaway.add(quantity);
		emit mintEvent(_to, quantity, totalSupply());
    }

    function claimRPFPaper(
        uint256 quantity, 
        uint256 maxClaimNum, 
        bytes memory SIGNATURE
    ) 
        external 
        override
        claimActive
    {
        require(verify(maxClaimNum, SIGNATURE), "NOT_ELIGIBLE_CLAIM");
        require(totalSupply().add(quantity) <= MAX_RPFSTORYPAPER, "EXCEED_MAX_RPFSTORYPAPER");
        require(quantity > 0 && claimedAmt[msg.sender].add(quantity) <= maxClaimNum, "EXCEED_MAX_CLAIMABLE");
        _safeMint(msg.sender, quantity);

        totalClaim = totalClaim.add(quantity);
		claimedAmt[msg.sender] = claimedAmt[msg.sender].add(quantity);

        emit mintEvent(msg.sender, quantity, totalSupply());
    }

    /**
     * Write Functions
     */
    /**
     * @dev
     * @param tokenId ChapterId, the page users want to write
     * @param name Name, the name of the corresponding RPF
     * @param story Story, the story that users write
     */
    function writePaperPhase1(
        uint256 tokenId,
        uint256 rpfTokenId,
        string memory name,
        string memory story
    ) 
        external 
        override
        writeActive
        onlyTokenOwner(tokenId)
        paperWritten(tokenId)
    {
        require(IRPF(RPFAddr).ownerOf(rpfTokenId) == msg.sender, "NOT_RPF_OWNER");
        writtenRPFStoryPaper[tokenId] = true;
        RPFName[rpfTokenId] = name;
        tokenStory[rpfTokenId] = story;
        emit phaseOneWritten(tokenId, rpfTokenId, name, story);
    }

    /**
     * Token Functions
     */
	function tokenURI(uint256 tokenId) 
        public 
        view 
        override 
        returns (string memory) 
    {
		require(_exists(tokenId), "TOKEN_NOT_EXISTS");
		return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
	}

    /**
     * Getter Functions 
     */
    function getRPFName(uint256 tokenId)
        public
        view
        override
        returns (string memory name)
    {
        return RPFName[tokenId];
    }

    function getStory(uint256 tokenId)
        public
        view
        override
        returns (string memory story)
    {
        return tokenStory[tokenId];
    }

    function getPaperStatus(address owner) 
        public 
        view 
        override
        returns (bool[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new bool[](0);
        } else {
            bool[] memory result = new bool[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                uint256 token = tokenOfOwnerByIndex(owner, index);
                result[index] = writtenRPFStoryPaper[token];
            }
            return result;
        }
    }

    function tokensOfOwner(address owner) 
        external 
        view 
        override
        returns(uint256[] memory ) 
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    /**
     * Setter Functions 
     */
    function setRPFAddress(address _RPF) 
        override 
        external 
        onlyOwner 
    {
        RPFAddr = _RPF;
    }

    function setWritePhase(
        bool _hasWriteStarted, 
        uint256 _writeTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        writeEnable = _hasWriteStarted;
        writeTimestamp = _writeTimestamp;
    }

    function setClaim(
        bool _hasClaimStarted, 
        uint256 _claimTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        claimEnable = _hasClaimStarted;
        claimTimestamp = _claimTimestamp;
    }

    function setURI(
        string calldata _tokenURI) 
        override 
        external 
        onlyOwner 
    {
		_baseTokenURI = _tokenURI;
	}

    function setTreasury(address _treasury) 
        override 
        external 
        onlyOwner 
    {
        require(_treasury != address(0), "SETTING_ZERO_ADDRESS");
        treasury = _treasury;
    }

    /**
     * Withdrawal Functions
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