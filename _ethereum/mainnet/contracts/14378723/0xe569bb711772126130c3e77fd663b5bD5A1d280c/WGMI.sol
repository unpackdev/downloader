//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./ERC721ABurnable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./IMerkleQuantity.sol";
import "./IMerkle.sol";
import "./OpenSeaGasFreeListing.sol";

contract WGMI is ERC721ABurnable, AccessControl, Pausable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;

    bool public premintLive;
    bool public publicLive;

    uint256 public price = 0.078 ether;
    uint256 public supply = 1475;
    uint256 public limit = 3;
    string public baseUri = "https://ipfs.io/ipfs/QmWgSg8jqk5YhoTBzYdysnuL4QcShmwgNGgHZipAsGep7J/";
    string public extension = ".json";

    mapping(address => bool) public claimed;
    mapping(address => uint256) public preminted;

    IMerkle public merkle;
    IMerkleQuantity public merkleQuantity;

    address[] private _shareholders = [
        0x7d61682343bA7DFCE6C909996bec5a13fc3e65F0,
        0xa40963B7304F0a279850A032c3047BCecD7bC9a6
    ];

    uint256[] private _equities = [85, 15];

    event PremintLive(bool live);
    event PublicLive(bool live);

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) PaymentSplitter(_shareholders, _equities) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function adminMint(address to, uint256 quantity) external nonReentrant whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(totalSupply() + quantity <= supply, "exceeds supply");
        _safeMint(to, quantity);
    }

    function premint(uint256 amount, uint256 _limit, bytes32[] calldata proof, bytes32[] calldata claimProof) external nonReentrant whenNotPaused mintConditions(amount) payable {
        require(premintLive, "Not live");
        uint256 toMint;

        if(isClaimPermittedAndNotClaimed(_msgSender(), claimProof)) {
            claimed[_msgSender()] = true;
            toMint += 1;
        }

        if(isPresalePermittedAndNotExceedsLimit(_msgSender(), _limit, amount, proof)) {
            preminted[_msgSender()] += amount;
            toMint += amount;
            require(msg.value == amount * price, "invalid price");
        }

        require(toMint > 0, "cannot mint zero");

        _safeMint(_msgSender(), toMint);
    }

    function mint(uint256 amount) external nonReentrant whenNotPaused mintConditions(amount) payable {
        require(publicLive, "Not live");
        require(msg.value == price * amount, "Insufficient amount");

        _safeMint(_msgSender(), amount);
    }

    modifier mintConditions(uint256 amount) {
        require(amount <= limit, "Exceeds limit");
        require(totalSupply() + amount <= supply, "exceeds supply");

        _;
    }

    function isClaimPermittedAndNotClaimed(address to, bytes32[] memory proof) public view returns (bool) {
        return merkle.isPermitted(to, proof) && !claimed[to];
    }

    function isPresalePermittedAndNotExceedsLimit(address to, uint256 _limit, uint256 amount, bytes32[] memory proof) public view returns (bool) {
        return merkleQuantity.isPermitted(to, _limit, proof) && (preminted[to] + amount <= _limit);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator) || OpenSeaGasFreeListing.isApprovedForAll(owner, operator);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function togglePublic() external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool isLive = !publicLive;
        publicLive = isLive;
        emit PublicLive(isLive);
    }

    function togglePremint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool isLive = !premintLive;
        premintLive = isLive;
        emit PremintLive(isLive);
    }

    function setExtension(string memory _extension) external onlyRole(DEFAULT_ADMIN_ROLE) {
        extension = _extension;
    }

    function setUri(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseUri = _uri;
    }

    function setMerkle(IMerkle _merkle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkle = _merkle;
    }

    function setMerkleQuantity(IMerkleQuantity _merkle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleQuantity = _merkle;
    }

    function setPrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _price;
    }

    function setSupply(uint256 _supply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supply = _supply;
    }

    function setLimit(uint256 _limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        limit = _limit;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
