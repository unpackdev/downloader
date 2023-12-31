pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Cast {

    function spell(address _target, bytes memory _data) public payable{
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    let size := returndatasize()
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
        }
    }
    
    function cast(
        address[] memory _targets,
        bytes[] memory _datas,
        address _origin
    )
    public
    payable
    {
        for (uint i = 0; i < _targets.length; i++) {
            address _target = _targets[i];
            bytes memory _data = _datas[i];
            require(_target != address(0), "target-invalid");
            assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    let size := returndatasize()
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
            }
        }
       
    }
    receive() external payable {}

}