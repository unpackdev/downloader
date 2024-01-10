// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface SSSInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ArtifactsInterface {
    function mintTo(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}

contract ATFMinter is Ownable {
    using SafeMath for uint256;
    address private _manager = 0xf5383b4e0d3EDDA3B6c091e51AbE58F882c98ce3;

    uint256 private constant MAX_CLAIMED = 11110;
    SSSInterface sssContract;
    ArtifactsInterface artifactsContract;
    bool public saleIsActive = false;
    uint256 public claimedSupply = 0;
    mapping(uint256 => bool) public sssClaimed;
    uint256 private constant ARTIFACT_ID = 1;

    constructor(address sssAddress, address artifactsAddress) {
        sssContract = SSSInterface(sssAddress);
        artifactsContract = ArtifactsInterface(artifactsAddress);
    }

    receive() external payable {}

    modifier onlyOwnerOrManager() {
        require(
            owner() == _msgSender() || _manager == _msgSender(),
            "Caller not the owner or manager"
        );
        _;
    }

    function flipSaleState() external onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function setManager(address manager) external onlyOwnerOrManager {
        _manager = manager;
    }

    function claim(uint256 sssId) external {
        require(saleIsActive, "sale not live");
        require(!sssClaimed[sssId], "token already claimed");
        require(
            sssContract.ownerOf(sssId) == msg.sender,
            "not the owner of token"
        );
        claimedSupply++;
        sssClaimed[sssId] = true;
        artifactsContract.mintTo(msg.sender, ARTIFACT_ID, 1);
    }

    function claimMulti(uint256[] calldata sssIds) external {
        require(saleIsActive, "sale not live");
        uint256 amount = sssIds.length;
        for (uint256 i = 0; i < amount; i++) {
            require(!sssClaimed[sssIds[i]], "token already claimed");
            require(
                sssContract.ownerOf(sssIds[i]) == msg.sender,
                "not the owner of token"
            );
            sssClaimed[sssIds[i]] = true;
        }
        claimedSupply += amount;
        artifactsContract.mintTo(msg.sender, ARTIFACT_ID, amount);
    }

    function claimLeftovers(address to, uint256 amount)
        external
        onlyOwnerOrManager
    {
        require(claimedSupply + amount <= MAX_CLAIMED, "not enough left");
        claimedSupply += amount;
        artifactsContract.mintTo(to, ARTIFACT_ID, amount);
    }
}
