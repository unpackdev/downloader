pragma solidity >=0.7.0 <0.9.0;

interface PaymentMaster {
    function deployNewHandler() external;
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract MultiDeploy {
    function deploy(PaymentMaster master, uint256 count) public {
        for (uint i = 0 ; i < count; i++) {
            master.deployNewHandler();
        }
    }
}