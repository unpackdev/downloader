// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IMOPN.sol";
import "./IMOPNToken.sol";
import "./IMOPNBomb.sol";
import "./CollectionVaultBytecodeLib.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Multicall.sol";
import "./Create2.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/
contract MOPNGovernance is Multicall, Ownable {
    event CollectionVaultCreated(
        address indexed collectionAddress,
        address indexed collectionVault
    );

    uint256 public vaultIndex;

    /// uint160 vaultAdderss + uint96 vaultIndex
    mapping(address => uint256) public CollectionVaults;

    address public mopnContract;
    address public bombContract;
    address public tokenContract;
    address public pointContract;
    address public landContract;
    address public dataContract;
    address public collectionVaultContract;
    address public auctionHouseContract;

    address public ERC6551Registry;
    address public ERC6551AccountProxy;
    address public ERC6551AccountHelper;

    modifier onlyMOPN() {
        require(msg.sender == mopnContract, "not allowed");
        _;
    }

    modifier onlyCollectionVault(address collectionAddress) {
        require(
            msg.sender == getCollectionVault(collectionAddress),
            "only collection vault allowed"
        );
        _;
    }

    function updateERC6551Contract(
        address ERC6551Registry_,
        address ERC6551AccountProxy_,
        address ERC6551AccountHelper_
    ) public onlyOwner {
        ERC6551Registry = ERC6551Registry_;
        ERC6551AccountProxy = ERC6551AccountProxy_;
        ERC6551AccountHelper = ERC6551AccountHelper_;
    }

    function updateMOPNContracts(
        address auctionHouseContract_,
        address mopnContract_,
        address bombContract_,
        address tokenContract_,
        address pointContract_,
        address landContract_,
        address dataContract_,
        address collectionVaultContract_
    ) public onlyOwner {
        auctionHouseContract = auctionHouseContract_;
        mopnContract = mopnContract_;
        bombContract = bombContract_;
        tokenContract = tokenContract_;
        pointContract = pointContract_;
        landContract = landContract_;
        dataContract = dataContract_;
        collectionVaultContract = collectionVaultContract_;
    }

    function createCollectionVault(
        address collectionAddress
    ) public returns (address) {
        require(
            CollectionVaults[collectionAddress] == 0,
            "collection vault exist"
        );

        address vaultAddress = _createCollectionVault(collectionAddress);
        CollectionVaults[collectionAddress] =
            (uint256(uint160(vaultAddress)) << 96) |
            vaultIndex;
        emit CollectionVaultCreated(collectionAddress, vaultAddress);
        vaultIndex++;
        return vaultAddress;
    }

    function _createCollectionVault(
        address collectionAddress
    ) internal returns (address) {
        bytes memory code = CollectionVaultBytecodeLib.getCreationCode(
            collectionVaultContract,
            collectionAddress,
            0
        );

        address _account = Create2.computeAddress(bytes32(0), keccak256(code));

        if (_account.code.length != 0) return _account;

        _account = Create2.deploy(0, bytes32(0), code);
        return _account;
    }

    function getCollectionVault(
        address collectionAddress
    ) public view returns (address) {
        return address(uint160(CollectionVaults[collectionAddress] >> 96));
    }

    function getCollectionVaultIndex(
        address collectionAddress
    ) public view returns (uint256) {
        return uint96(CollectionVaults[collectionAddress]);
    }

    function computeCollectionVault(
        address collectionAddress
    ) public view returns (address) {
        bytes memory code = CollectionVaultBytecodeLib.getCreationCode(
            collectionVaultContract,
            collectionAddress,
            0
        );

        return Create2.computeAddress(bytes32(0), keccak256(code));
    }
}
