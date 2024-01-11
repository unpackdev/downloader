// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";

contract VersionTracker is Ownable {

    struct Version {
        uint16 major;
        uint16 minor;
        address coreLocation;
        address registrarLocation;
        address resolverLocation;
    }

    enum ContractType { CORE, REGISTRAR, RESOLVER }

    Version[] coreVersions;

    function updateMajor(address coreContract, address registrarContract, address resolverContract) external onlyOwner returns(Version memory){
        require(coreContract != address(0));
        require(registrarContract != address(0));
        require(resolverContract != address(0));
        Version memory nextMajor;
        if (coreVersions.length == 0){
            nextMajor = Version(0, 0, coreContract, registrarContract, resolverContract);
        } else {
            Version memory currentVersion = getCurrentVersion();
            nextMajor = Version(currentVersion.major + 1, 0, coreContract, registrarContract, resolverContract);
        }
        return storeVersion(nextMajor);
    }

    function updateMinor(address coreContract, address registrarContract, address resolverContract) external onlyOwner returns(Version memory) {
        require(coreContract != address(0));
        require(registrarContract != address(0));
        require(resolverContract != address(0));
        Version memory nextMinor;
        if (coreVersions.length == 0){
            nextMinor = Version(0, 0, coreContract, registrarContract, resolverContract);
        } else {
            Version memory currentVersion = getCurrentVersion();
            nextMinor = Version(currentVersion.major, currentVersion.minor+1, coreContract, registrarContract, resolverContract);
        }
        return storeVersion(nextMinor);
    }

    function getPhotochromicCore() external view returns (address){
        if (coreVersions.length == 0) revert();
        return getCurrentVersion().coreLocation;
    }

    function getPhotochromicCore(uint major) external view returns (address){
        (Version memory version, ) = findVersion(major);
        return version.coreLocation;
    }

    function getPhotochromicCore(uint major, uint minor) external view returns (address){
        (Version memory version, ) = findVersion(major, minor);
        return version.coreLocation;
    }

    function getVersionMajor() external view returns (uint) {
        return getCurrentVersion().major;
    }

    function getVersionMinor() external view returns (uint) {
        return getCurrentVersion().minor;
    }

    function getCurrentVersion() public view returns (Version memory){
        require(coreVersions.length > 0, "No version set");
        return coreVersions[coreVersions.length-1];
    }

    function getVersion(uint major) external view returns (Version memory version){
        (version, ) = findVersion(major);
        return version;
    }

    function getVersion(uint major, uint minor) external view returns(Version memory version){
        (version, ) = findVersion(major, minor);
        return version;
    }

    function getVersionForAddress(address contractAddress, ContractType contractType) external view returns (Version memory){
        Version memory v;
        for (uint i = coreVersions.length; i > 0; i--){
            v = coreVersions[i - 1];
            if (contractType == ContractType.CORE && v.coreLocation == contractAddress) return v;
            if (contractType == ContractType.REGISTRAR && v.registrarLocation == contractAddress) return v;
            if (contractType == ContractType.RESOLVER && v.resolverLocation == contractAddress) return v;
        }
        revert();
    }

    function findVersion(uint major) internal view returns (Version memory, uint) {
        for (uint i = coreVersions.length; i > 0; i--) {
            Version memory version = coreVersions[i - 1];
            if (version.major == major) return (version, i - 1);
        }
        revert();
    }

    function findVersion(uint major, uint minor) internal view returns (Version memory, uint){
        for (uint i = coreVersions.length; i > 0; i--) {
            Version memory version = coreVersions[i - 1];
            if ((version.major == major) && (version.minor == minor)) return (version, i - 1);
        }
        revert();
    }

    function storeVersion(Version memory version) internal returns(Version memory) {
        coreVersions.push(version);
        return getCurrentVersion();
    }
}
