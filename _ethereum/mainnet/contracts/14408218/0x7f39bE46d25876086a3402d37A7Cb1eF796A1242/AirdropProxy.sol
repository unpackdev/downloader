//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IPilgrimCore.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract AirdropProxy is IPilgrimCore, Ownable {

    struct _Claimable {
        address _to;
        address _nft;
        uint256 _tokenId;
        bytes32[] _params;
    }

    struct _Droppable {
        address _to;
        address _nft;
        uint256 _tokenId;
        uint256 _amount;
        bytes32[] _params;
    }

    address public pilgrimCore;
    address public pilgrimToken;
    address public pilgrimMetaNft;

    address public uniLockup;
    address public nftLockup;

    mapping(bytes32 => uint256) public claims;

    mapping(address => mapping(address => mapping(uint256 => uint128))) prelisted;

    event Claim(address indexed _to, address indexed _nft, uint256 _tokenId, bytes32[] _params);

    event Drop(address indexed _to, address indexed _nft, uint256 _tokenId, uint256 _amount, bytes32[] _params);

    event ProxyList(address indexed owner, address indexed _nft, uint256 _tokenId);

    event Prelist(address indexed owner, address indexed _nft, uint256 _tokenId, uint128 _initPrice);

    function setPilgrimAddrs(address _pilgrimCore, address _pilgrimToken, address _pilgrimMetaNft) external onlyOwner {
        pilgrimCore = _pilgrimCore;
        pilgrimToken = _pilgrimToken;
        pilgrimMetaNft = _pilgrimMetaNft;
    }

    function setLockupAddrs(address _uniLockup, address _nftLockup) external onlyOwner {
        uniLockup = _uniLockup;
        nftLockup = _nftLockup;
    }

    function _claimKey(_Claimable memory _claimable) private view returns (bytes32 _key) {
        bytes memory data = abi.encodePacked(_claimable._to, _claimable._nft, _claimable._tokenId);
        for(uint256 j = 0; j < _claimable._params.length; j++) {
            data = abi.encodePacked(data, _claimable._params[j]);
        }
        _key = keccak256(data);
    }

    function _dropKey(_Droppable calldata _droppable) private view returns (bytes32 _key) {
        bytes memory data = abi.encodePacked(_droppable._to, _droppable._nft, _droppable._tokenId);
        for(uint256 j = 0; j < _droppable._params.length; j++) {
            data = abi.encodePacked(data, _droppable._params[j]);
        }
        _key = keccak256(data);
    }

    function _claim(bytes32 _key, _Claimable memory _claimable) private {
        require(claims[_key] > 0, "No claims avaialble");
        uint256 amount = claims[_key];
        claims[_key] = 0;
        require(IERC20(pilgrimToken).transfer(_claimable._to, amount), "Can't transfer PILs");

        emit Claim(_claimable._to, _claimable._nft, _claimable._tokenId, _claimable._params);
    }

    function drop(_Droppable[] calldata droppables) external onlyOwner {
        for(uint256 i = 0; i < droppables.length; i++) {
            require(droppables[i]._amount > 0, "Can't drop zero PIL");

            bytes32 key = _dropKey(droppables[i]);
            claims[key] += droppables[i]._amount;

            emit Drop(droppables[i]._to, droppables[i]._nft, droppables[i]._tokenId, droppables[i]._amount, droppables[i]._params);
        }
    }

    function getAirdropAmount(_Claimable calldata _claimable) external view returns (uint256 _amount) {
        bytes32 key = _claimKey(_claimable);
        _amount = claims[key];
    }

    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint128 _initPrice,
        address _baseToken,
        string[] calldata _tags,
        bytes32 _descriptionHash
    ) external override {
        require(msg.sender == nftLockup || msg.sender == uniLockup, "Caller must be lockup contract");
        require(pilgrimCore != address(0), "Pilgrim address must be set");

        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        IERC721(_nftAddress).approve(pilgrimCore, _tokenId);

        address to = tx.origin;
        uint128 initPrice = prelisted[to][_nftAddress][_tokenId];
        require(initPrice > 0, "Must set listing price");

        IPilgrimCore(pilgrimCore).list(
            _nftAddress,
            _tokenId,
            initPrice,
            _baseToken,
            _tags,
            _descriptionHash
        );

        uint256 metaNftId = IPilgrimCore(pilgrimCore).getMetaNftId(_nftAddress, _tokenId);
        IERC721(pilgrimMetaNft).safeTransferFrom(address(this), msg.sender, metaNftId);

        emit ProxyList(to, _nftAddress, _tokenId);

        bytes32[] memory params;
        _Claimable memory claimable = _Claimable(to, _nftAddress, _tokenId, params);
        bytes32 key = _claimKey(claimable);
        if (claims[key] > 0) {
            _claim(key, claimable);
        }
    }

    function prelistWithInitPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint128 _initPrice
    ) external {
        prelisted[msg.sender][_nftAddress][_tokenId] = _initPrice;
        emit Prelist(msg.sender, _nftAddress, _tokenId, _initPrice);
    }

    function getMetaNftId(address _nftAddress, uint256 _tokenId) external view override returns (uint256 _metaNftId) {
        _metaNftId = IPilgrimCore(pilgrimCore).getMetaNftId(_nftAddress, _tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 amount = IERC20(pilgrimToken).balanceOf(address(this));
        IERC20(pilgrimToken).transfer(msg.sender, amount);
    }

    function onERC721Received(
    /* solhint-disable no-unused-vars */
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    /* solhint-enable no-unused-vars */
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
