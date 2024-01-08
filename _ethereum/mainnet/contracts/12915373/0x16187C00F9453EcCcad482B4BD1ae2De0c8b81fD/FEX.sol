// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IFEX.sol";
import "./DelegateERC20.sol";



contract FEXToken is DelegateERC20,IFEX, Ownable {
    uint256 private constant preMineSupply = 100000000 * 1e18; 
    uint256 private constant maxSupply =    500000000 * 1e18;     // the total supply

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

    constructor() public ERC20("FEXToken", "FEX"){
        _mint(msg.sender, preMineSupply);
    }

    // mint with max supply
    function mint(address _to, uint256 _amount) external onlyMinter override  returns (bool) {
        require (_amount.add(totalSupply()) <= maxSupply) ;
        _mint(_to, _amount);
        return true;
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "FEXToken: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "FEXToken: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "FEXToken: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }

}
