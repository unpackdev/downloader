// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract SolidlyDeployerInterface {
    address public owner1Address;
    address public owner2Address;
    address[] public deployedAddresses;

    function setOwner1Address(address _owner1Address) external {}

    function setOwner2Address(address _owner2Address) external {}

    function deployedAddressesLength() external view returns (uint256) {}

    function deployedAddressesList() external view returns (address[] memory) {}

    function deploy(bytes memory code, uint256 salt) public {}

    function deployMany(bytes memory code, uint256[] memory salts) public {}

    function updateImplementationAddress(
        address _targetAddress,
        address _implementationAddress
    ) external {}

    function updateGovernanceAddress(
        address _targetAddress,
        address _governanceAddress
    ) public {}

    function updateGovernanceAddressAll(
        address _governanceAddress
    ) external {}

    function generateContractAddress(
        bytes memory bytecode,
        uint256 salt
    ) public view returns (address) {}

    enum Operation {
        Call,
        DelegateCall
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success) {}

    /**
     * @notice Don't do anything with direct NFT transfers
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {}

}
