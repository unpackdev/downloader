// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./ERC721STRMMinimal.sol";
import "./BeaconProxy.sol";
import "./Ownable.sol";

/**
 * @dev This contract is for creating proxy to access ERC721STRM token.
 *
 * The beacon should be initialized before call ERC721STRMFactoryC2 constructor.
 *
 */
contract ERC721STRMFactoryC2 is Ownable {
    address public beacon;
    address transferProxy;
    address lazyTransferProxy;

    event Create721STRMProxy(address proxy);
    event Create721STRMUserProxy(address proxy);

    constructor(address _beacon, address _transferProxy, address _lazyTransferProxy) {
        beacon = _beacon;
        transferProxy = _transferProxy;
        lazyTransferProxy = _lazyTransferProxy;
    }

    function createToken(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, uint salt) external {
        address beaconProxy = deployProxy(getData(_name, _symbol, baseURI, contractURI), salt);
        ERC721STRMMinimal token = ERC721STRMMinimal(address(beaconProxy));
        token.transferOwnership(_msgSender());
        emit Create721STRMProxy(beaconProxy);
    }

    function createToken(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory operators, uint salt) external {
        address beaconProxy = deployProxy(getData(_name, _symbol, baseURI, contractURI, operators), salt);
        ERC721STRMMinimal token = ERC721STRMMinimal(address(beaconProxy));
        token.transferOwnership(_msgSender());
        emit Create721STRMUserProxy(beaconProxy);
    }

    //deploying BeaconProxy contract with create2
    function deployProxy(bytes memory data, uint salt) internal returns(address proxy){
        bytes memory bytecode = getCreationBytecode(data);
        assembly {
            proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, 0)
            }
        }
    }

    //adding constructor arguments to BeaconProxy bytecode
    function getCreationBytecode(bytes memory _data) internal view returns (bytes memory) {
        return abi.encodePacked(type(BeaconProxy).creationCode, abi.encode(beacon, _data));
    }

    //returns address that contract with such arguments will be deployed on
    function getAddress(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, uint _salt)
        public
        view
        returns (address)
    {   
        bytes memory bytecode = getCreationBytecode(getData(_name, _symbol, baseURI, contractURI));

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }

    function getData(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI) view internal returns(bytes memory){
        return abi.encodeWithSelector(ERC721STRMMinimal(0).__ERC721STRM_init.selector, _name, _symbol, baseURI, contractURI, transferProxy, lazyTransferProxy);
    }

    //returns address that private contract with such arguments will be deployed on
    function getAddress(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory operators, uint _salt)
        public
        view
        returns (address)
    {   
        bytes memory bytecode = getCreationBytecode(getData(_name, _symbol, baseURI, contractURI, operators));

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }

    function getData(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory operators) view internal returns(bytes memory){
        return abi.encodeWithSelector(ERC721STRMMinimal(0).__ERC721STRMUser_init.selector, _name, _symbol, baseURI, contractURI, operators, transferProxy, lazyTransferProxy);
    }
}