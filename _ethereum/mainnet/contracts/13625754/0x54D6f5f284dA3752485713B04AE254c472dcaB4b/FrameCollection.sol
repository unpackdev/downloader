//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ERC165.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./GatewayHandler.sol";
import "./IERC165.sol";
import "./IFrameCollection.sol";
import "./IGatewayHandler.sol";

abstract contract FrameCollection is IFrameCollection, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant IPFS_GATEWAY_KEY = keccak256("IPFS_GATEWAY");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IGatewayHandler public gatewayHandler;

    // frameId => Frame
    mapping(uint256 => Frame) private _frameOf;

    EnumerableSet.UintSet private _frameIds;
    uint256 private _nextFrameId = 0;

    constructor(IGatewayHandler gatewayHandler_) {
        gatewayHandler = gatewayHandler_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function registerFrame(string calldata ipfsHash_, uint256 zIndex_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _frameOf[_nextFrameId] = Frame(zIndex_, ipfsHash_);
        _frameIds.add(_nextFrameId);
        _nextFrameId += 1;
    }

    function removeFrame(uint256 frameId_) external onlyRole(OPERATOR_ROLE) {
        require(
            _frameIds.contains(frameId_),
            "FrameCollection: Unregistered frame"
        );
        _frameIds.remove(frameId_);
        delete _frameOf[frameId_];
    }

    function frameOf(uint256 frameId_)
        public
        view
        override
        returns (FrameWithUri memory)
    {
        FrameWithUri memory frame = FrameWithUri(
            frameId_,
            _frameOf[frameId_].ipfsHash,
            string(
                abi.encodePacked(
                    gatewayHandler.gateways(IPFS_GATEWAY_KEY),
                    "/",
                    _frameOf[frameId_].ipfsHash
                )
            ),
            _frameOf[frameId_].zIndex
        );
        return frame;
    }

    function getAllFrames()
        external
        view
        override
        returns (FrameWithUri[] memory)
    {
        uint256 amountOfFrames = _frameIds.length();
        FrameWithUri[] memory frames = new FrameWithUri[](amountOfFrames);

        for (uint256 i = 0; i < amountOfFrames; i += 1) {
            uint256 frameId = _frameIds.at(i);
            frames[i] = frameOf(frameId);
        }

        return frames;
    }

    function totalFrames() external view override returns (uint256) {
        return _frameIds.length();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IFrameCollection).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
