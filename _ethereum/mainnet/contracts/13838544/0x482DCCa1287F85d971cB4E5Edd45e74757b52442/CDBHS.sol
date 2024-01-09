pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract CDBHS is ERC721, Ownable, ReentrancyGuard {
    uint256 public constant STARTING_ID = 160;
    uint256 public constant ENDING_ID = 5360;
    uint256 public constant MAX_PURCHASES = 30;
    uint256 public constant TOKEN_PRICE = 0.0169 ether;

    bool public preSale = false;
    bool public publicSale = false;
    address public cdbs3;

    string private baseURI = "";

    constructor(address _cdbs3) ERC721("CryptoDickbutts Holiday Special", "CDBHS") {
        cdbs3 = _cdbs3;
    }

    function mint(uint256[] memory ids) external payable nonReentrant {
        require(publicSale, "public sale is not live");
        _checkMintRequirements(ids);

        _minter(msg.sender, ids);
    }

    function presaleMint(uint256[] memory ids) external payable nonReentrant {
        require(preSale, "pre sale is not live");
        _checkMintRequirements(ids);

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                IERC721(cdbs3).ownerOf(ids[i]) == msg.sender,
                "you don't own requested token"
            );
        }

        _minter(msg.sender, ids);
    }

    function _checkMintRequirements(uint256[] memory ids) internal {
        uint256 quantity = ids.length;
        require(
            quantity > 0 && quantity <= MAX_PURCHASES,
            "invalid quantity: zero or greater than mint allowance"
        );
        require(
            msg.value == TOKEN_PRICE * quantity,
            "wrong amount of ether sent"
        );
        for (uint256 i; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            require(
                tokenId != 5000 && tokenId >= STARTING_ID && tokenId <= ENDING_ID,
                "invalid token id"
            );
        }
    }

    function togglePublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function togglePreSale() public onlyOwner {
        preSale = !preSale;
    }

    function _minter(address addr, uint256[] memory ids) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            _safeMint(addr, ids[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
}
