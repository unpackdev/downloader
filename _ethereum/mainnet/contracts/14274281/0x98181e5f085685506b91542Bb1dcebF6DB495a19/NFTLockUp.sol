//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IPilgrimCore.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";

contract NFTLockUp is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    address public pilgrimCore;
    address public pilgrimToken;
    address public pilgrimMetaNft;

    mapping(address => EnumerableSet.AddressSet) private lockedNFTs;
    mapping(address => mapping(address => EnumerableSet.UintSet)) private lockedTokens;

    bool public lockActivated = true;
    uint128 public initPrice = 1 ether;

    event Lock(address _owner, address _nFTAddress, uint256 _tokenId);

    event Withdraw(address _owner, address _nFTAddress, uint256 _tokenId);

    event Migrate(address _owner, address _nFTAddress, uint256 _tokenId);

    modifier onlyTokenOwner(address _nFTAddress, uint256 _tokenId) {
        require(EnumerableSet.contains(lockedTokens[msg.sender][_nFTAddress], _tokenId), "Not token owner");
        _;
    }

    function getLockedNFTs(address _owner) external view returns (address[] memory _tokenIds) {
        _tokenIds = EnumerableSet.values(lockedNFTs[_owner]);
    }

    function getLockedTokens(address _owner, address _nFTAddress) external view returns (uint256[] memory _tokenIds) {
        _tokenIds = EnumerableSet.values(lockedTokens[_owner][_nFTAddress]);
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

    function lock(address _nFTAddress, uint256 _tokenId) external {
        require(lockActivated, "Deactivated");

        IERC721(_nFTAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        EnumerableSet.add(lockedTokens[msg.sender][_nFTAddress], _tokenId);
        EnumerableSet.add(lockedNFTs[msg.sender], _nFTAddress);

        emit Lock(msg.sender, _nFTAddress, _tokenId);
    }

    function withdraw(address _nFTAddress, uint256 _tokenId) external onlyTokenOwner(_nFTAddress, _tokenId) {
        IERC721(_nFTAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

        EnumerableSet.remove(lockedTokens[msg.sender][_nFTAddress], _tokenId);
        EnumerableSet.remove(lockedNFTs[msg.sender], _nFTAddress);

        emit Withdraw(msg.sender, _nFTAddress, _tokenId);
    }

    function migrate(
        address _nFTAddress,
        uint256 _tokenId,
        bytes32 _descriptionHash,
        string[] calldata _tags
    ) external onlyTokenOwner(_nFTAddress, _tokenId) {
        require(pilgrimCore != address(0), "Pilgrim address must be set");

        IERC721(_nFTAddress).approve(pilgrimCore, _tokenId);

        IPilgrimCore(pilgrimCore).list(
            _nFTAddress,
            _tokenId,
            initPrice,
            pilgrimToken,
            _tags,
            _descriptionHash
        );

        uint256 metaNftId = IPilgrimCore(pilgrimCore).getMetaNftId(_nFTAddress, _tokenId);
        IERC721(pilgrimMetaNft).safeTransferFrom(address(this), msg.sender, metaNftId);

        EnumerableSet.remove(lockedTokens[msg.sender][_nFTAddress], _tokenId);
        EnumerableSet.remove(lockedNFTs[msg.sender], _nFTAddress);

        emit Migrate(msg.sender, _nFTAddress, _tokenId);
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
