//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//    _    __   , __   ___ 
// \_|_)  /\_\//|/  \ / (_)
//   |   |    | |___/ \__  
//  _|   |    | | \   /    
// (/\___/\__/  |  \_/\___/
import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";
import "./Counters.sol";

contract Lore is ERC721, Ownable, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter public totalSupply;

    /* Tree management */
    uint256 constant STORY_ROOT = 0; // tokenId of root, the empty sentence
    mapping (uint256 => uint256[]) public children;
    mapping (uint256 => uint256) public parent;
    
    /* Tree node data */
    mapping (uint256 => string) public sentence;
    mapping (uint256 => uint16) public imageStyle;
    
    /* Sale management */
    bytes32 mirrorMerkleRoot;
    mapping (address => bool) public hasClaimedAllowlist; 

    event SentenceAdded(uint256 tokenId, string sentence);

    constructor() ERC721("Lore","LORE") {
        // make a "root" node to be the base case
        sentence[STORY_ROOT] = '';
        imageStyle[STORY_ROOT] = 0;
        _safeMint(msg.sender, STORY_ROOT);
        totalSupply.increment();
    }

    function mintSeed(string calldata _sentence, uint16 _imageStyle) public payable {
        require(msg.value == 0.08 ether || msg.sender == owner(), "requires money");
        _mint(STORY_ROOT, _sentence, _imageStyle);
    }
    /**
     * gas-efficient allowlist using MerkleProof
     * we could make the tx less expensive if the seed 
     * had to be their first purchase
     */
    function mintSeedBacker(string calldata _sentence,
                            uint16 _imageStyle,
                            bytes32[] calldata _merkleProof) external
    {
        bytes32 node = getMerkleLeaf(msg.sender);
        require(
            MerkleProof.verify(_merkleProof, mirrorMerkleRoot, node),
            "Non-backers must pay to mint"
        );
        require(!hasClaimedAllowlist[msg.sender], "Already claimed");
        hasClaimedAllowlist[msg.sender] = true;
        _mint(STORY_ROOT, _sentence, _imageStyle);
    }
    /* Convenience methods */
    function getMerkleLeaf(address _claimer) public pure returns (bytes32) {
        // airdrop is a list of addresses
        return keccak256(abi.encodePacked(_claimer));
    }
    function setEarlyBackerMerkleRoot(bytes32 _root) external onlyOwner {
        mirrorMerkleRoot = _root;
    }
    function mint(uint256 _parentId, string calldata _sentence, uint16 _imageStyle) external {
        require(_parentId != 0, "mint seeds through mintSeed");
        _mint(_parentId, _sentence, _imageStyle);
    }
    function _mint(uint256 _parentId, 
                    string calldata _sentence,
                    uint16 _imageStyle) internal returns (uint256 tokenId) {
        tokenId = totalSupply.current();
        totalSupply.increment();
        children[_parentId].push(tokenId);
        parent[tokenId] = _parentId;
        sentence[tokenId] = _sentence;
        imageStyle[tokenId] = _imageStyle;
        _safeMint(msg.sender, tokenId);
        emit SentenceAdded(tokenId, _sentence);
    }
    /**
     * ROYALTIES
     */
    uint256 public constant ROYALTY_AMOUNT_BIPS = 500; // 5%
    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    )
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = owner();
        require(receiver != address(0));
        royaltyAmount = (_salePrice * ROYALTY_AMOUNT_BIPS) / 10000;
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    // See https://docs.opensea.io/docs/contract-level-metadata for details.
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
            _baseURI(),
            'contract-metadata'
        ));
    }
    /**
    * HELPER FUNCTIONS
    * */
    function storyAt(uint256 _tokenId) public virtual view returns (string memory) {
        uint256 curToken = _tokenId;
        string memory story = '';
        while (curToken != STORY_ROOT) {
            story = string(abi.encodePacked(sentence[curToken], story));
            curToken = parent[curToken];
        }
        return story;
    }

    function getNumChildren(uint256 _tokenId) public virtual view returns (uint256) {
        return children[_tokenId].length;
    }

    function getAllChildren(uint256 _tokenId) public virtual view returns (uint256[] memory) {
        return children[_tokenId];
    }

    function getAllParents(uint256 _tokenId) public virtual view returns (uint256[] memory) {
        uint256 curToken = _tokenId;
        uint256 treeDepth = 0;
        while (curToken != STORY_ROOT) {
            treeDepth++;
            curToken = parent[curToken];
        }
        
        
        uint256[] memory parents = new uint256[](treeDepth);
        curToken = _tokenId;
        for (uint256 i = 0; i < treeDepth; i++) {
            parents[i] = curToken;
            curToken = parent[curToken];
        }
        return parents;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        string memory toReturn = string(abi.encodePacked(
            "http://makelore.xyz/metadata/",
            toAsciiString(address(this)),
            '/'
            ));
        return toReturn;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
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

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(sent, "Withdraw failed");
    }
    receive() external payable {}
}