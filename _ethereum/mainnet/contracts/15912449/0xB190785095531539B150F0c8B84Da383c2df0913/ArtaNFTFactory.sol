// File: contracts/OpenGateNFTV3.sol

pragma solidity =0.6.6;
import "./Vendor.sol";
import "./Initializable.sol";
import "./BEP20UpgradeableProxy.sol";
import "./IWhiteList.sol";

contract ArtaNFTFactory is AccessControl, Initializable {
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    mapping(address => bool) nftMap;
    address[] public nfts;

    address public nftLogic;
    IWhiteList public whiteList;

    event Create(address indexed sender, string indexed name, address indexed nft, string symbol, address coin, address feeAcount, uint256 feeAmout);
    event SetOpen(address indexed sender, bool indexed open);
    event SetAdmin(address indexed sender, address indexed account);
    event SetCoin(address indexed sender, address indexed coin);
    event SetAccount(address indexed sender, address indexed account);
    event SetAmount(address indexed sender, uint256 indexed amount);
    
    function initialize(
        address _nftLogic,
        IWhiteList _whiteList
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        nftLogic = _nftLogic;
        whiteList = _whiteList;
    }

    function deployNFT(
        string memory name, 
        string memory symbol, 
        string memory baseUri,
        address coin, 
        address payable feeAccount, 
        uint256 feeAmount,
        uint256 tokenRoyalties,
        uint256 maxMintLimit
    ) public onlyAdmin returns (address pair) {
        return _deployNFT(            
            name,
            symbol,
            baseUri,
            coin,
            feeAccount,
            feeAmount,
            tokenRoyalties,
            maxMintLimit
            );
    }

    function upgradeLogic(address _nftLogic) public onlyAdmin {
        nftLogic = _nftLogic;
        for (uint256 i = 0; i < nfts.length; i++) {
            BEP20UpgradeableProxy(payable(nfts[i])).upgradeTo(_nftLogic);
        }
    }

    function upgradeWhiteList(IWhiteList _whiteList) public onlyAdmin {
        whiteList = _whiteList;
    }


    function _deployNFT(
        string memory name, 
        string memory symbol, 
        string memory baseUri,
        address coin, 
        address payable feeAccount, 
        uint256 feeAmount,
        uint256 tokenRoyalties,
        uint256 maxMintLimit
    ) private returns (address pair) {
        address nft = address(new BEP20UpgradeableProxy(nftLogic, address(this), ""));
        (bool success, bytes memory data) = nft.call(abi.encodeWithSignature("initialize(string,string,string,address,address,uint256,uint256,uint256)", 
            name,
            symbol,
            baseUri,
            coin,
            feeAccount,
            feeAmount,
            maxMintLimit,
            tokenRoyalties
        ));
        require(success);
        pair = address(nft);
        _addNFT(pair);
        emit Create(_msgSender(), name, pair, symbol, coin, feeAccount, feeAmount);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role');
        _;
    }

    function _addNFT(address _nft) private {
        nftMap[_nft] = true;
        nfts.push(_nft);
    }

    function setAdmin(address _address) public onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
        emit SetAdmin(_msgSender(), _address);
    }

    function beforeMint(address from) public returns (uint256) {
        require(nftMap[msg.sender], 'NFT contract not found');
        require(whiteList.isOpen(msg.sender, from), 'Mint not opening');
        return whiteList.addWhiteListUsedCount(msg.sender, from);
    }

    function setWhiteList(
        address token,
        address[] calldata addressArray,
        uint256[] calldata priceArray,
        uint256[] calldata limitArray
    ) external onlyAdmin {
        whiteList.setWhiteList(token, addressArray, priceArray, limitArray);
    }

    function setCollectionWhiteListOpen(address token, bool open)
        external
        onlyAdmin
    {
        whiteList.setCollectionWhiteListOpen(token, open);
    }

    function setCollectionAllOpen(address token, bool open) external onlyAdmin {
        whiteList.setCollectionAllOpen(token, open);
    }
}