// SPDX-Lisence-Identifier: MIT
pragma solidity ^0.8.13;

//@author some mfers
//@title somfers

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract somfers is Ownable, ERC721A, PaymentSplitter {
    using Strings for uint256;

    enum Step {
        Before,
        PublicSale,
        SoldOut,
        Reveal
    }

    uint256 private constant MAX_SUPPLY = 10021;

    uint256 private teamLength;

    string public baseURI;
    Step public sellingStep;
    uint256 public publicSalePrice = 0.0345 ether;
    string public notRevealedUri;
    bool public revealed = false;

    mapping(address => uint256) public freeNftsPerWallet;

    constructor(
        address[] memory _team,
        uint256[] memory _teamShares,
        string memory _baseURI,
        string memory _notRevealedUri
    ) ERC721A("somfer", "SOMFER") PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        notRevealedUri = _notRevealedUri;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller must be human");
        _;
    }

    function publicSaleMint(address _account, uint256 _quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = publicSalePrice;
        require(price != 0, "that's not free");
        require(sellingStep == Step.PublicSale, "not the right time to mint");
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "not enough somfers available"
        );
        require(msg.value >= price * _quantity, "not enough funds");
        _safeMint(_account, _quantity);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function gift(address _to, uint256 _quantity) external onlyOwner {
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "not enough somfers available"
        );
        _safeMint(_to, _quantity);
    }

    function setStep(uint256 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }
}
