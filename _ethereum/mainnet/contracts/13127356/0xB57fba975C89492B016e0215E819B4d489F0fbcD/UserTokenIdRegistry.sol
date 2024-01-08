//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";

interface IERC721 {
    function ownerOf(uint256) external view returns (address);
    function balanceOf(address) external view returns (uint256);
}

contract UserTokenIdRegistry is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    // using EnumerableSet.AddressSet for contractController;
    // onlyOwner can change contractControllers and transfer it's ownership
    // any contractController can setData
    EnumerableSet.AddressSet contractController;


    IERC721             public ECTokenContract;
    mapping(address => uint16) data;

    event contractControllerEvent(address _address, bool mode);
    event updateDataEvent(address _address, uint16 _tokenId);

    constructor(address _ECTokenContract) {
        ECTokenContract = IERC721(_ECTokenContract);
    }

    /**
     * @notice mgs.sender sets this tokenID as their "main"
     */
    function update(uint16 _id) public {
        require(ECTokenContract.ownerOf(_id) == msg.sender, "Not owner of selected token id.");
        data[msg.sender] = _id;
        updateDataEvent(msg.sender, _id);
    }

    /**
     * @notice returns the addresses token or revert
     */
    function get(address _address) public view returns ( uint16 ) {
        return data[_address];
    }

    /**
     * @notice returns true if the address holds an EC token
     */
    function hasAnECToken(address _address) public view returns ( bool ) {
        if(ECTokenContract.balanceOf(_address) > 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice returns the addresses token or revert
     */
    function getTokenOrRevert(address _address) public view returns ( uint16 ) {
        uint16 _id = data[_address];
        require(ECTokenContract.ownerOf(_id) == _address, "Not owner of registered token id.");
        return _id;
    }

    /*
    *   Admin Stuff
    */

    /**
     * @notice Batch update
     */
    function updateBatch(address[] calldata _addr, uint16[] calldata _ids) public onlyAllowed {
        for(uint16 i = 0; i < _ids.length; i++) {
            data[_addr[i]] = _ids[i];
            updateDataEvent(_addr[i], _ids[i]);
        }
    }

    /**
     * @notice Update method in case a second contract needs this
     */
    function updateByController(address _addr, uint16 _id) public onlyAllowed {
        require(ECTokenContract.ownerOf(_id) == _addr, "Not owner of selected token id.");
        data[_addr] = _id;
        updateDataEvent(_addr, _id);
    }

    function setContractController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            contractController.add(_controller);
        } else {
            contractController.remove(_controller);
        }
        emit contractControllerEvent(_controller, _mode);
    }

    function getContractControllerLength() public view returns (uint256) {
        return contractController.length();
    }

    function getContractControllerAt(uint256 _index) public view returns (address) {
        return contractController.at(_index);
    }

    function getContractControllerContains(address _addr) public view returns (bool) {
        return contractController.contains(_addr);
    }


    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "Not Authorised"
        );
        _;
    }

}