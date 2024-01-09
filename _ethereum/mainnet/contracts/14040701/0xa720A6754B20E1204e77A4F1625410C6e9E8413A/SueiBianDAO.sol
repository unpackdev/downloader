// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SueiBianDAO is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;

    address public dispenser;
    string private _baseURIExtended;

    constructor() ERC721("SueiBianDAO", "SBD") {}

    modifier onlyDispenserOrOwner() {
        require(
            msg.sender == dispenser || msg.sender == owner(),
            "only dispenser or owner can mint"
        );
        _;
    }

    /******************
     * USER FUNCTIONS *
     ******************/

    // @notice This function can be called to retrieve the tokenURI
    // @param  tokenId - the unique identifier for one NFT
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

    /*******************
     * ADMIN FUNCTIONS *
     *******************/

    function mint(address receiver) external onlyDispenserOrOwner {
        require(totalSupply() + 1 <= MAX_SUPPLY, "MAX_SUPPLY REACHED");
        _safeMint(receiver, totalSupply());
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setDispenser(address _dispenser) external onlyOwner {
        dispenser = _dispenser;
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }
}
