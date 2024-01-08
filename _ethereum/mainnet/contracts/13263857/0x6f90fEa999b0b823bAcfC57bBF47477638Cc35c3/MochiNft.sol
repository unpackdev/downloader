// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IMochiNFT.sol";
import "./IMochiEngine.sol";
import "./IMochiPositionDescriptor.sol";

contract MochiPositionNFT is IMochiNFT, ERC721Enumerable {
    IMochiEngine public immutable engine;
    address public descriptor;

    mapping(uint256 => MochiInfo) public info;

    constructor(address _engine) ERC721("MochiNFTPositionNFT", "MOCHI-NFT-POS") {
        engine = IMochiEngine(_engine);
    }

    function setDescriptor(address _descriptor) external {
        require(msg.sender == engine.governance(), "!governance");
        descriptor = _descriptor;
    }

    function mint(address _asset, address _owner)
        external
        override
        returns (uint256 id)
    {
        require(
            msg.sender == address(engine.vaultFactory().getVault(_asset)),
            "!vault"
        );
        id = totalSupply();
        _mint(_owner, id);
        info[id].asset = _asset;
    }

    function asset(uint256 _id) external view override returns (address) {
        return info[_id].asset;
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        if (descriptor == address(0)) {
            return "";
        } else {
            return
                IMochiPositionDescriptor(descriptor).getTokenURI(
                    address(this),
                    _id
                );
        }
    }
}
