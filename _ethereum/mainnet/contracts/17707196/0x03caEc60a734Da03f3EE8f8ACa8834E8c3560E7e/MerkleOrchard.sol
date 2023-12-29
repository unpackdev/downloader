// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IMerkleOrchard.sol";

// solhint-disable-next-line
// Inpsired by https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/distributors/contracts/MerkleOrchard.sol

contract MerkleOrchard is ERC721Enumerable, IMerkleOrchard {
    using SafeERC20 for IERC20;
    string internal baseTokenURI;

    error MerkleProofError();
    error NotOwnerError();
    error NonExistentTokenError();
    error CallNotSuccessfulError();
    error ZeroFundingError();

    event MerkleRootUpdated(uint256 indexed channelId, bytes32 indexed merkleRoot, string indexed ipfsHash);
    event ChannelFunded(uint256 indexed channelId, address indexed token);
    event ChannelFundedWithETH(uint256 indexed channelId);
    event TokenClaimed(uint256 indexed channelId, address indexed receiver, address indexed token);

    struct Channel {
        mapping(address => uint256) reserves;
        // token => account => amount
        mapping(address => mapping(address => uint256)) withdraws;
        bytes32 merkleRoot;
    }

    mapping(uint256 => Channel) public channels;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
    }

    function openChannel() external {
        // One time use: staking rewards
        require(totalSupply() == 0, "No more mints");
        _mint(msg.sender, totalSupply());
    }

    // TODO support ETH
    function fundChannel(
        uint256 _channelId,
        address _token,
        uint256 _amount
    ) external {
        if (_channelId >= totalSupply()) {
            revert NonExistentTokenError();
        }

        if (_amount == 0) {
            revert ZeroFundingError();
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        channels[_channelId].reserves[_token] += _amount;
        emit ChannelFunded(_channelId, _token);
    }

    function getChannelReservesByToken(uint256 _channelId, address _token) public view returns (uint256) {
        return channels[_channelId].reserves[_token];
    }

    function fundChannelWithEth(uint256 _channelId) external payable {
        if (_channelId >= totalSupply()) {
            revert NonExistentTokenError();
        }

        if (msg.value == 0) {
            revert ZeroFundingError();
        }

        channels[_channelId].reserves[address(0)] += msg.value;
        emit ChannelFundedWithETH(_channelId);
    }

    function setMerkleRoot(
        uint256 _channelId,
        bytes32 _merkleRoot,
        string memory _ipfsHash
    ) external {
        if (ownerOf(_channelId) != msg.sender) {
            revert NotOwnerError();
        }

        channels[_channelId].merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_channelId, _merkleRoot, _ipfsHash);
    }

    function getMerkleRoot(uint256 _channelId) public view returns (bytes32) {
        return channels[_channelId].merkleRoot;
    }

    // @dev claim entire balance of channel
    function claim(
        uint256 _channelId,
        address _receiver,
        address _token,
        uint256 _cumulativeAmount,
        bytes32[] calldata _proof
    ) external {
        Channel storage channel = channels[_channelId];

        // Checks
        bytes32 leaf = keccak256(abi.encodePacked(_receiver, _token, _cumulativeAmount));
        if (!MerkleProof.verify(_proof, channel.merkleRoot, leaf)) {
            revert MerkleProofError();
        }

        // Effects
        uint256 withdrawnPreviously = channel.withdraws[_token][_receiver];
        uint256 withdrawAmount = _cumulativeAmount - withdrawnPreviously;
        channel.withdraws[_token][_receiver] = _cumulativeAmount;
        channel.reserves[_token] -= withdrawAmount;

        // Interactions
        // IF ETH
        if (_token == address(0)) {
            // solhint-disable-next-line
            (bool success, ) = payable(_receiver).call{ value: withdrawAmount }("");
            if (!success) {
                revert CallNotSuccessfulError();
            }
        } else {
            IERC20(_token).safeTransfer(_receiver, withdrawAmount);
        }
        emit TokenClaimed(_channelId, _receiver, _token);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice returns the baseURI
    /// @return The tokenURI
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function getUserWithdraws(uint256 channelId, address token, address account) public view returns(uint256) {
        Channel storage channel = channels[channelId];
        return channel.withdraws[token][account];
    }
}
