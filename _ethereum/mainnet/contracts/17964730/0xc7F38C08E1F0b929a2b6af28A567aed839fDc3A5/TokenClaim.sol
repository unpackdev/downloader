// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

import "./IERC20.sol";

contract TokenClaim is AccessControl, ReentrancyGuard {
    error InvalidMerkleRoot();
    error ZeroAddress();
    error InvalidAmount();
    error InvalidProof();
    error AlreadyClaimed();
    error ClaimDisabled();

    enum ClaimAsset {
        ETH,
        PETH,
        JPEG,
        PETH_ETH,
        JPEG_PETH
    }

    struct ClaimData {
        bool ethClaimed;
        bool pethClaimed;
        bool jpegClaimed;
        bool pethEthClaimed;
        bool jpegPethClaimed;
    }

    struct ClaimArguments {
        ClaimAsset asset;
        bytes32[] proof;
        uint256 amount;
    }

    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    bytes32 public immutable ETH_ROOT;
    bytes32 public immutable PETH_ROOT;
    bytes32 public immutable JPEG_ROOT;
    bytes32 public immutable PETH_ETH_ROOT;
    bytes32 public immutable JPEG_PETH_ROOT;

    IERC20 public immutable PETH;
    IERC20 public immutable JPEG;

    uint256 public immutable EXPECTED_PETH_ETH_AMOUNT;
    uint256 public immutable EXPECTED_JPEG_PETH_AMOUNT;

    IERC20 public pethEthLpToken;
    IERC20 public jpegPethLpToken;

    uint256 public receivedPethEthAmount;
    uint256 public receivedJpegPethAmount;

    mapping(address => ClaimData) public claimData;

    constructor(
        bytes32 _ethRoot, 
        bytes32 _pethRoot, 
        bytes32 _jpegRoot, 
        bytes32 _pethEthRoot, 
        bytes32 _jpegPethRoot, 
        address _peth,
        address _jpeg,
        uint256 _expectedPethEthAmount, 
        uint256 _expectedJpegPethAmount
    ) {
        if (
            _ethRoot == bytes32(0) || 
            _pethRoot == bytes32(0) || 
            _jpegRoot == bytes32(0) || 
            _pethEthRoot == bytes32(0) || 
            _jpegPethRoot == bytes32(0)
        )
        if (_peth == address(0) || _jpeg == address(0))
            revert ZeroAddress();

        if (_expectedPethEthAmount == 0 || _expectedJpegPethAmount == 0)
            revert InvalidAmount();

        ETH_ROOT = _ethRoot;
        PETH_ROOT = _pethRoot;
        JPEG_ROOT = _jpegRoot;
        PETH_ETH_ROOT = _pethEthRoot;
        JPEG_PETH_ROOT = _jpegPethRoot;

        PETH = IERC20(_peth);
        JPEG = IERC20(_jpeg);
        EXPECTED_PETH_ETH_AMOUNT = _expectedPethEthAmount;
        EXPECTED_JPEG_PETH_AMOUNT = _expectedJpegPethAmount;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

    function claim(ClaimArguments[] calldata _args) external nonReentrant {
        uint256 _length = _args.length;
        if (_length == 0)
            revert();

        uint256 _receivedPethEthAmount = receivedPethEthAmount;
        if (_receivedPethEthAmount == 0)
            revert ClaimDisabled();

        ClaimData memory _data = claimData[msg.sender];
        for (uint256 i; i < _length; ++i) {
            ClaimArguments memory _curr = _args[i];
            
            if (_curr.asset == ClaimAsset.ETH) {
                if (_data.ethClaimed)
                    revert AlreadyClaimed();
                
                _verifyProof(ETH_ROOT, _curr.proof, msg.sender, _curr.amount);
                _data.ethClaimed = true;
                (bool _sent,) = msg.sender.call{value: _curr.amount}("");
                if (!_sent)
                    revert();
            } else if (_curr.asset == ClaimAsset.PETH) {
                if (_data.pethClaimed)
                    revert AlreadyClaimed();

                _verifyProof(PETH_ROOT, _curr.proof, msg.sender, _curr.amount);
                _data.pethClaimed = true;
                PETH.transfer(msg.sender, _curr.amount);
            } else if (_curr.asset == ClaimAsset.JPEG) {
                if (_data.jpegClaimed)
                    revert AlreadyClaimed();

                _verifyProof(JPEG_ROOT, _curr.proof, msg.sender, _curr.amount);
                _data.jpegClaimed = true;
                JPEG.transfer(msg.sender, _curr.amount);
            } else if (_curr.asset == ClaimAsset.PETH_ETH) {
                if (_data.pethEthClaimed)
                    revert AlreadyClaimed();

                _verifyProof(PETH_ETH_ROOT, _curr.proof, msg.sender, _curr.amount);
                _data.pethEthClaimed = true;
                pethEthLpToken.transfer(msg.sender, _normalizeClaimAmount(EXPECTED_PETH_ETH_AMOUNT, receivedPethEthAmount, _curr.amount));
            } else if (_curr.asset == ClaimAsset.JPEG_PETH) {
                if (_data.jpegPethClaimed)
                    revert AlreadyClaimed();

                _verifyProof(JPEG_PETH_ROOT, _curr.proof, msg.sender, _curr.amount);
                _data.jpegPethClaimed = true;
                jpegPethLpToken.transfer(msg.sender, _normalizeClaimAmount(EXPECTED_JPEG_PETH_AMOUNT, receivedJpegPethAmount, _curr.amount));
            } else
                revert();
        }

        claimData[msg.sender] = _data;
    }

    function enableClaim(IERC20 _pethEthLpToken, IERC20 _jpegPethLpToken) external onlyRole(DEPLOYER_ROLE) {
        if (address(pethEthLpToken) != address(0))
            revert();

        if (address(_pethEthLpToken) == address(0) || address(_jpegPethLpToken) == address(0))
            revert ZeroAddress();

        uint256 _pethEthAmount = _pethEthLpToken.balanceOf(address(this));
        uint256 _jpegPethAmount = _jpegPethLpToken.balanceOf(address(this));
        if (EXPECTED_PETH_ETH_AMOUNT > _pethEthAmount || EXPECTED_JPEG_PETH_AMOUNT > _jpegPethAmount)
            revert InvalidAmount();

        pethEthLpToken = _pethEthLpToken;
        jpegPethLpToken = _jpegPethLpToken;

        receivedPethEthAmount = _pethEthAmount;
        receivedJpegPethAmount = _jpegPethAmount;
    }

    function withdrawETH(address _recipient, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool _sent,) = _recipient.call{value: _amount}("");
        if (!_sent)
            revert();
    }

    function withdrawToken(IERC20 _token, address _recipient, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _token.transfer(_recipient, _amount);
    }

    function _normalizeClaimAmount(uint256 _expectedSupply, uint256 _actualSupply, uint256 _claimAmount) internal pure returns (uint256) {
        return _claimAmount * _actualSupply / _expectedSupply;
    }
    
    function _verifyProof(bytes32 _root, bytes32[] memory _merkleProof, address _account, uint256 _amount) internal pure {
        bytes32 _leaf = keccak256(abi.encodePacked(_account, _amount));
        if (!MerkleProof.verify(_merkleProof, _root, _leaf))
            revert InvalidProof();
    }
}