import "./Initializable.sol";
import "./Vendor.sol";
import "./IOwner.sol";
import "./IArtaNFTFactory.sol";

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

contract ArtaNFT is ERC721Pausable, Initializable, IOwner {
    string _name;
    string _symbol;

    uint256 public nextTokenId = 1;
    uint256 public maxMintLimit;
    address public feeERC20Address;
    address payable public mintFeeAddr;
    uint256 public mintFeeAmount;
    uint256 public tokenRoyalties;
    address public override owner;

    IERC20 public quoteErc20;
    mapping(uint256 => address payable) public tokenCreators;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address coin,
        address payable feeAccount,
        uint256 feeAmount,
        uint256 _maxMintLimit,
        uint256 _tokenRoyalties
    ) public initializer {
        _name = name;
        _symbol = symbol;
        _setBaseURI(baseUri);
        maxMintLimit = _maxMintLimit;
        feeERC20Address = coin;
        quoteErc20 = IERC20(coin);
        mintFeeAddr = feeAccount;
        mintFeeAmount = feeAmount;
        nextTokenId = 1;
        tokenRoyalties = _tokenRoyalties;
        owner = _msgSender();
    }

    receive() external payable {}

    function mint(bytes32[] memory merkleProof) public payable {
        require(
            maxMintLimit == 0 || nextTokenId <= maxMintLimit,
            "max mint limit has been reached"
        );
        uint256 whiteListPrice = IArtaNFTFactory(owner).beforeMint(_msgSender(), merkleProof);
        uint256 feeAmount = whiteListPrice == 0 ? mintFeeAmount : whiteListPrice;

        if (feeERC20Address == address(0)) {
            require(msg.value >= feeAmount, "msg value too low");
            mintFeeAddr.transfer(feeAmount);
            _msgSender().transfer(msg.value - feeAmount);
        } else {
            if (feeAmount != 0) {
                quoteErc20 = IERC20(feeERC20Address);
                require(
                    quoteErc20.balanceOf(_msgSender()) >= feeAmount,
                    "your price is too low"
                );
                quoteErc20.transferFrom(
                    _msgSender(),
                    mintFeeAddr,
                    feeAmount
                );
            }
        }

        uint256 tokenId = nextTokenId;
        _mint(_msgSender(), tokenId);
        tokenCreators[tokenId] = _msgSender();
        nextTokenId++;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

        // override approve 
    function approve(address to, uint256 tokenId) public virtual override {
        IArtaNFTFactory(owner).checkBlacklistMarketplaces(to);
        super.approve(to, tokenId);
    }

    // override setApprovalForAll 
    function setApprovalForAll(address operator, bool approved) public virtual override {
        IArtaNFTFactory(owner).checkBlacklistMarketplaces(operator);
        super.setApprovalForAll(operator, approved);
    }
}
