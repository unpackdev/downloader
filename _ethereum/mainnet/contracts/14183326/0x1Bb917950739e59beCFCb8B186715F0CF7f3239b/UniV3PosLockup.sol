//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IPilgrimCore.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";

import "./console.sol";

contract UniV3PosLockup is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public pilgrimCore;
    address public pilgrimToken;
    address public pilgrimMetaNft;
    address public uniV3Pos;
    mapping(address => EnumerableSet.UintSet) private lockedTokens;
    uint256 private lastMetaNftId;
    bool public lockActivated;
    uint128 public initPrice;

    constructor(address _uniV3Pos) {
        uniV3Pos = _uniV3Pos;
        lockActivated = true;
        initPrice = 1 ether;
    }

    event Lock(address _owner, uint256 tokenId);
    event Withdraw(address _owner, uint256 tokenId);
    event Migrate(address _owner, uint256 tokenId);

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(EnumerableSet.contains(lockedTokens[msg.sender], _tokenId), "Not token owner");
        _;
    }

    function getLockedTokens(address _owner) external view returns (uint256[] memory _tokenIds) {
        _tokenIds = EnumerableSet.values(lockedTokens[_owner]);
    }

    function setPilgrimAddrs(address _pilgrimCore, address _pilgrimToken, address _pilgrimMetaNft) external onlyOwner {
        pilgrimCore = _pilgrimCore;
        pilgrimToken = _pilgrimToken;
        pilgrimMetaNft = _pilgrimMetaNft;
    }

    function setInitPrice(uint128 _initPrice) external onlyOwner {
        initPrice = _initPrice;
    }

    function activate() external onlyOwner {
        lockActivated = true;
    }

    function deactivate() external onlyOwner {
        lockActivated = false;
    }

    function lock(uint256 _tokenId) external {
        require(lockActivated, "Deactivated");
        IERC721(uniV3Pos).safeTransferFrom(msg.sender, address(this), _tokenId);
        EnumerableSet.add(lockedTokens[msg.sender], _tokenId);
        emit Lock(msg.sender, _tokenId);
    }

    function withdraw(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        IERC721(uniV3Pos).safeTransferFrom(address(this), msg.sender, _tokenId);
        EnumerableSet.remove(lockedTokens[msg.sender], _tokenId);
        emit Withdraw(msg.sender, _tokenId);
    }

    function migrate(
        uint256 _tokenId,
        bytes32 _descriptionHash,
        string[] calldata _tags
    ) external onlyTokenOwner(_tokenId) {
        require(pilgrimCore != address(0), "Pilgrim address must be set");
        IERC721(uniV3Pos).approve(pilgrimCore, _tokenId);
        IPilgrimCore(pilgrimCore).list(
            uniV3Pos,
            _tokenId,
            initPrice,
            pilgrimToken,
            _tags,
            _descriptionHash
        );
        uint256 metaNftId = IPilgrimCore(pilgrimCore).getMetaNftId(uniV3Pos, _tokenId);
        IERC721(pilgrimMetaNft).safeTransferFrom(address(this), msg.sender, metaNftId);
        EnumerableSet.remove(lockedTokens[msg.sender], _tokenId);
        emit Migrate(msg.sender, _tokenId);
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
