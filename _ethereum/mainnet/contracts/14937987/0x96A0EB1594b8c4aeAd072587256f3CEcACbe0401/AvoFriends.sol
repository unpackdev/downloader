// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract AvoFriends is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_PER_TX = 10000;
    uint256 public constant MAX_SUPPLY = 10000;

    bool public publicSaleOpen = true;
    string public baseExtension = ".json";
    string private _baseTokenURI;

    constructor() ERC721A("Avo Friends", "AVOFRIENDS") {}

    function presaleMint(uint256 quantity) external payable {
        require(msg.sender == owner(), "doesn't have permission");
        require(
            quantity > 0,
            "quantity of tokens cannot be less than or equal to 0"
        );
        _safeMint(msg.sender, quantity);
    }

    function mintApe(uint256 quantity) public payable {
        require(msg.sender == owner(), "doesn't have permission");
        require(publicSaleOpen, "Public Sale is not open");
        require(
            quantity > 0,
            "quantity of tokens cannot be less than or equal to 0"
        );
        require(quantity <= MAX_PER_TX, "exceed max per transaction");
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenID),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return
            string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    /* *************** */
    /* OWNER FUNCTIONS */
    /* *************** */
    function giveAway(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
