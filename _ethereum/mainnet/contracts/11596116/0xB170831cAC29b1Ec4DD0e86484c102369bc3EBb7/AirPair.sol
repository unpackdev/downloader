pragma solidity ^0.6.0;

import "./SafeMath.sol";

// ERC721
import "./IERC721Receiver.sol";
import "./IERC721.sol";

// ERC1155
import "./ERC1155Receiver.sol";
import "./IERC1155.sol";

import "./console.sol";

import "./ERC20.sol";

import "./EnumerableSet.sol";

contract AirPair is ERC20, IERC721Receiver, ERC1155Receiver {
    using SafeMath for uint256;

    address public factory;
    address public nftAddress;
    uint256 public nftType;
    uint256 public nftValue = 100 * 10**18;

    uint256 public fee = 5;

    mapping(uint256 => uint256) public track1155;

    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet lockedNfts;

    // example
    address public DAO = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    // create new token
    constructor() public {
        factory = msg.sender;
    }

    function init(
        string memory name,
        string memory symbol,
        address _nftAddress,
        uint256 _nftType
    ) public {
        super.init(name, symbol);
        nftAddress = _nftAddress;
        nftType = _nftType;
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
        if (nftType == 1155) {
            if (_tokenIds.length == 1) {
                burn(nftValue.mul(amounts[0]));
                _withdraw1155(
                    address(this),
                    msg.sender,
                    _tokenIds[0],
                    amounts[0]
                );
            } else {
                _batchWithdraw1155(
                    address(this),
                    msg.sender,
                    _tokenIds,
                    amounts
                );
            }
        } else if (nftType == 721) {
            burn(nftValue.mul(_tokenIds.length));
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _withdraw721(address(this), msg.sender, _tokenIds[i]);
            }
        }
    }

    function _withdraw1155(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 value
    ) internal {
        console.log("token id", value);
        track1155[_tokenId] = track1155[_tokenId].sub(value);
        if (track1155[_tokenId] == 0) {
            lockedNfts.remove(_tokenId);
        }
        IERC1155(nftAddress).safeTransferFrom(_from, _to, _tokenId, value, "");
    }

    function _batchWithdraw1155(
        address _from,
        address _to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 qty = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            track1155[ids[i]] = track1155[ids[i]].sub(amounts[i]);
            if (track1155[ids[i]] == 0) {
                lockedNfts.remove(ids[i]);
            }
            qty = qty + amounts[i];
        }
        // burn tokens
        burn(nftValue.mul(ids.length.add(qty)));

        IERC1155(nftAddress).safeBatchTransferFrom(
            _from,
            _to,
            ids,
            amounts,
            "0x0"
        );
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
        require(nftType == 721, "forbidden");
        require(nftAddress == msg.sender, "forbidden");
        require(!lockedNfts.contains(tokenId), "forbidden");
        require(
            IERC721(nftAddress).ownerOf(tokenId) == address(this),
            "forbidden"
        );

        console.log("token id", tokenId);
        console.log("operaor", operator);

        lockedNfts.add(tokenId);
        _mint(DAO, nftValue.mul(fee).div(100));
        _mint(operator, nftValue.mul(uint256(100).sub(fee)).div(100));
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256 value,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(nftType == 1155, "forbidden");
        require(nftAddress == msg.sender, "forbidden");
        require(
            IERC1155(nftAddress).balanceOf(address(this), id) >= value,
            "forbidden"
        );

        if (!lockedNfts.contains(id)) {
            lockedNfts.add(id);
        }

        track1155[id] = track1155[id].add(value);

        _mint(DAO, (nftValue.mul(value)).mul(fee).div(100));
        _mint(
            operator,
            (nftValue.mul(value)).mul(uint256(100).sub(fee)).div(100)
        );
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(nftType == 1155, "forbidden");
        require(nftAddress == msg.sender, "forbidden");

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                IERC1155(nftAddress).balanceOf(address(this), ids[i]) >=
                    values[i],
                "forbidden"
            );

            if (!lockedNfts.contains(ids[i])) {
                lockedNfts.add(ids[i]);
            }

            track1155[ids[i]] = track1155[ids[i]].add(values[i]);
            _mint(
                operator,
                (nftValue.mul(values[i])).mul(uint256(100).sub(fee)).div(100)
            );
        }

        // maybe on multiple batch set custom fee to save on gas.
        _mint(DAO, 20 * 10**18);

        return this.onERC1155BatchReceived.selector;
    }

    // set new price
    function setParams(
        uint256 _nftType,
        uint256 _nftValue,
        uint256 _fee,
        string memory name,
        string memory symbol
    ) public {
        require(msg.sender == factory, "!authorized");
        nftType = _nftType;
        nftValue = _nftValue;
        fee = _fee;
        _name = name;
        _symbol = symbol;
    }
}
