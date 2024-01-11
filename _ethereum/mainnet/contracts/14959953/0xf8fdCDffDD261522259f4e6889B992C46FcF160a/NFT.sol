// SPDX-License-Identifier: MIT
//https://rinkeby.etherscan.io/address/0xeC724f0b7e2D7dde7995B73Ec622F593f58f5dF8#code
pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract TinkerTown is ERC721A {
    using Strings for uint256;

    address public owner;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public PUBLIC_SALE_PRICE = 0.02 ether;
    string public baseTokenUri;
    string public placeholderTokenUri;
    bool public isRevealed = false;
    bool public publicSale = true;
    bool public pause = false;
    bool public teamMinted;
    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("TinkerTown", "TITOWN") {
        owner = msg.sender;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "TITOWN :: Cannot be called by a contract"
        );
        _;
    }

    modifier OnlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    function freeMint(uint256 _quantity) public callerIsUser {
        //First 2 NFTs for free
        require(pause == false, "Sale is paused");
        require(publicSale, "TITOWN :: Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "TITOWN :: Beyond Max Supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) < 3,
            "TITOWN :: Already minted 2 times!"
        );
        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        // after Mint 2 NFTs
        require(pause == false, "Sale is paused");
        require(publicSale, "TITOWN :: Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "TITOWN :: Beyond Max Supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "TITOWN :: Already minted 3 times!"
        );

        if (msg.sender != owner) {
            require(msg.value >= PUBLIC_SALE_PRICE * _quantity);
        }
        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _qua) external OnlyOwner {
        require(!teamMinted, "TITOWN :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, _qua);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

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

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return placeholderTokenUri;
        }
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function setTokenUri(string memory _baseTokenUri) external OnlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri)
        external
        OnlyOwner
    {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function togglePause() external OnlyOwner {
        pause = !pause;
    }

    function togglePublicSale() external OnlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external OnlyOwner {
        isRevealed = !isRevealed;
    }

    function transferOwner(address _to) public OnlyOwner {
        owner = _to;
    }

    function withdraw() external OnlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
