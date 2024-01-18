pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Errors.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract HORNS is Initializable, ERC721PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IERC2981Upgradeable, DefaultOperatorFiltererUpgradeable {
    using SafeMathUpgradeable for uint256;

    // @dev: supply for collection
    uint256 constant _max = 1000;
    uint256 constant _maxUser = 900;

    // @dev: handler
    address public _admin;
    address public _paramsAddress;

    string public _algorithm;
    uint256 public _counter;
    string public _uri;

    // @dev: mint condition 
    // base on PLAYER nft
    address public _tokenAddrErc721;
    // base on fee
    uint256 public _fee;

    struct Horn {
        string nation;
        string palletTop;
        string palletBottom;
    }

    uint256 public _limit;

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0) && paramsAddress != address(0), Errors.INV_ADD);
        __ERC721_init(name, symbol);
        _paramsAddress = paramsAddress;
        _admin = admin;
        _limit = _maxUser;

        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __ReentrancyGuard_init();
        __ERC721Pausable_init();
    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != address(0) && _admin != newAdm, Errors.ONLY_ADMIN_ALLOWED);
        _admin = newAdm;
    }

    function changeParam(address newP) external {
        require(msg.sender == _admin && newP != address(0) && _paramsAddress != newP, Errors.ONLY_ADMIN_ALLOWED);
        _paramsAddress = newP;
    }

    function changeToken(address sweet) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _tokenAddrErc721 = sweet;
    }

    function setAlgo(string memory algo) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _algorithm = algo;
    }

    function setFee(uint256 fee) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _fee = fee;
    }

    function setLimit(uint256 limit) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _limit = limit;
    }

    function pause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _pause();
    }

    function unpause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _unpause();
    }

    function withdraw() external nonReentrant {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success);
    }


    function seeding(uint256 id, string memory trait) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(trait, StringsUpgradeable.toString(id))));
    }

    /* @TRAITS: Get data for render
    */
    function getNation(uint256 id) internal view returns (string memory) {
        // 3% for each
        string[32] memory _nations = [
        "Qatar", "Ecuador", "Senegal", "Netherlands", // GA
        "England", "IR Iran", "USA", "Wales", // GB
        "Argentina", "Saudi Arabia", "Mexico", "Poland", // GC
        "France", "Australia", "Denmark", "Tunisia", //GD
        "Spain", "Costa Rica", "Germany", "Japan", //GE
        "Belgium", "Canada", "Morocco", "Croatia", //GF
        "Brazil", "Serbia", "Switzerland", "Cameroon", //GG
        "Portugal", "Ghana", "Uruguay", "Korea Republic" // GH
        ];
        return _nations[seeding(id, "nation") % _nations.length];
    }

    function getPaletteBottom(uint256 id) public view returns (string memory) {
        string[35] memory colors = [
        '#00A5E3', '#8DD7BF', '#FF96C5', '#FF5768', '#FFBF65',
        '#FC6238', '#FFD872', '#F2D4CC', '#E77577', '#6C88C4',
        '#C05780', '#FF828B', '#E7C582', '#00B0BA', '#0065A2',
        '#00CDAC', '#FF6F68', '#FFDACC', '#FF60A8', '#CFF800',
        '#FF5C77', '#4DD091', '#FFEC59', '#FFA23A', '#74737A',
        '#FFF100', '#FF8C00', '#E81123', '#EC008C', '#68217A',
        '#00188F', '#00BCF2', '#00B294', '#009E49', '#BAD80A'
        ];
        return colors[seeding(id, "palletBottom") % colors.length];
    }

    function getPaletteTop(uint256 id) public view returns (string memory) {
        string[25] memory colors = [
        '#ABDEE6', '#CBAACB', '#FFFFB5', '#FFCCB6', '#F3B0C3',
        '#C6DBDA', '#FEE1E8', '#FED7C3', '#F6EAC2', '#ECD5E3',
        '#FF968A', '#FFAEA5', '#FFC5BF', '#FFD8BE', '#FFC8A2',
        '#D4F0F0', '#8FCACA', '#CCE2CB', '#B6CFB6', '#97C1A9',
        '#FCB9AA', '#FFDBCC', '#ECEAE4', '#A2E1DB', '#55CBCD'
        ];
        return colors[seeding(id, "palletTop") % colors.length];
    }

    function getParamValues(uint256 tokenId) public view returns (Horn memory horn) {
        horn = Horn(
            getNation(tokenId),
            getPaletteTop(tokenId),
            getPaletteBottom(tokenId)
        );
        return horn;
    }

    /* @URI: control uri
    */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function changeBaseURI(string memory baseURI) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _uri = baseURI;
    }

    /* @MINT mint nft
    */
    function mintByToken(uint256 tokenIdGated) public {
        require(_tokenAddrErc721 != address(0) && _limit > 0, Errors.INV_ADD);
        // owner erc-721
        IERC721Upgradeable token = IERC721Upgradeable(_tokenAddrErc721);
        require(token.ownerOf(tokenIdGated) == msg.sender);

        require(_counter < _maxUser && _counter < _limit);
        _counter++;
        _safeMint(msg.sender, _counter);
    }

    function mint() public payable {
        require(_fee > 0 && msg.value >= _fee && _limit > 0, Errors.INV_FEE_PROJECT);
        require(_counter < _maxUser && _counter < _limit);
        _counter++;
        _safeMint(msg.sender, _counter);
    }

    function ownerMint(uint256 id) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(id > _maxUser && id <= _max);
        _safeMint(msg.sender, id);
    }

    /** @dev EIP2981 royalties implementation. */
    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _admin;
        royaltyAmount = (_salePrice * 500) / 10000;
    }

    /* @notice: opensea operator filter registry
    */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
