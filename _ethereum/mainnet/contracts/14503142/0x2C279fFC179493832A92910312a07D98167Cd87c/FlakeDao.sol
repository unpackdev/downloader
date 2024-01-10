// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract FlakeDao is ERC721, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    string private _altName;
    string private _altSymbol;
    uint256 private _burnCount;
    string private _baseTokenURI;

    // tokenId -> membership
    mapping(uint256 => uint256) public tokenToMembership;

    struct Membership {
        bool enabled;
        uint256 price;
        string uri;
    }

    Membership[] public memberships;

    Counters.Counter private _tokenIdCounter;

    event MembershipAdded(uint256 indexed tokenId, uint256 indexed membershipLevel);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        _baseTokenURI = _uri;
        _burnCount = 0;
        // VIP
        memberships.push(Membership({ enabled: true, price: 1 ether, uri: "diamond" }));
        // Curator
        memberships.push(Membership({ enabled: true, price: 0.5 ether, uri: "gold" }));
        // Founding Member
        memberships.push(Membership({ enabled: true, price: 0.1 ether, uri: "silver" }));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return bytes(_altName).length > 0 ? _altName : super.name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return bytes(_altSymbol).length > 0 ? _altSymbol : unicode"\u2744DAO";
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - _burnCount;
    }

    function burn(uint256 tokenId) public virtual override {
        super.burn(tokenId);
        _burnCount += 1;
    }

    function mint(
        address _owner,
        uint256 _quantity,
        uint256 _level
    ) public payable whenNotPaused {
        Membership storage membership = memberships[_level];
        require(membership.enabled && membership.price > 0, "Membership mint disabled");
        require(membership.price * _quantity == msg.value, "Incorrect ETH value sent");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            tokenToMembership[tokenId] = _level;
            _safeMint(_owner, tokenId);
            emit MembershipAdded(tokenId, _level);
        }
    }

    function ownerMint(
        address _owner,
        uint256 _quantity,
        uint256 _level
    ) public onlyOwner {
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            tokenToMembership[tokenId] = _level;
            _safeMint(_owner, tokenId);
            emit MembershipAdded(tokenId, _level);
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory membershipURI = memberships[tokenToMembership[tokenId]].uri;
        return
            (bytes(baseURI).length > 0 && bytes(membershipURI).length > 0)
                ? string(abi.encodePacked(baseURI, membershipURI, ".json"))
                : "";
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function toggleMembershipEnabled(uint256 _level, bool _enabled) external onlyOwner {
        memberships[_level].enabled = _enabled;
    }

    function updateMembershipPrice(uint256 _level, uint256 _price) external onlyOwner {
        memberships[_level].price = _price;
    }

    function updateMembershipURI(uint256 _level, string memory _uri) external onlyOwner {
        memberships[_level].uri = _uri;
    }

    function addMembership(
        bool _enabled,
        uint256 _price,
        string memory _uri
    ) external onlyOwner {
        memberships.push(Membership({ enabled: _enabled, price: _price, uri: _uri }));
    }

    function setAltName(string memory _name) external onlyOwner {
        _altName = _name;
    }

    function setAltSymbol(string memory _symbol) external onlyOwner {
        _altSymbol = _symbol;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawETH() public onlyOwner {
        (bool success, ) = payable(owner()).call{ value: address(this).balance }("");
        require(success, "Withdraw failed.");
    }

    function withdrawToken(address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(owner(), amount);
    }

    // DEV ONLY
    // function terminate() public onlyOwner {
    //     selfdestruct(payable(owner()));
    // }
}
