// File: contracts/upgradeable-Bridge/IronVestPreCheck.sol



pragma solidity 0.8.17;

/// @author The ferrum network.
/// @title This is a vesting contract named as IronVest.
/// @dev This contract is upgradeable please use a framework i.e truffle or hardhat for deploying it.
/// @notice This contract contains the power of accesscontrol.
/// There are two different vesting defined in the contract with different functionalities.
/// Have fun reading it. Hopefully it's bug-free. God Bless.
contract IronVestPreCheck {

    /// @dev Only callable by vester.
    /// @param _vestingEndTime : Vesting end time should be greater than current time.
    /// @param _usersAddresses : Length of _usersAddresses and _userAlloc must be equal.
    /// @param _userAlloc : Just for checking length.
    /// @notice it is a precheck for new vesting.
    function preAddVesting(
        uint256 _vestingEndTime,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc
    ) external view {
        require(
            _usersAddresses.length == _userAlloc.length,
            "IIronVest Array : Length of _usersAddresses And _userAlloc Must Be Equal"
        );
        require(
            _vestingEndTime > block.timestamp,
            "IIronVest : Vesting End Time Should Be Greater Than Current Time"
        );
    }

    /// @dev Only callable by vester.
    /// @param _vestingEndTime : Vesting time should be greater than _cliffVestingEndTime.
    /// @param _cliffVestingEndTime : Cliff vesting time must Be greater than cliff period.
    /// @param _cliffPeriodEndTime : cliff period should must be grater than block.timestamp .
    /// @param _cliffPercentage10000 : Cliff percentage should be less than 50%.
    /// @param _usersAddresses : Length of _usersAddresses and _userAlloc must be equal.
    /// @param _usersAlloc : Checking Length.
    /// @notice it is a precheck for new vesting with cliff.
    function preAddCliffVesting(
        uint256 _vestingEndTime,
        uint256 _cliffVestingEndTime,
        uint256 _cliffPeriodEndTime,
        uint256 _cliffPercentage10000,
        address[] memory _usersAddresses,
        uint256[] memory _usersAlloc
    ) external view {
        require(
            _cliffVestingEndTime < _vestingEndTime,
            "IIronVest : Cliff Vesting End Time Must Be Lesser Than Vesting Time"
        );
        require(
            _cliffVestingEndTime > _cliffPeriodEndTime,
            "IIronVest : Cliff Vesting Time Must Be Greater Than Cliff Period"
        );
        require(
            _cliffPeriodEndTime > block.timestamp,
            "IIronVest : Cliff Vesting Time Must Be Lesser Than Vesting Time"
        );

        require(
            _cliffPercentage10000 <= 5000,
            "Percentage : Percentage Should Be less Than 50%"
        );
        require(
            _usersAddresses.length == _usersAlloc.length,
            "IIronVest Array : Length of _usersAddresses And _userAlloc Must Be Equal"
        );
    }

    /// @dev Only callable by owner.
    /// @param _poolId : Pool Id should be less than _vestingPoolSize.
    /// @param _deprecatedAddress : Deprecated Address and Updated Address Shouldn't be The Same.
    /// @param _updatedAddress : Shouldn't be the zero address.
    /// @notice This function used as precheck whenever a person lose their address which has pool allocation.
    function preUpdateBeneficiaryAddress(
        uint256 _poolId,
        address _deprecatedAddress,
        address _updatedAddress,
        uint256 _vestingPoolSize
    ) external pure {
        require(_vestingPoolSize > _poolId, "Pool Id : Invalid _poolId");
        require(
            _updatedAddress != _deprecatedAddress,
            "PreCheck : Deprecated Address and Updated Address Shouldn't be The Same"
        );
        require(
            _updatedAddress != address(0x00) &&
                _deprecatedAddress != address(0x00),
            "PreCheck: Invalid Address"
        );
    }

    /// @dev For splititng signature.
    /// @param _sig : signature provided signed by signer
    /// @return r : First 32 bytes stores the length of the signature.
    /// @return s : add(sig, 32) = pointer of sig + 32
    /// effectively, skips first 32 bytes of signature.
    /// @return v : mload(p) loads next 32 bytes starting
    /// at the memory address p into memory.
    function splitSignature(bytes memory _sig)
        external
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            /// First 32 bytes stores the length of the signature

            /// add(_sig, 32) = pointer of _sig + 32
            /// effectively, skips first 32 bytes of signature

            /// mload(p) loads next 32 bytes starting at the memory address p into memory

            /// first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            /// second 32 bytes
            s := mload(add(_sig, 64))
            /// final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        /// implicitly return (r, s, v)
    }

    /// @dev Verify and recover signer from salt and signature.
    /// @param _salt : A hash value which contains concatenated hash of different values.
    /// @param _v : mload(p) loads next 32 bytes starting at the memory address p into memory.
    /// @param _r : First 32 bytes stores the length of the signature.
    /// @param _s : add(sig, 32) = pointer of sig + 32 effectively, skips first 32 bytes of signature.
    /// @return signerAddress : Return the address of signer.
    function verifyMessage(
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external pure returns (address signerAddress) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _salt)
        );
        address _signerAddress = ecrecover(prefixedHashMessage, _v, _r, _s);
        return _signerAddress;
    }

    /// @dev create a message hash by concatincating the values.
    /// @param _poolName : Pool name.
    /// @param _tokenAddress : Vesting token address .
    /// @param _keyHash : key hash value generated by our backend to stop replay attack.
    /// also a chain Id so that a user can't replay the hash any other chain.
    /// @return returning keccak hash of concate values.
    function messageHash(
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) external view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(_poolName, _tokenAddress, _keyHash, block.chainid)
        );
        return hash;
    }
}