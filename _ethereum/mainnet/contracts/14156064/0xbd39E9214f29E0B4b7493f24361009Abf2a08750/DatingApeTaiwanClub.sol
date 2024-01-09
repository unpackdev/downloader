// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract DatingApeTaiwanClub is Ownable, ERC721A {
    using Strings for uint256;
    address public minter;
    string private _baseURIExtended;
    event Minted(address to, uint256 quantity);

    constructor() ERC721A("Dating Ape Taiwan Club", "DATC") {
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "not a minter");
        _;
    }

    // ADMIN FUNCTION
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function mint(address to, uint256 quantity) external onlyMinter {
        _safeMint(to, quantity);
        emit Minted(to, quantity);
    }

    // USER FUNCTIONS
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    // INTERNAL FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }
}
