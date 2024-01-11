// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";

contract Fomo is ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 constant MAX_SUPPLY = 500;
    uint256 private _currentId;

    uint256 public maxPerWallet = 10;

    string public baseURI;
    string private _contractURI;

    bool public isActive;

    uint256 public price = 10**17;

    mapping(address => uint256) private _alreadyMinted;

    bool private revealed;
    string public unrevealedURI;

    address private beneficiaryT;
    address private beneficiaryM;
    address private beneficiaryO;
    address private beneficiaryStake;
    address public royalties;

    uint256 private royaltyPercent = 5;

    constructor(
        address _beneficiaryT,
        address _beneficiaryM,
        address _beneficiaryO,
        address _beneficiaryStake,
        address _royalties,
        string memory _initialBaseURI,
        string memory _initialContractURI,
        string memory _unrevealedURI
    ) ERC721("Fomo Collection", "FOMO") {
        beneficiaryT = _beneficiaryT;
        beneficiaryM = _beneficiaryM;
        beneficiaryO = _beneficiaryO;
        beneficiaryStake = _beneficiaryStake;
        royalties = _royalties;
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
        unrevealedURI = _unrevealedURI;
    }

    // Accessors

    function setPrice(uint n) external onlyOwner {
        price = n;
    }

    function setMaxPerWallet(uint n) external onlyOwner {
        maxPerWallet = n;
    }

    function setUnrevealedURI(string calldata newURI) external onlyOwner {
        unrevealedURI = newURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setBeneficiaries(
        address _beneficiaryT,
        address _beneficiaryM,
        address _beneficiaryO,
        address _beneficiaryStake
    ) external onlyOwner {
        beneficiaryT = _beneficiaryT;
        beneficiaryM = _beneficiaryM;
        beneficiaryO = _beneficiaryO;
        beneficiaryStake = _beneficiaryStake;
    }

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function batchUriByOwner(address account)
        external
        view
        returns (string[] memory)
    {
        string[] memory uris = new string[](balanceOf(account));
        for (uint256 i = 0; i < balanceOf(account); i++) {
            uris[i] = (tokenURI(tokenOfOwnerByIndex(account, i)));
        }
        return uris;
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
        if (revealed) {
            string memory base = _baseURI();
            return
                bytes(base).length > 0
                    ? string(
                        abi.encodePacked(base, tokenId.toString(), ".json")
                    )
                    : "";
        } else {
            return unrevealedURI;
        }
    }

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    // Metadata

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    // Minting

    function mintPublic(uint256 amount) public payable nonReentrant {
        address sender = _msgSender();

        require(isActive, "Sale is closed");
        require(
            amount <= maxPerWallet - _alreadyMinted[sender],
            "Insufficient mints left"
        );
        require(msg.value == price * amount, "Incorrect payable amount");

        _alreadyMinted[sender] += amount;
        _internalMint(sender, amount);
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _internalMint(to, amount);
    }

    function withdraw() external onlyOwner {
        uint256 t = address(this).balance;
        payable(beneficiaryT).transfer(t * 20 / 100);
        payable(beneficiaryM).transfer(t * 10 / 100);
        payable(beneficiaryO).transfer(t * 20 / 100);
        payable(beneficiaryStake).transfer(t * 50 / 100);
    }

    // Private

    function _internalMint(address to, uint256 amount) private {
        require(
            _currentId + amount <= MAX_SUPPLY,
            "Will exceed maximum supply"
        );

        for (uint256 i = 1; i <= amount; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // IERC2981

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId;
        royaltyAmount = (_salePrice * royaltyPercent) / 100;
        return (royalties, royaltyAmount);
    }
}
