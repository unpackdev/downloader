// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./RigNFT.sol";

contract RigToken is ERC20 {
    RigNFT rig;
    address nftAddress;
    uint startBlock;
    constructor(address _nftAddress) ERC20("RigToken", "RIG") {
        startBlock = block.timestamp;
        nftAddress = _nftAddress;
        rig = RigNFT(nftAddress);
    }
    struct Claim {
        bool allowsPublic;
        uint claimTimestamp;
    }
    mapping(uint => Claim) private claims;

    event PublicClaim (
        uint256 claimId,
        address claimingAddress
    );
    event OwnerClaim (
        uint256 claimId
    );
    event SetPublic (
        uint256 claimId
    );
    event SetPrivate (
        uint256 claimId
    );

    function initialOwnerClaim (uint256 id) public {
        require(msg.sender == rig.ownerOf(id), "only owner can claim tokens");
        //attempts to enforce a period between potential claims.
        require(block.timestamp >= claims[id].claimTimestamp + rig.periodOf(id), "not enough time has past since the last claim.");
        _mint(msg.sender, mintAmount(id));
        claims[id].allowsPublic = false;
        claims[id].claimTimestamp = block.timestamp;
        emit OwnerClaim(id);
    }

    function ownerClaim (uint256 id) public {
        require(msg.sender == rig.ownerOf(id), "only owner can claim tokens");
        //attempts to enforce a period between potential claims.
        require(block.timestamp >= claims[id].claimTimestamp + rig.periodOf(id), "not enough time has past since the last claim.");
        _mint(msg.sender, mintAmount(id));
        claims[id].claimTimestamp = block.timestamp;
        emit OwnerClaim(id);
    }

    function publicClaim (uint256 id) public {
        require(claims[id].allowsPublic, "only owner can claim tokens");
        //attempts to enforce a period between potential claims.
        require(block.timestamp >= claims[id].claimTimestamp + rig.periodOf(id), "not enough time has past since the last claim.");
        _mint(msg.sender, mintAmount(id));
        _mint(rig.ownerOf(id), 1);
        claims[id].claimTimestamp = block.timestamp;
        emit PublicClaim(id, msg.sender);
    }

    function setPublic(uint256 id) public {
        require(msg.sender == rig.ownerOf(id), "only owner can change settings");
        claims[id].allowsPublic = true;
        emit SetPublic(id);
    }
    function setPrivate(uint256 id) public {
        require(msg.sender == rig.ownerOf(id), "only owner can change settings");
        claims[id].allowsPublic = false;
        emit SetPrivate(id);
    }
    function isClaimable(uint256 id) public view returns (bool) {
        return block.timestamp >= claims[id].claimTimestamp + rig.periodOf(id) ? true : false;
    }
    function allowsPublic(uint256 id) public view returns (bool) {
        return claims[id].allowsPublic;
    }
    /*
    * @dev This could be unsafe, but seems to be the only reliable way to cheaply do this atm.
    * @dev Just need a minor decay to occur as time passes and this is an attempt to create that.
    *
    * @notice please read deeper into the following for more info.
    *
    * The current block timestamp must be strictly larger than the
    * timestamp of the last block, but the only guarantee is that
    * it will be somewhere between the timestamps of two consecutive
    * blocks in the canonical chain.
    *
    * https://docs.soliditylang.org/en/latest/units-and-global-variables.html?highlight=block.timestamp
    */

    function mintAmount(uint256 id) private view returns (uint) {
        return ((rig.powerOf(id) * startBlock) / block.timestamp * 10 ** 18);
    }
}
