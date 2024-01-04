pragma solidity ^0.6.0;

// ERC721
import "./IERC721Receiver.sol";
import "./IERC721.sol";

import "./ERC20.sol";

import "./EnumerableSet.sol";

interface IFactory {
    function fee() external view returns (uint256);
}

contract NFT20Pair721 is ERC20, IERC721Receiver {
    address public factory;
    address public nftAddress;
    uint256 public nftType;
    uint256 public nftValue;

    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet lockedNfts;

    event Withdraw(uint256[] indexed _tokenIds, uint256[] indexed amounts);

    // create new token
    constructor() public {}

    function initialize(
        string memory name,
        string memory symbol,
        address _nftAddress,
        uint256 _nftType
    ) public {
        factory = msg.sender;
        super.init(name, symbol);
        nftAddress = _nftAddress;
        nftType = _nftType;
        nftValue = 100 * 10**18;
    }

    function getInfos()
        public
        view
        returns (
            uint256 _type,
            string memory _name,
            string memory _symbol,
            uint256 _supply
        )
    {
        _type = nftType;
        _name = name();
        _symbol = symbol();
        _supply = totalSupply() / 100 ether;
    }

    // withdraw nft and burn tokens
    function withdraw(uint256[] calldata _tokenIds, uint256[] calldata amounts)
        external
    {
        burn(nftValue.mul(_tokenIds.length));
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _withdraw721(address(this), msg.sender, _tokenIds[i]);
        }

        emit Withdraw(_tokenIds, amounts);
    }

    function swap(uint256 _in, uint256 _out) external {
        lockedNfts.add(_in);
        lockedNfts.remove(_out);

        // requires user approval
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _in);

        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, _out);
    }

    function _withdraw721(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        lockedNfts.remove(_tokenId);
        IERC721(nftAddress).safeTransferFrom(_from, _to, _tokenId);
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(nftAddress == msg.sender, "forbidden");
        require(!lockedNfts.contains(tokenId), "forbidden");
        lockedNfts.add(tokenId);
        uint256 fee = IFactory(factory).fee();
        _mint(factory, nftValue.mul(fee).div(100));
        _mint(operator, nftValue.mul(uint256(100).sub(fee)).div(100));
        return this.onERC721Received.selector;
    }

    // set new price
    function setParams(
        uint256 _nftType,
        string calldata name,
        string calldata symbol
    ) external {
        require(msg.sender == factory, "!authorized");
        nftType = _nftType;
        _name = name;
        _symbol = symbol;
    }
}
