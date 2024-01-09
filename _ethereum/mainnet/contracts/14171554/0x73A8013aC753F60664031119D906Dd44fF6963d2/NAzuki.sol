// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC165.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract NAzuki is Ownable, ERC721A, IERC2981 {
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public immutable MAX_MINT_PER_ADDRESS = 5;
    uint16 public constant BASE = 10000;
    uint16 internal royalty = 350; // base 10000, 3.5%

    string private baseURI;
    string private contractMetadata;
    address public withdrawAccount;
    uint256 public lastMintData;

    constructor(
        address _withdrawAccount,
        string memory _contractMetadata,
        string memory baseURI_
    ) ERC721A('Not Azuki', 'NAZUKI') {
        withdrawAccount = _withdrawAccount;
        contractMetadata = _contractMetadata;
        baseURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (totalSupply() < MAX_TOKENS) {
            return contractURI();
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function offset() public view returns (uint256) {
        if (totalSupply() < MAX_TOKENS) {
            return 0;
        } else {
            return lastMintData % MAX_TOKENS;
        }
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) public {
        uint256 afterMintSupply = totalSupply() + quantity;
        require(afterMintSupply <= MAX_TOKENS, 'NAZUKI:All tokens are minted');
        require(_numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDRESS, 'NAZUKI:Can not mint this many');

        _safeMint(msg.sender, quantity);
        if (afterMintSupply == MAX_TOKENS) {
            lastMintData = block.number + block.gaslimit + block.timestamp + block.difficulty;
        }
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (withdrawAccount, (_salePrice * royalty) / BASE);
    }

    function setRoyalty(uint16 _royalty) public onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'NAZUKI:Royalty must be between 0% and 10%.');

        royalty = _royalty;
    }

    function setContractURI(string memory _contractMetadata) public onlyOwner {
        contractMetadata = _contractMetadata;
    }

    function setBaseURI(string memory baseContractURI) public onlyOwner {
        baseURI = baseContractURI;
    }
}
