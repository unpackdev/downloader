// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IFactoryERC721.sol";

abstract contract WAYCFactory is FactoryERC721, Ownable {
    string private _name;
    string private _symbol;
    uint256 internal _numOptions;
    uint256 public maxSupply;
    address public proxyRegistryAddress;
    mapping(address => bool) public isMinter;

    modifier onlyMinter(){
        require(isMinter[_msgSender()], "Caller does not have permission to mint");
        _;
    }

    constructor(string memory _factoryName, string memory _factorySymbol, address _proxyRegistryAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        isMinter[_msgSender()] = true;
        _name = _factoryName;
        _symbol = _factorySymbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function numOptions() external view override returns (uint256) {
        return _numOptions;
    }

    function supportsFactoryInterface() external pure override returns (bool) {
        return true;
    }

    function updateMinter(address _address, bool _isMinter) external onlyOwner {
        isMinter[_address] = _isMinter;
    }

    function totalSupply() public view returns(uint256){
        return maxSupply;
    }

    function balanceOf(address owner) external view returns (uint256 balance){
        return _msgSender() == owner ? maxSupply : 0;
    }


}
