pragma solidity ^0.8.21;
// SPDX-License-Identifier: GPL-3.0

contract RoleRegistry{
    address owner;
    address controller;
    address rewardDistributor;
    address router;
    address operator;
    address VRFv2DirectFundingConsumer;
    address reserveAddress;
    bool initialized;
    function initialize(address ownerAddr, address controllerAddr, address distributorAddr, address routerAddr, address operatorAddr, address VRFv2DirectFundingConsumerAddress, address reserveAddr) external{
        require(initialized == false, "Contract is initialized already");
        _transferOwnerShip(ownerAddr);
        _transferControllerRole(controllerAddr);
        _transferRewardDistributorRole(distributorAddr);
        _transferRouter(routerAddr);
        _transferOperatorRole(operatorAddr);
        _transferReserveAddr(reserveAddr);
        _transferVRF(VRFv2DirectFundingConsumerAddress);
        initialized = true;
    }

    
    

    modifier onlyOwner(){
        require(msg.sender == owner, "Invalid caller");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner{
        _transferOwnerShip(newOwner);
    }
    function _transferOwnerShip(address newOwner) internal{
        owner = newOwner;
    }

    function transferReserveAddr(address reserveAddr) external onlyOwner{
        _transferReserveAddr(reserveAddr);
    }
    function _transferReserveAddr(address reserveAddr) internal{
        reserveAddress = reserveAddr;
    }

    function setController(address newController) external onlyOwner{
        _transferControllerRole(newController);
    }

    function setrewardDistributor(address newDistributor) external onlyOwner{
        _transferRewardDistributorRole(newDistributor);
    }
    function _transferRewardDistributorRole(address newDistributor) internal{
        rewardDistributor = newDistributor;
    }

    function _transferControllerRole(address newController) internal{
        controller = newController;
    }

    function setRouter(address newRouter) external onlyOwner{
        _transferRouter(newRouter);
    }

    function _transferRouter(address newRouter) internal{
        router = newRouter;
    }

    function setVRF(address newVRF) external onlyOwner{
        _transferVRF(newVRF);
    }

    function _transferVRF(address newVRF) internal{
        VRFv2DirectFundingConsumer = newVRF;
    }

    function _transferOperatorRole(address operatorAddr) internal{
        operator = operatorAddr;
    }

    function setOperatorRole(address operatorAddr) external onlyOwner{
        _transferOperatorRole(operatorAddr);
    }

    function getRouter() public view returns(address){
        address result = router;
        return result;
    }
    function getOwner() public view returns(address){
        address result = owner;
        return result;
    }
    function getController() public view returns(address){
        address result = controller;
        return result;
    }
    function getRewardDistributor() public view returns(address){
        address result = rewardDistributor;
        return result;
    }
    function getOperator() public view returns(address){
        address result = operator;
        return result;
    }

    function getVRF() public view returns(address){
        address result = VRFv2DirectFundingConsumer;
        return result;
    }

    function getReserveAddress() public view returns(address){
        address result = reserveAddress;
        return result;
    }


}