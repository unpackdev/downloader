// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

/**

 ___       __    ________   ________                                                        
|\  \     |\  \ |\_____  \ |\   __  \                                                       
\ \  \    \ \  \\|____|\ /_\ \  \|\ /_                                                      
 \ \  \  __\ \  \     \|\  \\ \   __  \                                                     
  \ \  \|\__\_\  \   __\_\  \\ \  \|\  \                                                    
   \ \____________\ |\_______\\ \_______\                                                   
    \|____________| \|_______| \|_______|                                                   
 ________   ________   ___  ___   ________   ___        ________   ________   ________      
|\   ____\ |\   ____\ |\  \|\  \ |\   __  \ |\  \      |\   __  \ |\   __  \ |\   ____\     
\ \  \___|_\ \  \___| \ \  \\\  \\ \  \|\  \\ \  \     \ \  \|\  \\ \  \|\  \\ \  \___|_    
 \ \_____  \\ \  \     \ \   __  \\ \  \\\  \\ \  \     \ \   __  \\ \   _  _\\ \_____  \   
  \|____|\  \\ \  \____ \ \  \ \  \\ \  \\\  \\ \  \____ \ \  \ \  \\ \  \\  \|\|____|\  \  
    ____\_\  \\ \_______\\ \__\ \__\\ \_______\\ \_______\\ \__\ \__\\ \__\\ _\  ____\_\  \ 
   |\_________\\|_______| \|__|\|__| \|_______| \|_______| \|__|\|__| \|__|\|__||\_________\
   \|_________|                                                                 \|_________|


 */

contract W3bScholars is
    ERC721,
    ERC721Enumerable,
    IERC2981,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE_PER_TOKEN = 0.08 ether;
    uint256 public constant MAX_ALLOW_LIST_MINT = 100;

    bool public saleIsActive = false;

    bool public isAllowListActive = false;

    address public beneficiary;
    address public royalties;
    string public baseURI;

    bytes32 public merkleRoot;
    mapping(address => uint256) private _alreadyMinted;

    constructor(
        address _beneficiary,
        address _royalties,
        string memory _initialBaseURI
    ) ERC721("SCHOLARS", "SCHLR") {
        beneficiary = _beneficiary;
        royalties = _royalties;
        baseURI = _initialBaseURI;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    function mintAllowList(uint256 amount, bytes32[] calldata merkleProof)
        public
        payable
        nonReentrant
    {
        address sender = _msgSender();
        uint256 ts = totalSupply();
        require(isAllowListActive, "Sale is closed");
        require(ts + amount <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            amount <= MAX_ALLOW_LIST_MINT - _alreadyMinted[sender],
            "Insufficient mints left"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(sender))
            ),
            "Invalid proof"
        );
        require(
            msg.value == PRICE_PER_TOKEN * amount,
            "Incorrect payable amount"
        );

        _alreadyMinted[sender] += amount;
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(sender, ts + i);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint256 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint");
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(beneficiary).transfer(balance);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "collection.json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice * 750) / 10000;
        return (royalties, royaltyAmount);
    }
}
